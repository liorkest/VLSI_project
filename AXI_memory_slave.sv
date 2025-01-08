/*------------------------------------------------------------------------------
 * File          : AXI_memory_slave.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 05, 2025
 * Description   : 
 * addressing convention: each address increment is WORD. each time we read 4-bytes (1 word)
 *------------------------------------------------------------------------------*/

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


	// Internal signals for read FSM
	reg [ADDR_WIDTH-1:0] read_addr;
	reg [31:0] read_data_count; 
	reg [31:0] read_len;


	// AXI Slave Write Response Simulation
	always @(posedge clk) begin
		if (!rst_n) begin
			awready <= 0;
			wready <= 0;
			bvalid <= 0;
		end else begin
			// Simulate awready
			if (awvalid && !awready) begin
				awready <= 1;
				wready <= 1; // Constant wready during burst
			end else begin
				awready <= 0;
			end

			// Simulate memory write
			if (wvalid && wready) begin
				memory[awaddr] <= wdata;
			end

			// Simulate bvalid
			if (wvalid && wlast && wready) begin
				bvalid <= 1;
				bresp <= 1;
			end else if (bready && bvalid) begin
				bvalid <= 0;
				bresp <= 0;
			end
		end
	end

	// AXI Slave Read Response Simulation
	always @(posedge clk) begin
		if (!rst_n) begin
			arready <= 0;
			rvalid <= 0;
			rdata <= 0;
			read_len <= 0;  // Make sure read_len is reset
			read_data_count <= 0; // [LK 01.01.24]
			rlast <= 0;
			// initialize memory
			for(int i=0; i< MEM_SIZE; i++) begin
				memory[i] = {8'd0, i[7:0],i[7:0],i[7:0]}; //[LS 06.01.25] easier to see read delay this way
			end
		end else begin
			// Simulate arready
			if (arvalid && !arready) begin
				arready <= 1;
			end else begin
				arready <= 0;
			end
			
			if (rvalid) begin			
				rdata <= memory[araddr];  // Provide read data from memory
				read_data_count <= read_data_count + 1; // [LK 01.01.24]
				rlast <= (read_data_count == read_len - 1);
			end 

			// Simulate rvalid and rdata for burst mode
			if (arvalid && arready) begin
				rvalid <= 1;  // Keep rvalid high during the burst
				read_len <= arlen;
			end else if (rready && rvalid && rlast) begin
				rvalid <= 0;  // Only deassert rvalid once the burst is finished
				rlast <= 0;   // Reset rlast
				read_data_count <= 0; // [LK 01.01.24]
			end
			

		end
	end


endmodule