/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_burst.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   : AXI Memory Master with Burst Support
 *------------------------------------------------------------------------------*/

module AXI_memory_master_burst #
(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4
)
(
	input  logic                    clk,
	input  logic                    resetn,

	// Write Address Channel
	output logic [ID_WIDTH-1:0]     awid,
	output logic [ADDR_WIDTH-1:0]   awaddr,
	output logic [7:0]              awlen,
	output logic [2:0]              awsize,
	output logic [1:0]              awburst,
	output logic                    awvalid,
	input  logic                    awready,

	// Write Data Channel
	output logic [DATA_WIDTH-1:0]   wdata,
	output logic [DATA_WIDTH/8-1:0] wstrb,
	output logic                    wlast,
	output logic                    wvalid,
	input  logic                    wready,

	// Write Response Channel
	//input  logic [ID_WIDTH-1:0]     bid,
	//input  logic [1:0]              bresp,
	input  logic                    bvalid,
	output logic                    bready,

	// Read Address Channel
	output logic [ID_WIDTH-1:0]     arid,
	output logic [ADDR_WIDTH-1:0]   araddr,
	output logic [7:0]              arlen,
	output logic [2:0]              arsize,
	output logic [1:0]              arburst,
	output logic                    arvalid,
	input  logic                    arready,

	// Read Data Channel
	//input  logic [ID_WIDTH-1:0]     rid,  // [LS 31.01.25] not used
	//input  logic [DATA_WIDTH-1:0]   rdata,  // [LS 31.01.25] not used
	//input  logic [1:0]              rresp,  // [LS 31.01.25] not used
	input  logic                    rlast,
	input  logic                    rvalid,
	output logic                    rready,

	// Control signals - to receive data to stream
	input  logic                    start_write,
	input  logic [ID_WIDTH-1:0]     write_id,
	input  logic [ADDR_WIDTH-1:0]   write_addr,
	input  logic [31:0]             write_len,
	input  logic [2:0]              write_size,
	input  logic [1:0]              write_burst,
	input  logic [DATA_WIDTH-1:0]   write_data,
	input  logic [DATA_WIDTH/8-1:0] write_strb,
	input  logic                    start_read,
	input  logic [ID_WIDTH-1:0]     read_id,
	input  logic [ADDR_WIDTH-1:0]   read_addr,
	input  logic [31:0]             read_len,
	input  logic [2:0]              read_size,
	input  logic [1:0]              read_burst
);

// Write Address State Machine
typedef enum logic [1:0] {
	WRITE_IDLE,
	WRITE_ADDR,
	WRITE_DATA,
	WRITE_RESP
} write_state_t;

write_state_t write_state, write_state_next;
logic [7:0] write_beat_count;   // Counter for beats in the burst
logic [ADDR_WIDTH-1:0] write_burst_addr;  // Current burst address

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn) begin
		write_state <= WRITE_IDLE;
		write_beat_count <= 8'd0;
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
				write_beat_count <= 8'd0;
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
assign awid = write_id;
assign awaddr = write_burst_addr;
assign awlen = write_len;  // Burst length
assign awsize = write_size;
assign awburst = write_burst;
assign awvalid = (write_state == WRITE_ADDR);

// Write Data Channel
assign wdata = write_data;  // Streamed data (input should provide data for each beat)
assign wstrb = write_strb;  // Write strobe
assign wlast = (write_beat_count == write_len);  // Assert on last beat
assign wvalid = (write_state == WRITE_DATA);
assign bready = (write_state == WRITE_RESP);

// Read Address State Machine
typedef enum logic [1:0] {
	READ_IDLE,
	READ_ADDR,
	READ_DATA
} read_state_t;

read_state_t read_state, read_state_next;
logic [7:0] read_beat_count;  // Counter for beats in the burst
logic [ADDR_WIDTH-1:0] read_burst_addr;  // Current burst address

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn) begin
		read_state <= READ_IDLE;
		read_beat_count <= 8'd0;
		read_burst_addr <= 0;
	end else begin
		read_state <= read_state_next;
		if (read_state == READ_DATA && rready && rvalid) begin
			if (read_beat_count < read_len) begin
				read_beat_count <= read_beat_count + 1;
				read_burst_addr <= read_burst_addr + 1;  // Increment by 2^read_size [LK 06.01.25] changed back to 1
			end else begin
				read_beat_count <= 8'd0;
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
assign arid = read_id;
assign araddr = read_burst_addr;
assign arlen = read_len;  // Burst length
assign arsize = read_size;
assign arburst = read_burst;
assign arvalid = (read_state == READ_ADDR);

// Read Data Channel
assign rready = (read_state == READ_DATA);

endmodule
