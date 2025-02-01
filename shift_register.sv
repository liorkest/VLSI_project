/*------------------------------------------------------------------------------
 * File          : shift_register.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module shift_register #(
	parameter DATA_WIDTH = 8,        // Width of a byte
	parameter DEPTH = 64            // Number of bytes in the shift register
)(
	input  logic                   clk,      // Clock signal
	input  logic                   rst_n,    // Asynchronous reset
	input  logic [DATA_WIDTH-1:0]  serial_in, // Serial input (1 byte at a time)
	input  logic                   shift_en,  // Enable signal for shifting
	output logic [DATA_WIDTH-1:0]  serial_out // Serial output (1 byte)
);

	// Register array to hold the bytes
	logic [DATA_WIDTH-1:0] shift_reg [0:DEPTH-1];
	int i;
	
	// Shift operation
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			// Reset all registers to 0
			for (int i = 0; i < DEPTH; i++) begin
				shift_reg[i] <= '0;
			end
		end else if (shift_en) begin
			
			// Shift data
			for (i = DEPTH-1; i > 0; i--) begin
				shift_reg[i] <= shift_reg[i-1];
			end
			shift_reg[0] <= serial_in; // Load new data into the first position
		end
	end

	// Assign the last byte to the serial output
	assign serial_out = shift_reg[DEPTH-1];

endmodule