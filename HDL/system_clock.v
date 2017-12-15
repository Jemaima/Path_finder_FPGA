`timescale 1ns / 1ps
module system_clock(
	input in_clk,
	output clk_13_mhz,
	output clk_108_mhz,
	output pll_locked
	);

	wire clk_13_mhz_pll, clk_108_mhz_pll;
	
pll_40_mhz	pll_40_mhz_inst (
	.inclk0 (in_clk),
	.c0 (clk_13_mhz_pll),
	.c3 (clk_108_mhz_pll),
	.locked (pll_locked)
	);
	
global_buf	global_buf_clk_108_mhz (
	.inclk (clk_108_mhz_pll),
	.outclk (clk_108_mhz)
	);	

global_buf	global_buf_clk_13_mhz (
	.inclk (clk_13_mhz_pll),
	.outclk (clk_13_mhz)
	);	
	
endmodule 