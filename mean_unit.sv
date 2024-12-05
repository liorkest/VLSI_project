/*------------------------------------------------------------------------------
 * File          : mean_unit.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   : this unit gets sequence of TOTAL_SAMPLES bytes, and outputs the mean, as regular unsigned int.
 *------------------------------------------------------------------------------*/

module mean_unit #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data_in,
	input  logic                   en,
	output logic [2*DATA_WIDTH-1:0]  mean_out, // 16-bit mean value output
	output logic                   ready         // Ready signal when mean is computed
);

	// Internal signals
	logic [31:0] count;
	logic [31:0] sum;

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			sum <= 0;
			count <= 0;
			mean_out <= 0;
			ready <=0;
		end else if (count < TOTAL_SAMPLES && !start_data_in && !ready)  begin
			if (en) begin
					sum <= sum + data_in;
					count <= count + 1;		
			end
		end else if (count == TOTAL_SAMPLES) begin
			sum <= 0;
			count <= 0;
			ready <= 1;
			mean_out <= sum >> $clog2(TOTAL_SAMPLES);
		end else if (start_data_in) begin
				count <= 0;
				ready <= 0;
				//mean_out <= 0; [05.12.24]
		end

	end
	
	

endmodule
