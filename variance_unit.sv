/*------------------------------------------------------------------------------
 * File          : variance_unit.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 10, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
module variance_unit #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	input  logic [DATA_WIDTH-1:0]  data_in,   // 8-bit input data
	input  logic                   start_data_in,
	input  logic [2*DATA_WIDTH-1:0]  mean_in,   // 8-bit mean value (from mean_calculator)
	output logic [2*DATA_WIDTH-1:0]  variance_out, // 16-bit variance output
	output logic                   ready         // Ready signal when variance is computed
);

	logic [2* DATA_WIDTH - 1:0] variance_sum; // Accumulator for variance sum
	logic [DATA_WIDTH-1:0] count;                       // Counter for number of samples
	logic signed [DATA_WIDTH - 1:0] diff; // added -1 [05.12.24]
	logic [2 * DATA_WIDTH:0] diff_square;

	// Stage 1: Compute diff and diff_square
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			diff <= 0;
			diff_square <= 0;
		end else if (count < TOTAL_SAMPLES && !ready && !start_data_in) begin
			// Variance calculation: (data_in - mean_in)^2
			diff <= data_in - mean_in; // Difference
			diff_square <= diff * diff; // Square of difference
		end 
		if (start_data_in) begin
			diff_square <= 0;
			diff <= 0; // added in [05.12.24]
		end
	end

	// Stage 2: Accumulate variance sum and update count
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			variance_sum <= 0;
			count <= 0;
			ready <= 0;
			variance_out <= 0;
		end else begin
			if (count == TOTAL_SAMPLES + 1) begin
				// When count reaches TOTAL_SAMPLES, calculate final variance
				// Reset for next cycle
				variance_sum <= 0;
				count <= 0;
				ready <= 1;
				// Division 
				variance_out <= variance_sum >> $clog2(TOTAL_SAMPLES);
				
			end else begin
				if (start_data_in) begin
					ready <= 0;
					count <= 0;
					variance_sum <= 0;
				end else if (!ready) begin
					variance_sum <= variance_sum + diff_square;
					count <= count + 1;
				end
				if(ready) begin
					ready <= 0;
				end
			end
		end
	end
endmodule