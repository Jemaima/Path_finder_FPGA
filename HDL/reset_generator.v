`timescale 1ns / 1ps
module reset_generator
	#(parameter W = 16)
	(
	input clk,
	input pll_locked,
	output hw_reset
	);
	
	wire timer_cnt_rst;
	wire timer_cnt_en;

	reg [W-1:0] timer_cnt = {1'b1, {(W-1){1'b0}}};
	reg hw_reset_ff = 1'b1;

// for clk = 27 MHz reset time = 2^15*37 ns = 1 ms 	
	
assign timer_cnt_rst = pll_locked;
assign timer_cnt_en = timer_cnt[W-1];
	
always @(posedge clk)
	if (!timer_cnt_rst)
		timer_cnt <= {1'b1, {(W-1){1'b0}}};
	else if (timer_cnt_en)
		timer_cnt <= timer_cnt + 1'b1;

always @(posedge clk)
	hw_reset_ff <= timer_cnt[W-1];
	
assign hw_reset = hw_reset_ff;

endmodule 	