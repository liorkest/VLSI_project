/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 29, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module wiener_block_stats #(
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
	
	output logic [2*DATA_WIDTH-1:0]  block_variance, 
	output logic [2*DATA_WIDTH-1:0]  mean_out, 
	output logic                     mean_ready,
	output logic                   variance_ready         // Ready signal when estimated_noise is computed
);



typedef enum logic [1:0] {
	PENDING = 0,
	CALCULATING = 1
 } state_t;

state_t state, next_state;


// wires from FSM
logic shift_en, shift_reg_rst_n, variance_start_of_data;
// interconnect wires between units
logic [2*DATA_WIDTH-1:0]  block_mean;
logic [DATA_WIDTH-1:0] serial_out;

logic is_first_block;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n || start_of_frame) begin
		mean_out <= 0;
		is_first_block <= 0;
	end
	if (mean_ready) begin
		if (!is_first_block)
			mean_out <= block_mean;
		else
			is_first_block <= 0;
	end
end

wiener_block_stats_FSM #(.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) wiener_block_stats_FSM_inst (
	.clk(clk),
	.rst_n(rst_n),
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.mean_ready(mean_ready),
	.variance_ready(variance_ready),
	.blocks_per_frame(blocks_per_frame),
	.shift_en(shift_en),
	.shift_reg_rst_n(shift_reg_rst_n),
	.variance_start_of_data(variance_start_of_data)
);


mean_unit #(
	.DATA_WIDTH(DATA_WIDTH)
) mean_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.total_samples(blocks_per_frame),
	.data_in(data_in),
	.start_data_in(start_data),
	.en(1),                        // entered constant [05.12.24]
	.mean_out(block_mean),
	.ready(mean_ready)
);


shift_register#(
	.BYTE_WIDTH(DATA_WIDTH),
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
	.variance_out(block_variance),
	.ready(variance_ready)
);


endmodule