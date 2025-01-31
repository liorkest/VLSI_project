/*------------------------------------------------------------------------------
 * File          : AXI_memory_slave.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 05, 2025
 * Description   : 
 * addressing convention: each address increment is WORD. each time we read 4-bytes (1 word)
 *------------------------------------------------------------------------------*/

module AXI_memory_slave_3channels #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter ID_WIDTH = 4,
	parameter MEM_SIZE  = 1024,
	parameter INIT_OPTION = 1 // 0=[all zeros], 1=[pre-defined 4 blocks values] 
) (
	input                       clk,
	input                       rst_n,

	// Write address channel
	input  [ADDR_WIDTH-1:0]     awaddr,
	//input  [7:0]                awlen, [LS 31.01.25] not used
	input                       awvalid,
	output logic                  awready,

	// Write data channel
	input  [DATA_WIDTH-1:0]     wdata,
	input                       wvalid,
	output logic                  wready,
	input                       wlast,

	// Write response channel
	output logic [1:0]            bresp,
	output logic                  bvalid,
	input                       bready,

	// #1 Read address channel
	input  [ADDR_WIDTH-1:0]     araddr,
	input  [7:0]                arlen,
	input                       arvalid,
	output logic                  arready,

	// #1 Read data channel
	output logic [DATA_WIDTH-1:0] rdata,
	output logic                  rvalid,
	input                       rready,
	output logic                  rlast,
	
	// #2 Read address channel
	input  [ADDR_WIDTH-1:0]     araddr_2,
	input  [7:0]                arlen_2,
	input                       arvalid_2,
	output logic                  arready_2,

	// #2 Read data channel
	output logic [DATA_WIDTH-1:0] rdata_2,
	output logic                  rvalid_2,
	input                       rready_2,
	output logic                  rlast_2
	
);


	// Memory array
	logic [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];



	logic [7:0] data [0:255] = {46,18,253,180,124,96,88,49,208,206,155,1,179,123,138,250,216,127,228,182,254,188,95,142,26,80,2,31,75,25,112,107,247,119,91,68,236,6,240,149,225,183,131,124,66,250,80,62,0,23,239,96,218,77,79,47,37,175,123,49,143,147,10,39,130,77,75,73,99,27,186,150,129,2,251,3,67,216,64,156,85,11,146,136,190,216,114,108,18,236,166,44,93,144,108,13,15,182,216,161,7,40,168,93,121,217,227,115,180,239,158,178,140,166,205,71,207,108,151,84,52,110,206,210,52,99,166,193,38,46,0,86,143,0,247,120,224,252,191,48,192,130,86,238,229,115,50,73,163,152,176,42,236,194,4,118,41,254,30,199,165,165,180,98,126,42,242,23,169,244,101,58,149,25,122,174,199,52,7,152,12,123,254,78,66,89,47,213,150,92,64,206,62,83,81,41,192,42,230,141,99,33,46,19,140,202,184,93,17,78,74,17,188,6,66,246,238,155,85,52,88,149,191,10,158,30,7,32,76,177,176,50,224,115,12,246,175,226,144,144,111,130,4,55,201,207,189,66,95,25,181,111,80,186,234,113};

	// AXI Slave Write Response Simulation
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			awready <= 0;
			wready <= 0;
			bvalid <= 0;
			for(int i=0; i< MEM_SIZE; i++) begin
				case (INIT_OPTION) 
					0: memory[i] = 32'd0; 
					1: memory[i] = {8'd0,data[i],data[i],data[i]}; 
				endcase
			end
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

	// #1 AXI Slave Read Response Simulation
	// Internal signals for read FSM
	logic [ADDR_WIDTH-1:0] read_addr;
	logic [31:0] read_data_count; 
	logic [31:0] read_len;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			arready <= 0;
			rvalid <= 0;
			rdata <= 0;
			read_len <= 0;  // Make sure read_len is reset
			read_data_count <= 0; // [LK 01.01.24]
			rlast <= 0;			
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
	
	// #2 AXI Slave Read Response Simulation
	// Internal signals for read FSM
	logic [ADDR_WIDTH-1:0] read_addr_2;
	logic [31:0] read_data_count_2; 
	logic [31:0] read_len_2;
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			arready_2 <= 0;
			rvalid_2 <= 0;
			rdata_2 <= 0;
			read_len_2 <= 0;  // Make sure read_len is reset
			read_data_count_2 <= 0; // [LK 01.01.24]
			rlast_2 <= 0;
			
		end else begin
			// Simulate arready
			if (arvalid_2 && !arready_2) begin
				arready_2 <= 1;
			end else begin
				arready_2 <= 0;
			end
			
			if (rvalid_2) begin			
				rdata_2 <= memory[araddr_2];  // Provide read data from memory
				read_data_count_2 <= read_data_count_2 + 1; // [LK 01.01.24]
				rlast_2 <= (read_data_count_2 == read_len_2 - 1);
			end 

			// Simulate rvalid and rdata for burst mode
			if (arvalid_2 && arready_2) begin
				rvalid_2 <= 1;  // Keep rvalid high during the burst
				read_len_2 <= arlen_2;
			end else if (rready_2 && rvalid_2 && rlast_2) begin
				rvalid_2 <= 0;  // Only deassert rvalid once the burst is finished
				rlast_2 <= 0;   // Reset rlast
				read_data_count_2 <= 0; // [LK 01.01.24]
			end
			

		end
	end


endmodule