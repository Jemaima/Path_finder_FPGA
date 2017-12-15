`timescale 1ns / 1ps
module student_top(
	// input clock = 40 MHz
	input IN_CLK,
	// ADC signals
	output ADC_CLK,
	output ADC_CLAMP,
	input [7:0] ADC_DATA,
	// LM1881 signals
	input COMP_SYNC,
	input VERT_SYNC,
	input ODDEVEN,
	input BURST,
	// DAC signals
	output DAC_CLK,
	output DAC_BLANC,	
	output [7:0] DAC_DATA
	);

	wire clk_13_mhz, clk_108_mhz;
	wire sys_clk_pll_locked;
	wire global_reset;
	wire video_frame_valid, video_line_valid, video_data_valid;
	wire [7:0] video_data_to_student, video_data_from_student;
	wire [19:0] video_address;	
	wire [1:0] mode;
	
// module for generation all global clocks	

system_clock sys_clk_inst(
	.in_clk (IN_CLK),
	.clk_13_mhz (clk_13_mhz),
	.clk_108_mhz (clk_108_mhz),
	.pll_locked (sys_clk_pll_locked));

// module to produce init hardware system reset

reset_generator #(8) rst_gen_inst (
	.clk (clk_13_mhz),
	.pll_locked (sys_clk_pll_locked),
	.hw_reset (global_reset));	

// adc controller 
		
adc_controller adc_ctrl_inst(
	.clk_108_mhz (clk_108_mhz),
	.reset (global_reset),
	.comp_sync (COMP_SYNC),
	.vert_sync (VERT_SYNC),
	.oddeven (ODDEVEN),
	.burst (BURST),
	.adc_data (ADC_DATA),
	.video_frame_valid (video_frame_valid),
	.video_line_valid (video_line_valid),
	.video_data_valid (video_data_valid),
	.video_data (video_data_to_student),
	.video_address (video_address),
	.adc_clamp (ADC_CLAMP),
	.adc_clk (ADC_CLK),
	.dac_clk (DAC_CLK),
	.dac_blanc (DAC_BLANC));

// student block

student_block student_block_inst(
	.clk (clk_108_mhz),
	.reset (global_reset),
	.mode (mode),
	.video_frame_valid (video_frame_valid),
	.video_line_valid (video_line_valid),
	.video_data_valid (video_data_valid),
	.video_data_in (video_data_to_student),
	.video_address (video_address),
	.video_data_ready (),
	.video_data_out (video_data_from_student));

// dac controller

dac_controller dac_ctrl_inst(
	.clk_108_mhz (clk_108_mhz),
	.video_data (video_data_from_student),
	.dac_data (DAC_DATA));

// matlab

parameter_ctrl parameter_ctrl_inst(
	.clk (clk_108_mhz),
	.mode (mode));
	
endmodule 