/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 12, 2024
 * Description   : This module receives 
 * 						1. block statistics (mean&variation) 
 * 						2. pixel-by-pixel of block
 * 					and calculates the pixel according to Weiner filter formula, 
 * 					for {TOTAL_SAMPLES} cycles, and goes to IDLE state again.
 *------------------------------------------------------------------------------*/

module wiener_calc #(
	parameter DATA_WIDTH = 8,        // Width of input data
	parameter TOTAL_SAMPLES = 64    // Total number of samples per block (MUST be power of 2)
)(
	input logic                   clk,
	input logic                   rst_n,
	input logic                   stats_ready,
	input logic [2*DATA_WIDTH-1:0] mean_of_block, // added 
	input logic [2*DATA_WIDTH-1:0] variance_of_block,
	input logic [2*DATA_WIDTH-1:0] noise_variance,
	input logic [DATA_WIDTH-1:0]  data_in,	      // the current pixel channel value 0-255
	input logic [31:0]            blocks_per_frame,
	// outputs
	output logic  [DATA_WIDTH-1:0] data_out,
	output logic [31:0]            data_count_out // starting from 1 to TOTAL_SAMPLES
);

logic [31:0]            data_count ;


// divider inst
logic [4*DATA_WIDTH-1 : 0] a;
logic [4*DATA_WIDTH-1 : 0] b;
logic [4*DATA_WIDTH-1 : 0] quotient; // result of 16.0 / 16.0 fixed point division = 16.16 format
logic [4*DATA_WIDTH-1 : 0] remainder;
logic divide_by_0;
DW_div divider (.*);

// divider inputs 
assign a = (variance_of_block >= noise_variance) ? 32'(variance_of_block - noise_variance) << 2*DATA_WIDTH : 32'(noise_variance - variance_of_block) << 2*DATA_WIDTH; // adjust to fixed point
assign b = (variance_of_block == 0) ? 32'b1 : 32'(variance_of_block);

logic signed [31:0] data_out_unclipped;
logic quotient_sign;
logic data_mean_diff_sign;
logic [DATA_WIDTH-1:0] abs_data_mean_diff;
assign quotient_sign = (variance_of_block >= noise_variance) ? 1'b1 : 1'b0; // 1 - positive, 0 - negative
assign data_mean_diff_sign = (data_in >= mean_of_block) ? 1'b1 : 1'b0;
assign abs_data_mean_diff = (data_mean_diff_sign) ? data_in - mean_of_block[DATA_WIDTH-1:0] : mean_of_block[DATA_WIDTH-1:0] -data_in;

typedef enum logic [2:0] {
	IDLE = 0,
	CALCULATE = 1
 } state_t;

state_t state, next_state;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

always_comb begin
	case (state) 
		IDLE: begin
			if (stats_ready) begin
				next_state = CALCULATE;
			end else begin
				next_state = IDLE;
			end
		end
		CALCULATE: begin
			if (data_count > TOTAL_SAMPLES + 1) begin  // +1 due to delay by 2 cycles of data_out
				next_state = IDLE;
			end else begin
				next_state = CALCULATE;
			end
		end
		default: begin
			next_state = IDLE;
		end
	endcase
end



// Data processing logic
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_count<= 0;
		data_count_out <=0;
		data_out <= 0;
		data_out_unclipped <= 0;
	end else begin
		if (state == IDLE && !next_state == CALCULATE) begin
			data_count <= 0;
		end else if (state == CALCULATE ) begin  // [19.12.24 LK] changed back
			if (data_count > TOTAL_SAMPLES + 1) begin // +1 due to delay by 2 cycles of data_out
				data_count <= 0;
			end else begin
				data_count <= data_count + 1;
				data_count_out <= data_count; // [LK 19.12.24] to delay by one cycle, so that output will be synchronized.
				if (quotient_sign == data_mean_diff_sign) begin
					data_out_unclipped <= mean_of_block + ((quotient * abs_data_mean_diff) >> 16);
				end else begin
					data_out_unclipped <= mean_of_block - ((quotient * abs_data_mean_diff) >> 16);
				end
			end
		end
		
		// clipping 0-255 range            // [19.12.24] moved to end of code
		if (data_out_unclipped < 0) begin
			data_out <= 0; 
			//$display("Unclipped: %d, Clipped: %d\n",data_out_unclipped,  0);
		end	else if (data_out_unclipped > 255) begin
				data_out <= 255; 
				//$display("Unclipped: %d, Clipped: %d\n",data_out_unclipped,  255);
		end else begin
			data_out <= data_out_unclipped[DATA_WIDTH-1:0];
		end
	end
end

endmodule




