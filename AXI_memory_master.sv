/*------------------------------------------------------------------------------
 * File          : AXI_memory_master.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jul 23, 2024
 * Description   : 
 *------------------------------------------------------------------------------*/

module AXI_memory_master #
(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4
)
(
	input  wire                    clk,
	input  wire                    resetn,

	// Write Address Channel
	output wire [ID_WIDTH-1:0]     awid,
	output wire [ADDR_WIDTH-1:0]   awaddr,
	output wire [7:0]              awlen,
	output wire [2:0]              awsize,
	output wire [1:0]              awburst,
	output wire                    awvalid,
	input  wire                    awready,

	// Write Data Channel
	output wire [DATA_WIDTH-1:0]   wdata,
	output wire [DATA_WIDTH/8-1:0] wstrb,
	output wire                    wlast,
	output wire                    wvalid,
	input  wire                    wready,

	// Write Response Channel
	input  wire [ID_WIDTH-1:0]     bid,
	input  wire [1:0]              bresp,
	input  wire                    bvalid,
	output wire                    bready,

	// Read Address Channel
	output wire [ID_WIDTH-1:0]     arid,
	output wire [ADDR_WIDTH-1:0]   araddr,
	output wire [7:0]              arlen,
	output wire [2:0]              arsize,
	output wire [1:0]              arburst,
	output wire                    arvalid,
	input  wire                    arready,

	// Read Data Channel
	input  wire [ID_WIDTH-1:0]     rid,
	input  wire [DATA_WIDTH-1:0]   rdata,
	input  wire [1:0]              rresp,
	input  wire                    rlast,
	input  wire                    rvalid,
	output wire                    rready,

	// Control signals
	input  wire                    start_write,
	input  wire [ID_WIDTH-1:0]     write_id,
	input  wire [ADDR_WIDTH-1:0]   write_addr,
	input  wire [7:0]              write_len,
	input  wire [2:0]              write_size,
	input  wire [1:0]              write_burst,
	input  wire [DATA_WIDTH-1:0]   write_data,
	input  wire [DATA_WIDTH/8-1:0] write_strb,
	input  wire                    start_read,
	input  wire [ID_WIDTH-1:0]     read_id,
	input  wire [ADDR_WIDTH-1:0]   read_addr,
	input  wire [7:0]              read_len,
	input  wire [2:0]              read_size,
	input  wire [1:0]              read_burst
);

// Write Address State Machine
typedef enum logic [1:0] {
	WRITE_IDLE,
	WRITE_ADDR,
	WRITE_DATA,
	WRITE_RESP
} write_state_t;

write_state_t write_state, write_state_next;

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn)
		write_state <= WRITE_IDLE;
	else
		write_state <= write_state_next;
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
assign awaddr = write_addr;
assign awlen = write_len;
assign awsize = write_size;
assign awburst = write_burst;
assign awvalid = (write_state == WRITE_ADDR);

// Write Data Channel
assign wdata = write_data;
assign wstrb = write_strb;
assign wlast = (write_len == 8'd0); // Assuming a single beat write for simplicity
assign wvalid = (write_state == WRITE_DATA);

// Write Response Channel
assign bready = (write_state == WRITE_RESP);

// Read Address State Machine
typedef enum logic [1:0] {
	READ_IDLE,
	READ_ADDR,
	READ_DATA
} read_state_t;

read_state_t read_state, read_state_next;

always_ff @(posedge clk or negedge resetn) begin
	if (!resetn)
		read_state <= READ_IDLE;
	else
		read_state <= read_state_next;
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
assign araddr = read_addr;
assign arlen = read_len;
assign arsize = read_size;
assign arburst = read_burst;
assign arvalid = (read_state == READ_ADDR);

// Read Data Channel
assign rready = (read_state == READ_DATA);

endmodule
