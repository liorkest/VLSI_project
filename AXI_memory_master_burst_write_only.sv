/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_burst_write_only.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   : AXI Memory Master with Burst Support
 *------------------------------------------------------------------------------*/

module AXI_memory_master_burst_write_only #
(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4
)
(
	input  logic                    clk,
	input  logic                    resetn,

	// Write Address Channel
	output logic [ADDR_WIDTH-1:0]   awaddr,
	output logic [31:0]              awlen,
	output logic [2:0]              awsize,
	output logic [1:0]              awburst,
	output logic                    awvalid,
	input  logic                    awready,

	// Write Data Channel
	output logic [DATA_WIDTH-1:0]   wdata,
	output logic                    wlast,
	output logic                    wvalid,
	input  logic                    wready,

	// Write Response Channel
	input  logic                    bvalid,
	output logic                    bready,


	// Control signals - to receive data to stream
	input  logic                    start_write,
	input  logic [ADDR_WIDTH-1:0]   write_addr,
	input  logic [31:0]             write_len,
	input  logic [2:0]              write_size,
	input  logic [1:0]              write_burst,
	input  logic [DATA_WIDTH-1:0]   write_data
	//input  logic  write_strb
);

// Write Address State Machine
typedef enum logic [1:0] {
	WRITE_IDLE,
	WRITE_ADDR,
	WRITE_DATA,
	WRITE_RESP
} write_state_t;

write_state_t write_state, write_state_next;
logic [31:0] write_beat_count;   // Counter for beats in the burst
logic [ADDR_WIDTH-1:0] write_burst_addr;  // Current burst address

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn) begin
		write_state <= WRITE_IDLE;
		write_beat_count <= 0;
		write_burst_addr <= 0;
	end else begin
		write_state <= write_state_next;
		if (write_state == WRITE_IDLE) begin
			write_burst_addr <= write_addr; // Initialize burst address
		end else if (write_state == WRITE_DATA) begin
			if (wready && wvalid && write_beat_count < write_len) begin
				write_beat_count <= write_beat_count + 1;
				write_burst_addr <= write_burst_addr + 1 ;  // Increment by 2^write_size [LK 06.01.25] changed back from (1 << write_size) to 1
			end else begin
				write_beat_count <= 0;
			end
		end
	end
end

always_comb begin
	write_state_next = write_state;
	case (write_state)
		WRITE_IDLE: begin
			if (start_write)
				write_state_next = WRITE_ADDR;
		end
		WRITE_ADDR: begin
			if (awready && awvalid)
				write_state_next = WRITE_DATA;
		end
		WRITE_DATA: begin
			if (wready && wvalid && wlast)
				write_state_next = WRITE_RESP;
		end
		WRITE_RESP: begin
			if (bvalid && bready)
				write_state_next = WRITE_IDLE;
		end
	endcase
end

// Write Address Channel
assign awaddr = write_burst_addr;
assign awlen = write_len;  // Burst length
assign awsize = write_size;
assign awburst = write_burst;
assign awvalid = (write_state == WRITE_ADDR);

// Write Data Channel
assign wdata = write_data;  // Streamed data (input should provide data for each beat)
//assign wstrb = write_strb;  // Write strobe
assign wlast = (write_beat_count == write_len);  // Assert on last beat
assign wvalid = (write_state == WRITE_DATA);
assign bready = (write_state == WRITE_RESP);



endmodule
