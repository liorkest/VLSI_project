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
	 // output logic                     mean_ready, // we need to remove this! LK 12.12.24
	output logic                   variance_ready,   // pulse that says that block statistics are ready     
	output logic [DATA_WIDTH-1:0]   data_out // added 12.12.24 LK
);




// wires from FSM
logic shift_en_1, shift_en_2, shift_en_mean, shift_reg_rst_n, variance_start_of_data;
logic mean_ready; // added LK [12.12.24]
// interconnect wires between units
logic [2*DATA_WIDTH-1:0]  block_mean;
logic [DATA_WIDTH-1:0] serial_lvl_1; // renamed 12.12.24 LK

/* removed by LK [12.12.24] 
logic is_first_block;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n || start_of_frame) begin
		mean_out <= 0;
		is_first_block <= 0;
	end
	if (variance_ready) begin 
		if (!is_first_block)
			//mean_out <= block_mean;
		else
			is_first_block <= 0;
	end
end*/


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
	.shift_en_1(shift_en_1),
	.shift_en_2(shift_en_2),
	.shift_reg_rst_n(shift_reg_rst_n),
	.variance_start_of_data(variance_start_of_data),
	.shift_en_mean(shift_en_mean)
);


mean_unit #(
	.DATA_WIDTH(DATA_WIDTH)
) mean_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.total_samples(blocks_per_frame),
	.data_in(data_in),
	.start_data_in(start_data),
	.en(1),                        // entered constant [05.12.24] LK
	.mean_out(block_mean),
	.ready(mean_ready)
);


shift_register#(
	.BYTE_WIDTH(DATA_WIDTH),
	.DEPTH(TOTAL_SAMPLES)
) shift_register_data_in_1 ( // renamed 12.12.24 LK
	.clk(clk),
	.rst_n(shift_reg_rst_n),
	.serial_in(data_in),
	.shift_en(shift_en_1),

	.serial_out(serial_lvl_1) // renamed 12.12.24 LK
);

// added new module 12.12.24 LK
shift_register#(
	.BYTE_WIDTH(DATA_WIDTH),
	.DEPTH(TOTAL_SAMPLES)
) shift_register_data_in_2 (
	.clk(clk),
	.rst_n(shift_reg_rst_n),
	.serial_in(serial_lvl_1), // LS, FYI - the shift registers are concatenated!
	.shift_en(shift_en_2),

	.serial_out(data_out)
);

// NEW module LK [12.12.24]
shift_register#(
	.BYTE_WIDTH(DATA_WIDTH*2),
	.DEPTH(2)
) shift_register_mean (
	.clk(clk),
	.rst_n(shift_reg_rst_n | start_of_frame),
	.serial_in(block_mean),
	.shift_en(shift_en_mean),
	.serial_out(mean_out)
);

// module added on 12.12.24 LK
variance_unit #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) variance_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.data_in(serial_lvl_1),
	.start_data_in(variance_start_of_data),
	.mean_in(block_mean),
	.variance_out(block_variance),
	.ready(variance_ready)
);


endmodule