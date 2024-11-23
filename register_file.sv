
module register_file (
	input  logic        clk,
	input  logic        resetn,

	// Write Channel for AXI Lite
	input  logic [3:0]  write_addr,  // 4-bit write address (16 registers)
	input  logic [31:0] write_data,  // 32-bit write data
	input  logic        write_en,    // Write enable

	// Read channel for AXI Lite
	input  logic [3:0]  read_addr,   // 4-bit read address (16 registers)
	output logic [31:0] read_data,   // 32-bit read data
	
	// Read wires for all modules
	output logic [31:0] res_x,
	output logic [31:0] res_y,
	output logic [31:0] fps
);

	// Register array: 16 registers of 32 bits
	logic [31:0] reg_file [15:0];

	// Write operation
	always_ff @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			// Initialize registers to 0 on reset
			integer i;
			for (i = 0; i < 16; i = i + 1) begin
				reg_file[i] <= 32'b0;
			end
		end else if (write_en) begin
			reg_file[write_addr] <= write_data;
		end
	end

	// Read operation for all blocks
	assign res_x = reg_file[0];
	assign res_y = reg_file[1];
	assign fps = reg_file[2];
	
	// Read operation for AXI Lite slave
	assign read_data = reg_file[read_addr];

endmodule
