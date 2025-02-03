/*------------------------------------------------------------------------------
 * File          : noise_estimation_top.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 29, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module noise_estimation #(
	parameter DATA_WIDTH = 8,         // Width of input data (each pixel in the channel)
	parameter TOTAL_SAMPLES = 8     // Total number of pixels per block (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	// controller
	input  logic                   start_of_frame, // end_of_frame, //[LS 31.01.25] removing - not used
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data,
	input  logic [31:0]            blocks_per_frame,
	
	output logic                   mean_ready,
	output logic [2*DATA_WIDTH-1:0]  estimated_noise, 
	output logic                   estimated_noise_ready         // Ready signal when estimated_noise is computed
);



typedef enum logic [1:0] {
	PENDING = 2'd0,
	CALCULATING = 2'd1
 } state_t;

state_t state, next_state;


// wires from FSM
logic shift_en, noise_mean_en, shift_reg_rst_n, variance_start_of_data, variance_ready;
// interconnect wires between units
logic [2*DATA_WIDTH-1:0]  block_mean;
logic [DATA_WIDTH-1:0] serial_out;
logic [2*DATA_WIDTH-1:0] variance_of_block;

// FSM
wire start_data_mean2;

noise_estimation_FSM #(.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) noise_estimation_FSM_inst (
	.clk(clk),
	.rst_n(rst_n),
	.start_of_frame(start_of_frame),
	//.end_of_frame(end_of_frame),
	.mean_ready(mean_ready),
	.variance_ready(variance_ready),
	.blocks_per_frame(blocks_per_frame),
	.shift_en(shift_en),
	.noise_mean_en(noise_mean_en),
	.shift_reg_rst_n(shift_reg_rst_n),
	.variance_start_of_data(variance_start_of_data),
	.start_data_mean2(start_data_mean2)
);


mean_unit #(
	.DATA_WIDTH(DATA_WIDTH)
) mean_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.total_samples(TOTAL_SAMPLES), // was 'blocks_per_frame' changed to 'TOTAL_SAMPLES' [LK 07.01.25]
	.data_in(data_in),
	.start_data_in(start_data),
	.en(1),                        // entered constant [05.12.24]
	.mean_out(block_mean),
	.ready(mean_ready)
);


shift_register#(
	.DATA_WIDTH(DATA_WIDTH),
	.DEPTH(TOTAL_SAMPLES)
) shift_register_inst (
	.clk(clk),
	.rst_n(shift_reg_rst_n),
	.serial_in(data_in),
	.shift_en(shift_en),

	.serial_out(serial_out)
);

variance_unit #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) variance_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.data_in(serial_out),
	.start_data_in(variance_start_of_data),
	.mean_in(block_mean),
	.variance_out(variance_of_block),
	.ready(variance_ready)
);


mean_unit #(
	.DATA_WIDTH(DATA_WIDTH*2) // added *2 [06.12.24 LK]
) mean_unit_for_variances (
	.clk(clk),
	.rst_n(rst_n),
	.total_samples(blocks_per_frame),
	.data_in(variance_of_block),
	.start_data_in(start_data_mean2),
	.en(noise_mean_en),
	.mean_out(estimated_noise),
	.ready(estimated_noise_ready)
);

endmodule