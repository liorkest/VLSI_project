/*------------------------------------------------------------------------------
 * File          : shift_register_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module shift_register_tb;
// Parameters
parameter DATA_WIDTH = 8;
parameter DEPTH = 10;

// Signals
logic                   clk;
logic                   rst_n;
logic [DATA_WIDTH-1:0]  serial_in;
logic                   shift_en;
logic [DATA_WIDTH-1:0]  serial_out;

// Instantiate the shift register
shift_register#(
	.DATA_WIDTH(DATA_WIDTH),
	.DEPTH(DEPTH)
) uut (
	.clk(clk),
	.rst_n(rst_n),
	.serial_in(serial_in),
	.shift_en(shift_en),
	.serial_out(serial_out)
);

// Clock generation
always #5 clk = ~clk;

// Test sequence
initial begin
	// Initialize signals
	clk = 0;
	rst_n = 0;
	shift_en = 0;
	serial_in = 8'h00;

	// Reset the design
	#10 rst_n = 1;

	// Load and shift data
	shift_en = 1;
	serial_in = 8'hAA;
	#10 serial_in = 8'hBB;
	#10 serial_in = 8'hCC;

	// Hold shift_en to observe the shift
	#100 shift_en = 0;
	#50 $finish;
end
endmodule