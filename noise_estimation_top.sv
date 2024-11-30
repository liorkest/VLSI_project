/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 29, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module noise_estimation #(
	parameter DATA_WIDTH = 8,         // Width of input data (each pixel in the channel)
	parameter TOTAL_SAMPLES = 64,     // Total number of pixels per block (MUST be power of 2)
	parameter BLOCKS_PER_FRAME = 2 
)(
	input  logic                   clk,
	input  logic                   rst_n,
	// controller
	input  logic                   start_of_frame, end_of_frame, 
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data,
	input logic                    end_data,
	
	output logic [2*DATA_WIDTH-1:0]  estimated_noise, 
	output logic                   estimated_noise_ready         // Ready signal when estimated_noise is computed
);



typedef enum logic [1:0] {
	PENDING = 0,
	CALCULATING = 1
 } state_t;

state_t state, next_state;

logic [DATA_WIDTH-1:0]  mean;   // 8-bit mean value (from mean_calculator)

// wires from FSM
logic shift_en, noise_mean_en, shift_reg_rst_n, variance_start_of_data, variance_ready;

noise_estimation_FSM #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES),
	.BLOCKS_PER_FRAME(BLOCKS_PER_FRAME)
) noise_estimation_FSM_inst (
	.clk(clk),
	.rst_n(rst_n),
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.mean_ready(mean_ready),
	.variance_ready(variance_ready),
	.shift_en(shift_en),
	.noise_mean_en(noise_mean_en),
	.shift_reg_rst_n(shift_reg_rst_n),
	.variance_start_of_data(variance_start_of_data)
);

logic [31:0] block_mean;
mean_unit #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) mean_unit_inst (
	.clk(clk),
	.rst_n(rst_n),
	.data_in(data_in),
	.start_data_in(start_data_in),
	.mean_out(mean_out),
	.ready(mean_ready)
);


logic serial_out;
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

logic [31:0] variance_of_block;
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

// Instantiate the variance calculator module
mean_unit #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(BLOCKS_PER_FRAME)
) mean_unit_for_variances (
	.clk(clk & ready),
	.rst_n(rst_n),
	.data_in(variance_of_block),
	.start_data_in(start_of_frame),
	.mean_out(estimated_noise),
	.ready(estimated_noise_ready)
);


always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= PENDING;
	end else begin
		state <= next_state;
	end
end

always_comb begin
	case (state)
		PENDING:
			if (start_of_frame) begin
				next_state = CALCULATING;
			end else begin
				next_state = PENDING;
			end
		CALCULATING:
			if (estimated_noise_ready) begin
				next_state = PENDING;
			end else begin
				next_state = CALCULATING;
			end
		default: begin
			next_state = PENDING;
		end
	endcase
end

endmodule