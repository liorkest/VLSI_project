/*------------------------------------------------------------------------------
 * File          : RGB_mean.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 19, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module RGB_mean #(
	parameter DATA_WIDTH = 8        // Width of 1 channel
)(
	input logic en,
	input  logic [DATA_WIDTH*3-1:0]  data_in,
	output logic [DATA_WIDTH-1:0]  data_out
);

logic [4*DATA_WIDTH-1:0] sum;

// divider inst
logic [4*DATA_WIDTH-1 : 0] a;
logic [4*DATA_WIDTH-1 : 0] b = 3;
logic [4*DATA_WIDTH-1 : 0] quotient; // result of 16.0 / 16.0 fixed point division = 16.16 format
logic [4*DATA_WIDTH-1 : 0] remainder;
logic divide_by_0;
DW_div divider (.*);


assign sum = data_in[7:0] + data_in[15:8] + data_in[23:16];
assign a = sum << 2*DATA_WIDTH;
always_comb begin
	if (en) begin
		data_out = quotient >>  2*DATA_WIDTH;
	end else begin
		data_out = 0;
	end
end

endmodule