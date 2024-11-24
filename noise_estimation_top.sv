/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module noise_estimation #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples per block (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	// controller
	input  logic                   start_of_frame, end_of_frame, 
	input logic  [31:0]            blocks_per_frame,
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