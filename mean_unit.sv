/*------------------------------------------------------------------------------
 * File          : mean_unit.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 10, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module mean_unit #(parameter frac_bits)(   // data_len will be block_size**2
	input wire clk,
	input wire reset,
	input wire [31:0] data_len,
	input wire [31:0] data_in,   // If we have one channel intensity than only one byte will be used, sign extended. 0-255
	input wire valid,
	input wire start_data,
	output logic [31:0] mean,
	output logic mean_valid
);

	// Internal signals
	logic [31:0] count;
	logic [31:0] sum;
	logic last;


	always @(posedge clk, posedge reset) begin
		mean_valid <= 1'b0;
		if (reset) begin
			count <= 0;
			mean <= 0;
			last <= 1;
			sum <= 0;
			mean_valid <= 0;
		end else if (valid) begin 
			if (last) begin
				last <= 1'b0;
			end
			if (count < data_len) begin
				count <= count + 1;
				
				sum <= sum + data_in;
			end else begin
					mean <= (sum <<< frac_bits) / data_len;
					mean_valid <= 1'b1;
					count <= 0;
					sum <= 0;
					last <= 1'b1;
			end
		end 
	end

endmodule
