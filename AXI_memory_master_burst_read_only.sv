/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_burst_read_only.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Feb 2, 2025
 * Description   : AXI Memory Master with Burst Support
 *------------------------------------------------------------------------------*/

module AXI_memory_master_burst_read_only #
(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4
)
(
	input  logic                    clk,
	input  logic                    resetn,


	// Read Address Channel
	output logic [ADDR_WIDTH-1:0]   araddr,
	output logic [31:0]              arlen,
	output logic [2:0]              arsize,
	output logic [1:0]              arburst,
	output logic                    arvalid,
	input  logic                    arready,

	// Read Data Channel
	input  logic                    rlast,
	input  logic                    rvalid,
	output logic                    rready,

	// Control signals - to receive data to stream
	input  logic                    start_read,
	input  logic [ADDR_WIDTH-1:0]   read_addr,
	input  logic [31:0]             read_len,
	input  logic [2:0]              read_size,
	input  logic [1:0]              read_burst
);
// Read Address State Machine
typedef enum logic [1:0] {
	READ_IDLE,
	READ_ADDR,
	READ_DATA
} read_state_t;

read_state_t read_state, read_state_next;
logic [31:0] read_beat_count;  // Counter for beats in the burst
logic [ADDR_WIDTH-1:0] read_burst_addr;  // Current burst address

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn) begin
		read_state <= READ_IDLE;
		read_beat_count <= 0;
		read_burst_addr <= 0;
	end else begin
		read_state <= read_state_next;
		if (read_state == READ_DATA && rready && rvalid) begin
			if (read_beat_count < read_len) begin
				read_beat_count <= read_beat_count + 1;
				read_burst_addr <= read_burst_addr + 1;  // Increment by 2^read_size [LK 06.01.25] changed back to 1
			end else begin
				read_beat_count <= 0;
			end
		end else if (read_state == READ_IDLE) begin
			read_burst_addr <= read_addr;  // Initialize burst address
		end
	end
end

always_comb begin
	read_state_next = read_state;
	case (read_state)
		READ_IDLE: begin
			if (start_read)
				read_state_next = READ_ADDR;
		end
		READ_ADDR: begin
			if (arready && arvalid)
				read_state_next = READ_DATA;
		end
		READ_DATA: begin
			if (rvalid && rready && rlast)
				read_state_next = READ_IDLE;
		end
	endcase
end

// Read Address Channel
assign araddr = read_burst_addr;
assign arlen = read_len;  // Burst length
assign arsize = read_size;
assign arburst = read_burst;
assign arvalid = (read_state == READ_ADDR);

// Read Data Channel
assign rready = (read_state == READ_DATA);

endmodule
