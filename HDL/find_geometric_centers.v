module find_geometric_centers(
	input clk,
	input video_frame_valid,
	input video_data_valid,
	input mazeParametersDefined,
	input video_data_in_bin, 
	input [25:0] curPose,
	input [9:0] cnt_h,
	input [9:0] cnt_v,
	
	output[9:0] bottom_center,
	output[9:0] left_center,
	output[9:0] upper_center,
	output[9:0] right_center,
	output[3:0] states
	);

parameter centerV		= 8;					
parameter centerH		= 15;

reg[4:0] sum_bottom 	= 5'd1;
reg[4:0] sum_left 	= 5'd1;
reg[4:0] sum_up 		= 5'd1;
reg[4:0] sum_right 	= 5'd1;

reg[9:0] sum_bottom_ind = 10'd15;
reg[9:0] sum_left_ind  	= 10'd8;
reg[9:0] sum_up_ind  	= 10'd15;
reg[9:0] sum_right_ind 	= 10'd8;


always @(posedge clk)

if (!video_frame_valid)
	begin
		sum_bottom <= 5'd1;
		sum_left <= 5'd1;
		sum_up <= 5'd1;
		sum_right <= 5'd1;
		sum_bottom_ind <= 10'd15;
		sum_left_ind  	<= 10'd8;
		sum_up_ind  	<= 10'd15;
		sum_right_ind 	<= 10'd8;
	end


else if (video_data_valid & mazeParametersDefined)
	if (video_data_in_bin)
	begin
	// bottom_center
	if ((cnt_v == curPose[9:0] + centerV) & 
		 (cnt_h > (curPose[19:10]-centerH)) & (cnt_h < (curPose[19:10] + centerH)))
		begin
			sum_bottom <= sum_bottom + 1'b1;
			sum_bottom_ind <= sum_bottom_ind + cnt_h - (curPose[19:10]-centerH);
		end
	// upper_center
	if ((cnt_v == (curPose[9:0] - centerV)) & 
				(cnt_h > (curPose[19:10]-centerH)) & (cnt_h < (curPose[19:10] + centerH)))
		begin
			sum_up <= sum_up + 1'b1;
			sum_up_ind <= sum_up_ind + cnt_h - (curPose[19:10]-centerH);
		end
	// left_center
	if ((cnt_h == curPose[19:10] - centerH) & 
				(cnt_v > (curPose[9:0]-centerV)) & (cnt_v < (curPose[9:0]+centerV))) 	
		
		begin	
			sum_left <= sum_left + 1'b1;
			sum_left_ind <= sum_left_ind + cnt_v - (curPose[9:0]-centerV);
		end
	// right_center
	if ((cnt_h == (curPose[19:10] + centerH)) & 
				(cnt_v > (curPose[9:0]-centerV)) & (cnt_v<(curPose[9:0]+centerV))) 
		begin
			sum_right <= sum_right + 1'b1;
			sum_right_ind <= sum_right_ind + cnt_v - (curPose[9:0]-centerV);
		end
	end
	
divider_16 divider_16_inst_b(
.denom(sum_bottom),
.numer(sum_bottom_ind),
.quotient(bottom_center)
);
	
divider_16 divider_16_inst_l(
.denom(sum_left),
.numer(sum_left_ind),
.quotient(left_center)
);

divider_16 divider_16_inst_u(
.denom(sum_up),
.numer(sum_up_ind),
.quotient(upper_center)
);

divider_16 divider_16_inst_r(
.denom(sum_right),
.numer(sum_right_ind),
.quotient(right_center)
);

//assign states = {(sum_bottom>3'd5) & (sum_bottom<sum_bottom_ind+3'd5), (sum_left>3'd3) & (sum_left<3'd3 + sum_left_ind),(sum_up>3'd5) & (sum_up<sum_up_ind+3'd5),(sum_right>3'd3) & (sum_right<3'd3 + sum_right_ind)};

assign states = {(sum_bottom>3'd5), (sum_left>3'd3),(sum_up>3'd5),(sum_right>3'd3)};

endmodule