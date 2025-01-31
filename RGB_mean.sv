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

logic [DATA_WIDTH+1:0] sum;

// divider inst
logic [DATA_WIDTH+1 : 0] a;
logic [DATA_WIDTH+1 : 0] b = 3;
logic [DATA_WIDTH+1 : 0] quotient; 
logic [DATA_WIDTH+1 : 0] remainder;
logic divide_by_0;
DW_div_10bit_inst divider (.*);


assign sum = data_in[7:0] + data_in[15:8] + data_in[23:16];
assign a = sum;
always_comb begin
	if (en) begin
		data_out = quotient[DATA_WIDTH-1 : 0];
	end else begin
		data_out = 0;
	end
end

endmodule