/*------------------------------------------------------------------------------
 * File          : Weiner_filter.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 3, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module data_gen #(
	parameter DATA_WIDTH = 32
)(
	input  logic                  clk,
	input  logic                  rst_n,
	output logic [DATA_WIDTH-1:0] data_out,
	output logic                  valid_out,
	output logic                  last_out,
	output logic                  user_out
);

	// Internal data counter for generating sequential data
	logic [DATA_WIDTH-1:0] data_counter;
	logic [3:0]            frame_counter;

	// Frame parameters
	parameter FRAME_LENGTH = 16; // Example: 16 cycles per frame

	// Data generation logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			data_counter <= 0;
			frame_counter <= 0;
			valid_out <= 0;
			last_out <= 0;
			user_out <= 0;
		end else begin
			// Set user signal high at start of frame
			user_out <= (frame_counter == 0);

			// Set valid high for data transmission
			valid_out <= 1;

			// Output data
			data_out <= data_counter;

			// Increment data and frame counters
			data_counter <= data_counter + 1;
			frame_counter <= frame_counter + 1;

			// Set last signal at end of frame
			if (frame_counter == FRAME_LENGTH - 1) begin
				last_out <= 1;
				frame_counter <= 0; // Reset frame counter for next frame
			end else begin
				last_out <= 0;
			end
		end
	end
endmodule