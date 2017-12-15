`timescale 1ns / 1ps
module parameter_ctrl(
	input clk,
	output [1:0] mode
	);
	
	wire [24:0] source;
	wire enable; 
	wire [7:0] address;
	wire [15:0] data;
	wire mode_wren;
	
	reg enable_z = 1'b0;
	reg [1:0] mode_rg = 2'b0;

source source_inst (
	.probe (1'b0),
	.source_clk (clk),
	.source (source));

assign enable = source[24];
assign address = source[23:16];
assign data = source[15:0];
	
always @(posedge clk)
	enable_z <= enable;

assign mode_wren = enable & ~enable_z & (address == 8'b0);
		
always @(posedge clk)
	if (mode_wren)
		mode_rg <= data[1:0];

assign mode = mode_rg;
		
endmodule 