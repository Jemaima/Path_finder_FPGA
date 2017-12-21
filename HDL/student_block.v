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

parameter centerV		= 8;					/// центр кадра
parameter centerH		= 15;
parameter windowSize = 31;					
parameter fifoSize 	= 16;	
//=======================================================
// initial scan windows generation
//=======================================================

reg [7:0] outdataReg = 8'd0; 
reg [fifoSize:0] window [windowSize-1:0];
reg [25:0] curPose = 25'd0;
reg [25:0] startPose = 25'd0;

generate
	genvar i;
	for (i = 0; i < windowSize ; i = i + 1)
	begin : gen1
		initial
			begin
			window[i] = {(fifoSize+1){1'b0}}; // initial each column = 0
			end
		always @(posedge clk)
		if (!video_frame_valid)
		begin
		window[i] = {(fifoSize+1){1'b0}}; // reset each column = 0
		end
	end
endgenerate 

//=======================================================
// data valid
//=======================================================

reg video_line_valid_z 	= 1'b0;
reg video_frame_valid_z = 1'b0;
wire lineStart;
wire frameStart;
always @(posedge clk) 
	begin
		video_line_valid_z 	<= video_line_valid;
		video_frame_valid_z 	<= video_frame_valid;
	end
assign lineStart 	= video_line_valid_z 	& ~video_line_valid; // check if new line
assign frameStart = video_frame_valid_z 	& ~video_frame_valid; // check if new frame

//=======================================================
// pix coordinate counter
//=======================================================

reg [9:0] cnt_h = 10'd0;
reg [9:0] cnt_v = 10'd0;
reg [9:0] cnt_frame = 10'd0;

always @(posedge clk)
begin
	if (frameStart) 
	begin
		cnt_frame <= cnt_frame + 10'd1;
		cnt_v <= 10'd0;
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

//=======================================================
//First frame processing
//=======================================================
reg [4:0] path_width_bottom = 5'd0;
reg [9:0] stLeft 	= 10'd0;
reg [9:0] stRight = 10'd0;

always @(posedge clk)
if (!mazeParametersDefined && video_data_valid)
begin
	if (cnt_v == 10'd50) // define initial parameters al lvl 16
	begin
		path_width 	<= path_width + video_data_in_bin;
		stLeft 		<=posEdgeMaze ? cnt_h:stLeft;
		stRight 		<=negEdgeMaze ? cnt_h:stRight;
	end
	
	else if (cnt_v == 10'd100) // write startPose
	begin
		startPose[9:0]	<=10'd50;
		startPose[19:10]	<=stLeft[9:1]+stRight[9:1] + 10'd1;
		startPose[23:20]	<=4'b1000; 
	end	
	else if (cnt_v == 10'd280) // define initial parameters al lvl 16
	begin
		path_width_bottom 	<= path_width_bottom + video_data_in_bin;
		stLeft 		<=posEdgeMaze ? cnt_h:stLeft;
		stRight 		<=negEdgeMaze ? cnt_h:stRight;
		curPose[9:0]	<=10'd50;
		curPose[19:10]	<=stLeft[9:1]+stRight[9:1] + 10'd1;
	end	
	else if (cnt_v == 10'd287 && cnt_h==10'd701 && (curPose[19:10]-startPose[19:10])<10'd10) /// если конец строки и последняя строка
	begin
		curPose <= startPose;
//		curPose[19:10]	<=stLeft[9:1]+stRight[9:1] + 10'd1;
//		curPose[23:20]	<=4'b1000; 
		mazeParametersDefined <= 1'b1;  // maze defenition complete
	end
	outdataReg <={1'b0,{7{video_data_in_bin}}};
end

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

reg [5:0] j = 6'd0; 	
always @(posedge clk)
	if(video_data_valid)
	begin
	for (j=windowSize-1;j>0;j=j-1)
		window[j] <= window[j-1];	
	window[0] <= {fifo_dout,video_data_in_bin};
	end

//=======================================================
// Node states
//=======================================================	

wire onLastPose;	
wire isStreight;
wire emptyConers;
wire [4:0] next_possible_dirs;


assign onLastPose = (cnt_h-centerH == curPose[19:10]) & (cnt_v-centerV == curPose[9:0]);
assign emptyConers =(!window[0][0] & !window[windowSize-1][0] & !window[0][fifoSize-1] && !window[windowSize-1][fifoSize-1]);
assign isStreight = (window[0][centerV] & window[windowSize-1][centerV] & !window[centerH][0] & !window[centerH][fifoSize-1])
					   ||(!window[0][centerV] & !window[windowSize-1][centerV] & window[centerH][0] & window[centerH][fifoSize-1]);
	
assign next_possible_dirs = {window[centerH][0],window[windowSize-1][centerV],window[centerH][fifoSize-1],window[0][centerV]}&(~{curPose[21:20],curPose[23:22]})&{4{window[centerH][centerV]}};

// reset is shift happend
always @(posedge clk)
if (onLastPose && window[centerH][centerV]==1'b0)
mazeParametersDefined <= 1'b0;


//=======================================================
// Define next position
//=======================================================

wire [4:0] botton_c;
wire [4:0] left_c;
wire [4:0] upper_c;
wire [4:0] right_c;
wire [3:0] wind_wire;

assign wind_wire = {window[centerH][0],window[windowSize-1][centerV],window[centerH][fifoSize-1],window[0][centerV]};

find_geometric_centers find_geometric_centers_inst1(
.clk(clk),
.window(wind_wire),
.botton_center(botton_c),
.left_center(left_c),
.upper_center(upper_c),
.right_center(right_c)
);


reg [4:0] botton_c_z = 5'd0;
reg [4:0] left_c_z 	= 5'd0;
reg [4:0] upper_c_z 	= 5'd0;
reg [4:0] right_c_z 	= 5'd0;

always @(posedge clk)
begin
	if (onLastPose)
	begin
	botton_c_z	= botton_c;
	left_c_z		= left_c;
	upper_c_z	= upper_c;
	right_c_z	= right_c;
	if (!emptyConers && !isStreight)
		curPose[23:20] <= next_possible_dirs;
	end
	
	if(frameStart)
	case (curPose[23:20])
	4'b1000:curPose[9:0] 	= curPose[9:0] 	+ botton_c_z;     // down
	4'b0100:curPose[19:10] 	= curPose[19:10] + left_c_z;			// left
	4'b0010:curPose[9:0] 	= curPose[9:0]	- upper_c_z;		// up
	4'b0001:curPose[19:10] 	= curPose[19:10]	- right_c_z;		// right
	endcase
end

//=======================================================
// Draw agent
//=======================================================
integer k,l;

always @(posedge clk)
if (mazeParametersDefined)
	begin
	if (onLastPose)
		outdataReg<=window[centerH][centerV];
	if (cnt_h==next_possible_dirs)
		outdataReg<=8'd250;
	else if (cnt_h==curPose[19:10]-startPose[19:10])
		outdataReg<=8'd200;
//	else if (cnt_h==left_c_z+2)
//		outdataReg<=8'd155;
	else if (cnt_v > curPose[9:0]- 10'd5 && cnt_v < curPose[9:0] + 10'd5 && cnt_h > curPose[19:10]- 10'd5 && cnt_h < curPose[19:10] + 10'd5)
		begin
			outdataReg<=8'd200;
		end
	else 
		outdataReg<={video_data_in_bin,5'd10};
	end
	
	
assign video_data_ready = video_data_valid;
assign video_data_out = outdataReg; 
	
endmodule 