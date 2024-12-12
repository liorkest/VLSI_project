/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 29, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module wiener_1_channel #(
	parameter DATA_WIDTH = 8,         // Width of input data (each pixel in the channel)
	parameter TOTAL_SAMPLES = 8     // Total number of pixels per frame (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	// controller
	input  logic                   start_of_frame, end_of_frame, 
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data,
	input logic [31:0]            blocks_per_frame,
	input logic [2*DATA_WIDTH-1:0]  noise_variance,
   
	output logic [DATA_WIDTH-1:0]   data_out,
	output logic [31:0]   data_count
);


// wires to wiener
logic [2*DATA_WIDTH-1:0]  block_variance;
logic [2*DATA_WIDTH-1:0]  mean_out;
		 // output logic                     mean_ready, // we need to remove this! LK 12.12.24
logic                     variance_ready;   // pulse that says that block statistics are ready  
logic [DATA_WIDTH-1:0]    serial_data_wire;    
// DUT instantiation
wiener_block_stats #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) wiener_block_stats_inst (
	.clk(clk),
	.rst_n(rst_n),
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.data_in(data_in),
	.start_data(start_data),
	.blocks_per_frame(blocks_per_frame),
	// .mean_ready(mean_ready), // removed  [LK 12.12.24]
	.block_variance(block_variance),
	.mean_out(mean_out),
	.variance_ready(variance_ready),
	.data_out(serial_data_wire)
);

wiener_calc #( 
	.DATA_WIDTH(DATA_WIDTH), 
	.TOTAL_SAMPLES(TOTAL_SAMPLES) 
  ) wiener_calc_inst ( 
	.clk(clk), 
	.rst_n(rst_n), 
	.stats_ready(variance_ready), 
	.mean_of_block(mean_out), 
	.variance_of_block(block_variance), 
	.noise_variance(noise_variance), 
	.data_in(serial_data_wire), 
	.blocks_per_frame(blocks_per_frame), 
	.data_out(data_out), 
	.data_count(data_count) 
  ); 

endmodule