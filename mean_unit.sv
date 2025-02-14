/*------------------------------------------------------------------------------
 * File          : mean_unit.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   : this unit gets sequence of TOTAL_SAMPLES bytes, and outputs the mean, as regular unsigned int.
 *------------------------------------------------------------------------------*/

module mean_unit #(
	parameter DATA_WIDTH = 8        // Width of input data
)(
	input  logic                   clk,
	input  logic                   rst_n,
	input logic  [31:0]            total_samples,//[06.12.24]
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data_in,
	input  logic                   en,
	output logic [2*DATA_WIDTH-1:0]  mean_out, // 16-bit mean value output
	output logic                   ready         // Ready signal when mean is computed
);

	// Internal signals
	logic [31:0] count;
	logic [31:0] sum;
	
	// divider inst
	logic [31:0] quotient; // result of 16.0 / 16.0 fixed point division = 16.16 format
	logic [31:0] remainder;
	logic divide_by_0;
	DW_div_32bit_inst divider (	
		.a          (sum),
		.b          (total_samples),
		.quotient   (quotient   ),
		.remainder  (remainder  ),
		.divide_by_0(divide_by_0)
	);
	

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			sum <= 0;
			count <= 0;
			mean_out <= {2*DATA_WIDTH{1'd0}};
			ready <=1'd0;
		end else if (start_data_in) begin
			count <= 0;
			sum <= 0;
			ready <= 1'd0;
		end else if (count < total_samples && !start_data_in && !ready)  begin
			if (en) begin
					sum <= sum + data_in;
					count <= count + 1;		
			end
		end else if (count == total_samples) begin
			sum <= 0;
			count <= 0;
			ready <= 1'd1;
			mean_out <= quotient;
		end
		
		

	end
	
	

endmodule
