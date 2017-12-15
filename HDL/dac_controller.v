`timescale 1ns / 1ps
module dac_controller(
	input clk_108_mhz,
	input [7:0] video_data,
	output [7:0] dac_data
	);

	reg [7:0] dac_data_rg = 8'b0;
	
always @(posedge clk_108_mhz)
	dac_data_rg <= video_data;

assign dac_data = dac_data_rg;
	
endmodule 