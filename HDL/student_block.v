`timescale 1ns / 1ps
module student_block(
	input clk,
	input reset, 
	input [1:0] mode, // 
	input video_frame_valid,  		// is frame ограничивает единицей считываем кадр
	input video_line_valid,  		// is line ща пойдет линия
	input video_data_valid,  		// is pxl ща пойдет кадр
	input [7:0] video_data_in,   	// img before binarization пишем сюда пиксели
	input [19:0] video_address,	// не нужно
	output video_data_ready,		// данные обработались??
	output[7:0] video_data_out
	);


//=======================================================
// MAIN PARAMETERS
//=======================================================

reg mazeParametersDefined = 1'b0;		/// вход в лабиринт 

reg [4:0] path_width = 5'd0;				/// ширина пути
reg [4:0] path_width_bottom = 5'd0;

reg [25:0] curPose = 25'd0;
reg [19:0] startPose = 10'd0;
reg [19:0] endPose = 10'd0;

parameter centerV		= 10'd8;					/// центр кадра
parameter centerH		= 10'd15;
parameter windowSize = 10'd31;					
parameter fifoSize 	= 10'd16;

parameter lastPixH = 10'd701;			
parameter firstPixH = 10'd0;	
parameter lastPixV = 10'd287;			
parameter firstPixV = 10'd0;	

parameter stepH = 10'd8;
parameter stepV = 10'd4;

//=======================================================
// initial scan windows generation
//=======================================================

reg [7:0] outdataReg = 8'd0; 
reg [fifoSize:0] window [windowSize-1:0];

generate
	genvar i;
	for (i = 0; i < windowSize ; i = i + 1)
	begin : gen1
		initial
			window[i] = {(fifoSize+1){1'b0}}; // initial each column = 0
	end
endgenerate 

//=======================================================
// data valid
//=======================================================

reg video_line_valid_z 	= 1'b0;
reg video_frame_valid_z = 1'b0;
wire lineStart;
wire frameStart;
wire frameEnd;
always @(posedge clk) 
	begin
		video_line_valid_z 	<= video_line_valid;
		video_frame_valid_z 	<= video_frame_valid;
	end
assign lineStart 	= ~video_line_valid_z 	& video_line_valid; // check if new line
assign frameStart = ~video_frame_valid_z 	& video_frame_valid; // check if new frame
assign frameEnd 	= video_frame_valid_z 	& ~video_frame_valid; 


//=======================================================
// pix coordinate counter
//=======================================================

reg [9:0] cnt_h = 10'd0;
reg [9:0] cnt_v = 10'd1023;
reg [9:0] cnt_frame = 10'd1023;


always @(posedge clk)
begin
if (!video_frame_valid)
	begin
	if (frameStart)
		begin
		cnt_v <= 10'd1023;
		cnt_h <= 10'd0;
		end
	end
	
else
	begin
	if (frameStart) 
		begin
		cnt_frame <= cnt_frame + 10'd1;
		cnt_v <= 10'd1023;
		cnt_h <= 10'd0;
//		if (!mazeParametersDefined)
//			cnt_frame<=10'd1023;
		end
	if (lineStart)
		begin
		cnt_v <= cnt_v + 10'd1;
		cnt_h <= 10'd0;
		end
	if (video_data_valid)
		begin
		cnt_h <= cnt_h + 10'd1;
		end
	end
end

//=======================================================
//binarization
//=======================================================

wire video_data_in_bin;
assign video_data_in_bin = (video_data_in>8'd150)?1'b1:1'b0;

//=======================================================
// detection edges to find first node
//=======================================================

reg edgeMaze_z = 1'b0;
wire posEdgeMaze;
wire negEdgeMaze;

always @(posedge clk) 
	begin
		edgeMaze_z <= video_data_in_bin;
	end
	
assign negEdgeMaze = edgeMaze_z & ~video_data_in_bin;	
assign posEdgeMaze = ~edgeMaze_z & video_data_in_bin;	

// check if on Last pose (window[centerH][centerV] == curPse)
wire onLastPose;
assign onLastPose = (cnt_h-centerH == curPose[19:10]) & (cnt_v-centerV == curPose[9:0]) & mazeParametersDefined;

//=======================================================
//FIFO organization
//=======================================================

reg [1:0] fifo_enable = 2'b01;

wire fifo_sclr;
wire fifo_wrreg,fifo_rdreg;
wire [fifoSize-1:0] fifo_din,fifo_dout;

assign fifo_sclr 	= ~video_frame_valid;
assign fifo_wrreq = video_data_valid & fifo_enable[0];
assign fifo_rdreq = video_data_valid & fifo_enable[1];
assign fifo_din 	= window[0][fifoSize-1:0];
	
fifo_1kx16 fifo_1kx16_inst1(
	.clock(clk),
	.data(fifo_din),
	.rdreq(fifo_rdreq),
	.sclr(fifo_sclr),
	.wrreq(fifo_wrreq),
	.q(fifo_dout)
	);

// fill first line
always @(posedge clk)
	if (!video_frame_valid)
		fifo_enable<=2'b01;
	else if (cnt_h==701)   // read access
		fifo_enable <=2'b11;

reg [5:0] j,jj; 	
always @(posedge clk)
	if (!video_frame_valid)
	for (jj = 0; jj < windowSize ; jj = jj + 1)
		window[jj] = {(fifoSize+1){1'b0}}; // reset each column = 0

	else if(video_data_valid)
	begin
	for (j=windowSize-1;j>0;j=j-1)
		window[j] = window[j-1];	
	window[0] = {fifo_dout,video_data_in_bin};
	end

//=======================================================
// Node states
//=======================================================	

wire isStreight;
wire emptyConers;
wire [3:0] next_possible_dirs;

assign emptyConers =(!window[0][0] & !window[windowSize-1][0] & !window[0][fifoSize-1] & !window[windowSize-1][fifoSize-1]) & mazeParametersDefined;

assign isStreight = (window[0][centerV] & window[windowSize-1][centerV] & !window[centerH][0] & !window[centerH][fifoSize-1])
					   ||(!window[0][centerV] & !window[windowSize-1][centerV] & window[centerH][0] & window[centerH][fifoSize-1]) & mazeParametersDefined;
	
assign next_possible_dirs  = {window[centerH][0], window[windowSize-1][centerV], window[centerH][fifoSize-1-3], window[0][centerV]};//  & ~{curPose[21:20],curPose[23:22]}; // & (~{curPose[21:20],curPose[23:22]});

//=======================================================
// Define maze Parameters
//=======================================================

reg [9:0] stLeft 	= 10'd0;
reg [9:0] stRight = 10'd0;

always @(posedge clk)
if (!video_frame_valid)
	begin
	if (!mazeParametersDefined)
		begin
		path_width = 5'd0;
		path_width_bottom = 5'd0;
		if (frameEnd && ((startPose[19:10]-endPose[19:10])<10'd30 || (endPose[19:10]-startPose[19:10])<10'd30)) /// если конец строки и последняя строка
				mazeParametersDefined <= 1'b1;  // maze defenition complete
		end
	stLeft 	= 10'd0;
	stRight = 10'd0;
	end

// video_frame_valid
else if (video_data_valid)
	if (!mazeParametersDefined)
	begin
		 // define start Pose
		if (cnt_v == 10'd18)
		begin
			path_width 	<= path_width + video_data_in_bin;
			stLeft 		<= posEdgeMaze ? cnt_h:stLeft;
			stRight 		<= negEdgeMaze ? cnt_h:stRight;
		end
		
		// set start pose at random line
		else if (cnt_v == 10'd29 && cnt_h==firstPixH) // write startPose
		begin
			startPose[9:0]		<= 10'd55;
			startPose[19:10]	<= stLeft[9:1] + stRight[9:1] + 10'd1;
			stLeft  <= 10'd0;
			stRight <= 10'd0;
		end	
		
		else if (cnt_v == 10'd269) // define initial parameters al lvl 16
		begin
			path_width_bottom 	<= path_width_bottom + video_data_in_bin;
			stLeft 		<= posEdgeMaze ? cnt_h:stLeft;
			stRight 		<= negEdgeMaze ? cnt_h:stRight;
		end	
		
		else if (cnt_v == 10'd270 && cnt_h==firstPixH) 
		begin
			endPose[9:0]	<= 10'd270;
			endPose[19:10]	<= stLeft[9:1] + stRight[9:1] + 10'd1;
		end	
	end
	
	// if parameters defined, but smth changed
	else if (onLastPose && !window[centerH][centerV])
		mazeParametersDefined <= 1'b0;
	
//=======================================================
// Define next position
//=======================================================

wire [9:0] bottom_c;
wire [9:0] left_c;
wire [9:0] upper_c;
wire [9:0] right_c;
wire [3:0] next_possible_dirs_2;
wire [4:0] sum_right;

find_geometric_centers find_geometric_centers_inst(
.clk(clk),
.video_frame_valid(video_frame_valid),
.video_data_valid(video_data_valid),
.mazeParametersDefined(mazeParametersDefined),
.video_data_in_bin(video_data_in_bin), 
.curPose(curPose),
.cnt_h(cnt_h),
.cnt_v(cnt_v),

.bottom_center(bottom_c),
.left_center(left_c),
.upper_center(upper_c),
.right_center(right_c),
.states(next_possible_dirs_2),
.sum_right_w(sum_right)
);

reg [9:0] bottom_c_z = 5'd0;
reg [9:0] left_c_z = 5'd0;
reg [9:0] upper_c_z = 5'd0;
reg [9:0] right_c_z = 5'd0;

//=======================================================
// Current Pose definition
//=======================================================

reg isStreight_z=1'b0;
reg emptyConers_z=1'b0;
reg nextShot =1'b0;

reg [3:0] allExceptBackDir_z = 4'd0;
reg [3:0] possibleDirs_z = 4'd0;
reg nearNodePose = 1'b0;

always @(posedge clk)
// set as Start if maze Parameters not Defined
begin 
	// only one frame per shot
	if (!video_frame_valid)
	begin
		nextShot<=1'b0;
		nearNodePose<=1'b0;
		if (!mazeParametersDefined & frameEnd)
		begin
			curPose[23:20] <= 4'b1000;
			curPose[19:0] 	<= startPose;
			bottom_c_z 	<= 5'd0;
			left_c_z 	<= 5'd0;
			upper_c_z 	<= 5'd0;
			right_c_z 	<= 5'd0;
		end
		
		// processinf after whole frame scanning
		else if (frameEnd)
		begin
			if (!nearNodePose)
				case (curPose[23:20])
					4'b1000:curPose[19:0] 	<= {curPose[19:10] - centerH	+ bottom_c_z, curPose[9:0] + stepV};   // down
					4'b0100:curPose[19:0] 	<= {curPose[19:10] - stepH, curPose[9:0] - centerV + left_c_z};		// left
					4'b0010:curPose[19:0] 	<= {curPose[19:10] - centerH	+ upper_c_z, curPose[9:0] - stepV};		// up
					4'b0001:curPose[19:0] 	<= {curPose[19:10] + stepH, curPose[9:0] - centerV + right_c_z};		// right
				endcase
			else
				case (curPose[23:20])
					4'b1000:curPose[19:0] 	<= {curPose[19:10], curPose[9:0] + stepV + stepV};   	// down
					4'b0100:curPose[19:0] 	<= {curPose[19:10] - stepH- stepH, curPose[9:0]};		// left
					4'b0010:curPose[19:0] 	<= {curPose[19:10], curPose[9:0] - stepV - stepV};		// up
					4'b0001:curPose[19:0] 	<= {curPose[19:10] + stepH+ stepH, curPose[9:0]};		// right
				endcase
			end
		
	end
	else if (video_data_valid & onLastPose & !nextShot )
	begin
		bottom_c_z	<= bottom_c + 1'b1;
		left_c_z		<=  left_c + 1'b1; //centerV; 
		upper_c_z	<=  upper_c + 1'b1; //centerH; 
		right_c_z	<= right_c + 1'b1; //centerV; 
		emptyConers_z <= emptyConers;
		isStreight_z <= !isStreight;
		
		allExceptBackDir_z <= ~{curPose[21:20],curPose[23:22]};
		possibleDirs_z <= next_possible_dirs_2 & next_possible_dirs;
		if (next_possible_dirs_2)
		if (emptyConers && !isStreight)
			//curPose[23:20]  <=curPose[23:20];
			curPose[23:20]  <= next_possible_dirs_2 & ~{curPose[21:20],curPose[23:22]} & next_possible_dirs;
		else if (!emptyConers)
			nearNodePose<=1'b1;
		nextShot <= 1'b1;
	end
end


//=======================================================
// Draw agent
//=======================================================
integer k,l;

always @(posedge clk)
// if parameters not defined
if (!mazeParametersDefined)

// draw frame
	if (cnt_h==1'b0 || cnt_h==lastPixH  )
		outdataReg<=8'd250;
	else if (cnt_v==1'b0 || cnt_v==lastPixV )
		outdataReg<=8'd250;	
// draw Pose and end Pose
	else if (cnt_h==startPose[19:10] || cnt_v==startPose[9:0])
		outdataReg<=8'd150;
	else if (cnt_h==endPose[19:10] || cnt_v==endPose[9:0])
		outdataReg<=8'd220;

// check if frame cnt works
	else if (cnt_v > 10'd5 && cnt_v < 10'd25 && cnt_h > 10'd5 && (cnt_h < 10'd25))
		outdataReg<=cnt_frame;
// draw background
	else
		outdataReg<={video_data_in_bin,7'd0};

else
begin
	if (onLastPose)
		outdataReg<={isStreight,emptyConers,6'b111111};
// check if frame cnt works
	else if (cnt_v > 10'd5 && cnt_v < 10'd25 && cnt_h > 10'd5 && (cnt_h < 10'd25))
		outdataReg<=cnt_frame;
		
	else if (cnt_v > curPose[9:0]- 10'd5 && cnt_v < curPose[9:0] + 10'd5 && cnt_h > curPose[19:10]- 10'd5 && (cnt_h < curPose[19:10] + 10'd5))
		outdataReg<=10'd255;


	else if (cnt_h==curPose[19:10] || cnt_v==curPose[9:0])
		outdataReg<=8'd150;
		
		
	else if (cnt_v > 10'd200- 10'd5 && cnt_v <  10'd200 + 10'd5 && cnt_h >  10'd20- 10'd5 && (cnt_h < 10'd20 + 10'd5))
		outdataReg<={8{emptyConers_z}};
	else if (cnt_v > 10'd200- 10'd5 && cnt_v <  10'd200 + 10'd5 && cnt_h >  10'd30- 10'd5 && (cnt_h < 10'd30 + 10'd5))
		outdataReg<={8{isStreight_z}};
	else if (cnt_v > 10'd200- 10'd5 && cnt_v <  10'd200 + 10'd5 && cnt_h >  10'd40- 10'd5 && (cnt_h < 10'd40 + 10'd5))
		outdataReg<={8{nearNodePose}};

		
// possible current dirs
	else if (cnt_v > 10'd220- 10'd2 && cnt_v <  10'd220 + 10'd2 && cnt_h >  10'd50- 10'd5 && (cnt_h < 10'd50 + 10'd5))
		outdataReg<={8{possibleDirs_z[1]}};
	else if (cnt_v > 10'd230- 10'd2 && cnt_v <  10'd230 + 10'd2 && cnt_h >  10'd50- 10'd5 && (cnt_h < 10'd50 + 10'd5))
		outdataReg<={8{possibleDirs_z[3]}};
	else if (cnt_v > 10'd230- 10'd2 && cnt_v <  10'd230 + 10'd2 && cnt_h >  10'd30- 10'd5 && (cnt_h < 10'd30 + 10'd5))
		outdataReg<={8{possibleDirs_z[2]}};
	else if (cnt_v > 10'd230- 10'd2 && cnt_v <  10'd230 + 10'd2 && cnt_h >  10'd70- 10'd5 && (cnt_h < 10'd70 + 10'd5))
		outdataReg<={8{possibleDirs_z[0]}};		

// alowed current dis (all excrpt back step)
	else if (cnt_v > 10'd250- 10'd2 && cnt_v <  10'd250 + 10'd2 && cnt_h >  10'd50- 10'd5 && (cnt_h < 10'd50 + 10'd5))
		outdataReg<={8{allExceptBackDir_z[1]}};
	else if (cnt_v > 10'd260- 10'd2 && cnt_v <  10'd260 + 10'd2 && cnt_h >  10'd50- 10'd5 && (cnt_h < 10'd50 + 10'd5))
		outdataReg<={8{allExceptBackDir_z[3]}};
	else if (cnt_v > 10'd260 - 10'd2 && cnt_v <  10'd260  + 10'd2 && cnt_h >  10'd30- 10'd5 && (cnt_h < 10'd30 + 10'd5))
		outdataReg<={8{allExceptBackDir_z[2]}};
	else if (cnt_v > 10'd260 - 10'd2 && cnt_v <  10'd260  + 10'd2 && cnt_h >  10'd70- 10'd5 && (cnt_h < 10'd70 + 10'd5))
		outdataReg<={8{allExceptBackDir_z[0]}};	
		
	else 
		//outdataReg<={1'b0,video_data_in_bin,cnt_frame[4:9]};
		outdataReg<={1'b0,video_data_in_bin,6'd0};
end
	
assign video_data_ready = video_data_valid;
assign video_data_out = outdataReg; 
	
endmodule 