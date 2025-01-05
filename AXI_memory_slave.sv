/*------------------------------------------------------------------------------
 * File          : AXI_memory_slave.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 05, 2025
 * Description   : 
 *------------------------------------------------------------------------------*/
/*
module AXI_memory_slave#
(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4,
	parameter MEM_SIZE = 32

)
(
	input  logic                    clk,
	input  logic                    rst_n,

	// Write Address Channel
	input logic [ID_WIDTH-1:0]     awid,
	input logic [ADDR_WIDTH-1:0]   awaddr,
	input logic [7:0]              awlen,
	input logic [2:0]              awsize,
	input logic [1:0]              awburst,
	input logic                    awvalid,
	output  logic                    awready,

	// Write Data Channel
	input logic [DATA_WIDTH-1:0]   wdata,
	input logic [DATA_WIDTH/8-1:0] wstrb,
	input logic                    wlast,
	input logic                    wvalid,
	output  logic                    wready,

	// Write Response Channel
	output  logic [ID_WIDTH-1:0]     bid,
	output  logic [1:0]              bresp,
	output  logic                    bvalid,
	input logic                    bready,

	// Read Address Channel
	input logic [ID_WIDTH-1:0]     arid,
	input logic [ADDR_WIDTH-1:0]   araddr,
	input logic [7:0]              arlen,
	input logic [2:0]              arsize,
	input logic [1:0]              arburst,
	input logic                    arvalid,
	output  logic                    arready,

	// Read Data Channel
	input  logic [ID_WIDTH-1:0]     rid,
	output  logic [DATA_WIDTH-1:0]   rdata,
	input  logic [1:0]              rresp,
	output  logic                    rlast,
	output  logic                    rvalid,
	input logic                    rready

);

logic [7:0] read_len;

// memory for simulation to store data
reg [31:0] memory [0:MEM_SIZE];

// AXI Slave Write Simulation
always @(posedge clk) begin
	if (!rst_n) begin
		awready <= 1'd0;
		wready <= 1'd0;
		bvalid <= 1'd0;
	end else begin
		// Simulate awready
		if (awvalid && !awready) begin
			awready <= 1'd1;
		end else begin
			awready <= 1'd0;
		end

		// Keep wready constant during burst
		if (awvalid && awready) begin
			wready <= 1'd1; // Constant wready during burst
		end else if (wlast) begin
			wready <= 1'd0; // Deassert wready at the end of burst
		end

		// Simulate memory write
		if (wvalid && wready) begin
			memory[awaddr] <= wdata;
			$display("saved memory[%0h] = %0h", awaddr, wdata);
		end

		// Simulate write response - bvalid
		if (wvalid && wlast && wready) begin
			bvalid <= 1'd1;
		end else if (bready && bvalid) begin
			bvalid <= 1'd0;
		end
	end
end

// [LK 03.11.25] copied from memory_writer_test_with_axi_mem.sv 
// check the read_len - when is it set??? [LK 03.01.25]
// AXI Slave Read Response Simulation
always @(posedge clk) begin
	if (!rst_n) begin
		arready <= 1'd0;
		rvalid <= 1'd0;
		rdata <= 0;
		rlast <= 1'd0;
		read_len <= 0;  // Make sure read_len is reset
	end else begin
		// Simulate arready
		if (arvalid && !arready) begin
			arready <= 1'd1;
		end else begin
			arready <= 1'd0;
		end

		// Simulate rvalid and rdata for burst mode
		if (arvalid && arready) begin
			rvalid <= 1'd1;  // Keep rvalid high during the burst
			read_len <= arlen;
		end else if (rready && rvalid && rlast) begin
			rvalid <= 1'd0;  // Only deassert rvalid once the burst is finished
			rlast <= 1'd0;   // Reset rlast
		end
		
		if (rvalid) begin			
			rdata <= memory[araddr];  // Provide read data from memory
			// Set rlast to 1 when it's the last read in the burst
			rlast <= (read_len == 0);

			// Decrement the read length as the burst progresses
			if (read_len > 0) 
				read_len <= read_len - 1;
		end 
	end
end




endmodule

*/

