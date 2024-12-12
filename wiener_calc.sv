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
`include "/users/eplkls/DW/DW_div.v"


module wiener_calc #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples per block (MUST be power of 2)
)(
	input logic                   clk,
	input logic                   rst_n,
	input logic                   stats_ready,
	input logic [2*DATA_WIDTH-1:0] mean_of_block, // added 
	input logic [2*DATA_WIDTH-1:0] variance_of_block,
	input logic [2*DATA_WIDTH-1:0] variance_of_noise,
	input logic [DATA_WIDTH-1:0]  data_in,	      // the current pixel channel value 0-255
	input logic [31:0]            blocks_per_frame,
	// outputs
	output logic  [DATA_WIDTH-1:0] data_out,
	output logic [31:0]            data_count // starting from 1 to TOTAL_SAMPLES
);

// the divider needs to be changed to bigger data width!!!
parameter integer a_width  = 8;
parameter integer b_width  = 8;
DW_div divider (.*);
logic  [a_width-1 : 0] a;
logic  [b_width-1 : 0] b;
logic  [a_width-1 : 0] quotient;
logic  [b_width-1 : 0] remainder;
logic 	               divide_by_0;


typedef enum logic [2:0] {
	IDLE = 0,
	calculate = 1
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
				next_state = calculate;
			end else begin
				next_state = IDLE;
			end
		end
		calculate: begin
			if (data_count == TOTAL_SAMPLES) begin
				next_state = IDLE;
			end else begin
				next_state = calculate;
			end
		end
		default: begin
			next_state = IDLE;
		end
	endcase
end

// divider wires
assign a = variance_of_noise + variance_of_block;
assign b = variance_of_block;

// Data processing logic
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		data_count<= 0;
	end else begin
		if (state == IDLE && !next_state == calculate) begin
			data_count <= 0;
		end else if (state == calculate || next_state == calculate) begin  // [12.12.24 LK] I wrote "next_state == calculate ",  otherwise we miss first sample!
			if (data_count == TOTAL_SAMPLES) begin 
				data_count <= 0;
			end else begin
				data_count <= data_count + 1;
				data_out <= mean_of_block + quotient * (data_in - mean_of_block); /// NOT SURE about quotient!!!  this is only the whole part, not fraction. [12.12.24]
			end
		end
	end
end

endmodule




