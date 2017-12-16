`timescale 1ns / 1ps
module student_block(
	input clk,
	input reset, 
	input [1:0] mode, // 
	input video_frame_valid,  		// is frame
	input video_line_valid,  		// is line
	input video_data_valid,  		// is pxl
	input [7:0] video_data_in,   	// img before binarization
	input [19:0] video_address,
	output video_data_ready,
	output[7:0] video_data_out
	);


//=======================================================
// MAIN PARAMETERS
//=======================================================

reg mazeParametersDefined = 1'b0;
reg [4:0] path_width = 5'd0;
parameter center=16;
parameter windowSize = 33;	
	
//=======================================================
// initial scan windows generation
//=======================================================

reg [7:0] outdataReg = 8'd0; 
reg [32:0] window [32:0];
reg [25:0] curPose = 25'd0;

generate
	genvar i;
	for (i = 0; i < 32; i = i + 1)
	begin : gen1
		initial
			begin
			window[i] = {33{1'b0}}; // initial each column = 0
			end
		always @(posedge clk)
		if (!video_frame_valid)
		begin
		window[i] = {33{1'b0}}; // reset each column = 0
		end
	end
endgenerate 

//=======================================================
// data valid
//=======================================================

reg video_line_valid_z = 1'b0;
reg video_frame_valid_z = 1'b0;
wire lineStart;
wire frameStart;
always @(posedge clk) 
	begin
		video_line_valid_z <= video_line_valid;
		video_frame_valid_z <= video_frame_valid;
	end
assign lineStart = video_line_valid_z & ~video_line_valid; // check if new line
assign frameStart = video_frame_valid_z & ~video_frame_valid; // check if new frame

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
//FIFO organization
//=======================================================

reg [1:0] fifo_enable = 2'd1;

wire fifo_sclr;
wire fifo_wrreg,fifo_rdreg;
wire [31:0] fifo_din,fifo_dout;

assign fifo_sclr = ~video_frame_valid;
assign fifo_wrreq = video_data_valid &fifo_enable[0];
assign fifo_rdreq = video_data_valid &fifo_enable[1];
assign fifo_din = {video_data_in_bin,window[0][31:1]};
	
fifo_1kx32 fifo_1kx32_inst1(
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
	else if (lineStart)   // read access
		fifo_enable <=2'b11;
	
reg [5:0] j = 6'd0;//	
always @(posedge clk)
	if(video_data_valid && fifo_enable[1])
	begin
	window[0] <= {video_data_in,fifo_dout};
	for (j=1;j<33;j=j+1)
		window[j] <= window[j-1];
	
	end

	
//=======================================================
// Node states
//=======================================================	
	
wire isStreight;
wire leftTurn;
wire rightTurn;

assign emptyConers =(!window[0][0] && !window[32][0] && !window[0][32] && !window[32][32]);
assign isStreight = (window[0][center] && window[32][center] && !window[center][0] && !window[center][32])
					   ||(!window[0][center] && !window[32][center] && window[center][0] && window[center][32]);


//=======================================================
//First frame processing
//=======================================================
reg [9:0] stLeft = 10'd0;
reg [9:0] stRight = 10'd0;

always @(posedge clk)
if (!mazeParametersDefined && video_data_valid)
begin
	if (cnt_v == 10'd16) // define initial parameters al lvl 16
	begin
		path_width <= path_width+video_data_in_bin;
		stLeft <=posEdgeMaze?cnt_h:stLeft;
		stRight <=negEdgeMaze?cnt_h:stRight;
	end	
	else if (cnt_v == 10'd287 && cnt_h==10'd701)
	begin
		curPose[9:0]<=10'd20;
		curPose[19:10]<=stLeft[9:1]+stRight[9:1] + 10'd1;
		curPose[23:20]<=4'b1000; 
		mazeParametersDefined <= 1'b1;  // maze defenition complete
	end
	outdataReg <={1'b0,{7{video_data_in_bin}}};
end
	
//=======================================================
// Define next position
//=======================================================

always @(posedge clk)
	if(frameStart)
	case (curPose[23:20])
	4'b1000:curPose[9:0] = curPose[9:0]+10'd8;
	4'b0100:curPose[9:0] = curPose[19:10]-10'd8;
	4'b0010:curPose[9:0] = curPose[9:0]-10'd8;
	4'b0001:curPose[9:0] = curPose[19:10]+10'd8;
	endcase
	
//=======================================================
// Draw agent
//=======================================================
integer k,l;

always @(posedge clk)
if (mazeParametersDefined)
	begin
	if (cnt_v > curPose[9:0]- 10'd5 && cnt_v < curPose[9:0] + 10'd5 && cnt_h > curPose[19:10]- 10'd5 && cnt_h < curPose[19:10] + 10'd5)
		begin
			outdataReg<=8'd200;
		end
	else
		//outdataReg<={8{window[center][center]}};
		outdataReg <={2'b00,{6{video_data_in_bin}}};
	for (k=0;k<32;k=k+1)
	for (l=0;l<32;l=l+1)
	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
		outdataReg<={1'b1,{7{window[center][center]}}};	
	
	
	
//	for (k=0;k<5;k=k+1)
//	for (l=0;l<5;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[0][0]}}};	
//	
//	for (k=6;k<10;k=k+1)
//	for (l=0;l<5;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[0][center]}}};	
//	
//	for (k=11;k<15;k=k+1)
//	for (l=0;l<5;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[0][31]}}};	
//	
//	for (k=16;k<20;k=k+1)
//	for (l=0;l<5;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[0][32]}}};
////======
//	for (k=0;k<5;k=k+1)
//	for (l=6;l<10;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[center][0]}}};	
//	
//	for (k=6;k<10;k=k+1)
//	for (l=6;l<10;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[center][center]}}};	
//	
//	for (k=11;k<15;k=k+1)
//	for (l=6;l<10;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[center][31]}}};	
//	
//	for (k=16;k<20;k=k+1)
//	for (l=6;l<10;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[center][32]}}};	
////======
//	for (k=0;k<5;k=k+1)
//	for (l=11;l<15;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[31][0]}}};	
//	
//	for (k=6;k<10;k=k+1)
//	for (l=11;l<15;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[31][center]}}};	
//	
//	for (k=11;k<15;k=k+1)
//	for (l=11;l<15;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[31][31]}}};	
//	
//	for (k=16;k<20;k=k+1)
//	for (l=11;l<15;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[31][32]}}};	
//	
////======
//	for (k=0;k<5;k=k+1)
//	for (l=16;l<21;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[32][0]}}};	
//	
//	for (k=6;k<10;k=k+1)
//	for (l=16;l<21;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[32][center]}}};	
//	
//	for (k=11;k<15;k=k+1)
//	for (l=16;l<21;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[32][31]}}};	
//	
//	for (k=16;k<20;k=k+1)
//	for (l=16;l<21;l=l+1)
//	if (cnt_h-k==curPose[19:10] && cnt_v-l==curPose[9:0])
//		outdataReg<={1'b1,{7{window[32][32]}}};	
		
	end
	
	
assign video_data_ready = video_data_valid;
assign video_data_out = outdataReg; 
	
endmodule 