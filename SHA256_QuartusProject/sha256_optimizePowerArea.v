// Copyright (C) 1991-2013 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License 
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.

// PROGRAM		"Quartus II 64-Bit"
// VERSION		"Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"
// CREATED		"Sun May 18 18:59:15 2025"

module sha256_optimizePowerArea(
	CLK,
	RESET_N,
	START,
	DATA_VALID,
	DATA_IN,
	done,
	output_sha256top
);


input wire	CLK;
input wire	RESET_N;
input wire	START;
input wire	DATA_VALID;
input wire	[31:0] DATA_IN;
output wire	done;
output wire	[255:0] output_sha256top;

wire	Done_comp;
wire	[255:0] Final_out;
wire	[3:0] message_word_addr;
wire	[31:0] message_word_in;
wire	[255:0] output_final;
wire	[5:0] round_t;
wire	start_to_comp;
wire	STN_comp;
wire	STN_to_sche;
wire	write_enable_in;
wire	[31:0] Wt_out_sche;
wire	[31:0] Wt_to_comp;





message_scheduler	b2v_inst(
	.clk(CLK),
	.reset_n(RESET_N),
	.STN(STN_to_sche),
	.write_enable_in(write_enable_in),
	.message_word_addr(message_word_addr),
	.message_word_in(message_word_in),
	.round_t(round_t),
	.Wt_out(Wt_out_sche));


message_compression	b2v_inst1(
	.clk(CLK),
	.rst_n(RESET_N),
	.start(start_to_comp),
	.Wt_in(Wt_to_comp),
	
	.done(Done_comp),
	.STN(STN_comp),
	.H_final_out(Final_out));


controller	b2v_inst2(
	.clk(CLK),
	.reset_n(RESET_N),
	.start(START),
	.wrapper_data_valid(DATA_VALID),
	.STN_from_comp(STN_comp),
	.done_from_comp(Done_comp),
	.hash_final_from_comp(Final_out),
	.wrapper_data(DATA_IN),
	.Wt_from_sche(Wt_out_sche),
	
	.write_enable_in(write_enable_in),
	.STN_to_sche(STN_to_sche),
	.start_to_comp(start_to_comp),
	.done(done),
	.hash_output(output_final),
	.message_word_addr(message_word_addr),
	.message_word_in(message_word_in),
	.round_t(round_t),
	.Wt_to_comp(Wt_to_comp));

assign	output_sha256top = output_final;

endmodule