module AXI_memory_slave #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4,
	parameter MEM_SIZE  = 1024
) (
	input                       clk,
	input                       rst_n,

	// Write address channel
	input  [ADDR_WIDTH-1:0]     awaddr,
	input  [7:0]                awlen,
	input                       awvalid,
	output reg                  awready,

	// Write data channel
	input  [DATA_WIDTH-1:0]     wdata,
	input                       wvalid,
	output reg                  wready,
	input                       wlast,

	// Write response channel
	output reg [1:0]            bresp,
	output reg                  bvalid,
	input                       bready,

	// Read address channel
	input  [ADDR_WIDTH-1:0]     araddr,
	input  [7:0]                arlen,
	input                       arvalid,
	output reg                  arready,

	// Read data channel
	output reg [DATA_WIDTH-1:0] rdata,
	output reg                  rvalid,
	input                       rready,
	output reg                  rlast
);

	// Memory array
	reg [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];

	// Internal signals for write FSM
	reg [ADDR_WIDTH-1:0] write_addr;
	reg [7:0]            write_count;

	// Internal signals for read FSM
	reg [ADDR_WIDTH-1:0] read_addr;
	reg [7:0]            read_count;

	// State encoding for Write FSM
	typedef enum logic [1:0] {
		WRITE_IDLE   = 2'b00,
		WRITE_ADDR   = 2'b01,
		WRITE_DATA   = 2'b10,
		WRITE_RESP   = 2'b11
	} write_state_t;

	// State encoding for Read FSM
	typedef enum logic [1:0] {
		READ_IDLE    = 2'b00,
		READ_ADDR    = 2'b01,
		READ_DATA    = 2'b10
	} read_state_t;

	// Current and next state for Write FSM
	write_state_t write_state, next_write_state;

	// Current and next state for Read FSM
	read_state_t read_state, next_read_state;

	// Sequential logic for Write FSM
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			write_state <= WRITE_IDLE;
		else
			write_state <= next_write_state;
	end

	// Sequential logic for Read FSM
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			read_state <= READ_IDLE;
		else
			read_state <= next_read_state;
			if(read_state == READ_ADDR) begin 
				read_addr  <= araddr;
				read_count <= arlen;
			end else if(read_state == READ_DATA) begin 
				if (rvalid && rready) begin
					read_addr <= read_addr + 4; // Assume 4-byte addressing
					read_count <= read_count - 1;
				end
			end
	end

	// Write FSM combinational logic
	always_comb begin
		// Default values
		awready = 1'b0;
		wready  = 1'b0;
		bresp   = 2'b00;
		bvalid  = 1'b0;

		case (write_state)
			WRITE_IDLE: begin
				if (awvalid) begin
					next_write_state = WRITE_ADDR;
				end else begin
					next_write_state = WRITE_IDLE;
				end
			end

			WRITE_ADDR: begin
				awready = 1'b1;
				if (awvalid && awready) begin
					write_addr  = awaddr;
					write_count = awlen;
					next_write_state = WRITE_DATA;
				end
			end

			WRITE_DATA: begin
				wready = 1'b1;
				if (wvalid && wready) begin
					memory[write_addr[ADDR_WIDTH-1:2]] = wdata;
					write_addr = write_addr + 4; // Assume 4-byte addressing /////////// LK - need to fix this, to be a valid counter!
					if (wlast || write_count == 0)
						next_write_state = WRITE_RESP;
					else
						write_count = write_count - 1;
				end
			end

			WRITE_RESP: begin
				bvalid = 1'b1;
				if (bvalid && bready)
					next_write_state = WRITE_IDLE;
			end
		endcase
	end

	// Read FSM combinational logic
	always_comb begin
		// Default values
		arready = 1'b0;
		rvalid  = 1'b0;
		rlast   = 1'b0;

		case (read_state)
			READ_IDLE: begin
				if (arvalid) begin
					next_read_state = READ_ADDR;
				end else begin
					next_read_state = READ_IDLE;
				end
			end

			READ_ADDR: begin
				arready = 1'b1;
				if (arvalid && arready) begin
					next_read_state = READ_DATA;
				end
			end

			READ_DATA: begin
				rvalid = 1'b1;
				rdata  = memory[read_addr[ADDR_WIDTH-1:2]];
				rlast  = (read_count == 0);

				if (rvalid && rready) begin
					if (read_count == 0)
						next_read_state = READ_IDLE;
					
					end
			end
		endcase
	end

endmodule