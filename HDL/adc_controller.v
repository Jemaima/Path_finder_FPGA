`timescale 1ns / 1ps
module adc_controller(
	input clk_108_mhz,
	input reset,
	input comp_sync,
	input vert_sync,
	input oddeven,
	input burst,
	input [7:0] adc_data,
	output video_frame_valid,
	output video_line_valid,
	output video_data_valid,
	output [7:0] video_data,
	output [19:0] video_address,
	output adc_clamp,
	output adc_clk,
	output dac_clk,
	output dac_blanc
	);

	localparam left_border = 79;
	localparam right_border = left_border + 701;
	localparam up_border_field0 = 18;
	localparam up_border_field1 = 19;
	localparam down_border_field0 = up_border_field0 + 287;
	localparam down_border_field1 = up_border_field1 + 287;
	
	wire cnt_up_8_rst;
	wire col_cnt_rst, col_cnt_en;
	wire row_cnt_rst, row_cnt_en;
	wire [8:0] up_border, down_border;
	wire up_border_cmpr, down_border_cmpr;
	wire left_border_cmpr, right_border_cmpr;
	wire line_valid, frame_valid;
	
	reg [2:0] comp_sync_mstb = 3'b0;
	reg [1:0] vert_sync_mstb = 2'b0;
	reg [1:0] oddeven_mstb = 2'b0;
	reg local_reset = 1'b1;	
	reg [3:0] cnt_up_8 = 3'b0;
	reg [9:0] col_cnt = 10'b0;
	reg [1:0] pulse = 2'b0;
	reg [8:0] row_cnt = 9'b0;
	reg adc_clk_ff = 1'b0;
	reg [7:0] adc_data_rg_iob = 8'b0;
	reg video_frame_valid_ff = 1'b0;
	reg video_line_valid_ff = 1'b0;
	reg video_data_valid_ff = 1'b0;	
	reg [7:0] video_data_rg = 8'b0;
	reg [9:0] addr_col_cnt = 10'b0;
	reg [8:0] addr_row_cnt = 9'b0;
	reg dac_clk_ff = 1'b0;
	reg dac_blanc_ff = 1'b0;
	
////////////////////////////////////////////////////
// metastability protection

always @(posedge clk_108_mhz)
begin
	comp_sync_mstb <= {comp_sync_mstb[1:0], comp_sync};
	vert_sync_mstb <= {vert_sync_mstb[0], vert_sync};
	oddeven_mstb <= {oddeven_mstb[0], oddeven};
end
	
////////////////////////////////////////////////////
// local reset

always @(posedge clk_108_mhz)
	if (reset)
		local_reset <= 1'b1;
	else 
		local_reset <= (local_reset & (vert_sync_mstb[1] | oddeven_mstb[1]));	

////////////////////////////////////////////////////
// counter up 8 (0..7) divides 108 Mhz clock and forms adc clock  

assign cnt_up_8_rst = comp_sync_mstb[2] & ~comp_sync_mstb[1];

always @(posedge clk_108_mhz)
	if (cnt_up_8_rst)
		cnt_up_8 <= 4'b0;
	else 
		cnt_up_8 <= cnt_up_8[2:0] + 1'b1;
		
////////////////////////////////////////////////////
// adc data address maping

assign col_cnt_rst = ~local_reset & comp_sync_mstb[1];
assign col_cnt_en = cnt_up_8[3];

always @(posedge clk_108_mhz)
	if (!col_cnt_rst)
		col_cnt <= 10'b0;
	else if (col_cnt_en)
		col_cnt <= col_cnt + 1'b1;

always @(posedge clk_108_mhz)
	if (comp_sync_mstb[1])
		pulse <= 2'b01;
	else 
		pulse <= {pulse[0], 1'b0}; 

assign row_cnt_rst = ~local_reset & vert_sync_mstb[1];
assign row_cnt_en = pulse[1];

always @(posedge clk_108_mhz)
	if (!row_cnt_rst)
		row_cnt <= 9'b0;
	else if (row_cnt_en)
		row_cnt <= row_cnt + 1'b1;
		
////////////////////////////////////////////////////
// adc data border creation

assign up_border = oddeven_mstb[1] ? up_border_field1[8:0] : up_border_field0[8:0];
assign down_border = oddeven_mstb[1] ? down_border_field1[8:0] : down_border_field0[8:0];

assign up_border_cmpr = (row_cnt >= up_border);
assign down_border_cmpr = (row_cnt <= down_border);
assign left_border_cmpr = (col_cnt >= left_border);
assign right_border_cmpr = (col_cnt <= right_border);
assign line_valid = (left_border_cmpr & right_border_cmpr);
assign frame_valid = (up_border_cmpr & down_border_cmpr);
	
////////////////////////////////////////////////////
// adc clk, adc data latch into iob and adc_clamp generation

always @(posedge clk_108_mhz)
	adc_clk_ff <= cnt_up_8[2];

always @(posedge clk_108_mhz)
	if (cnt_up_8[3])
		adc_data_rg_iob <= adc_data;
	
assign adc_clamp = ~burst;	
assign adc_clk = adc_clk_ff;

////////////////////////////////////////////////////
// video signals
		
always @(posedge clk_108_mhz)
	if (!line_valid || !frame_valid)
		video_data_rg <= 8'b0;
	else
		video_data_rg <= adc_data_rg_iob;
		
assign video_data = video_data_rg;		

// video address

always @(posedge clk_108_mhz)
	if (!line_valid)
		addr_col_cnt <= 10'b0;
	else if (cnt_up_8 == 4'd1)
		addr_col_cnt <= addr_col_cnt + 1'b1;

always @(posedge clk_108_mhz)
	if (!frame_valid)
		addr_row_cnt <= 9'b0;
	else if ((cnt_up_8 == 4'd1) && (addr_col_cnt == 10'd701))
		addr_row_cnt <= addr_row_cnt + 1'b1;
				
assign video_address = {addr_row_cnt, oddeven_mstb[1], addr_col_cnt};

// video signals

always @(posedge clk_108_mhz)
begin
	video_frame_valid_ff <= frame_valid;
	video_line_valid_ff <= line_valid;
	video_data_valid_ff <= frame_valid & line_valid & (cnt_up_8 == 4'd1);
end

assign video_frame_valid = video_frame_valid_ff;
assign video_line_valid = video_line_valid_ff;
assign video_data_valid = video_data_valid_ff;

////////////////////////////////////////////////////
// dac signals

always @(posedge clk_108_mhz)
	dac_blanc_ff <= frame_valid & line_valid;

always @(posedge clk_108_mhz)
	dac_clk_ff <= cnt_up_8[3];

assign dac_clk = dac_clk_ff;	
assign dac_blanc = dac_blanc_ff;
	
endmodule 