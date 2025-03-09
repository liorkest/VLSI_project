/*------------------------------------------------------------------------------
 * File          : memory_reader_noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_reader_noise_estimation_tb;

	// Parameters
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter BLOCK_SIZE = 4;
	parameter MEM_SIZE = 128;

	// Testbench Signals
	logic clk;
	logic rst_n;
	logic [15:0] frame_height=8;
	logic [15:0] frame_width=8;
	logic frame_ready;
	logic rvalid;
	logic arready;
	logic rlast;
	logic [ADDR_WIDTH-1:0] base_addr_in;
	logic [31:0] len;

	logic start_read;
	logic [ADDR_WIDTH-1:0] read_addr;
	logic [31:0] read_len;
	logic [2:0] read_size;
	logic [1:0] read_burst;
	logic [ADDR_WIDTH-1:0] base_addr_out;
	logic noise_estimation_en;
	logic start_of_frame;
	logic frame_ready_for_wiener;
	reg [31:0] read_data_count; // [LK 01.01.25]

	
	// Read Address Channel
	logic [ADDR_WIDTH-1:0] araddr;
	logic [7:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	logic arvalid;

	// Read Data Channel
	logic [DATA_WIDTH-1:0] rdata;
	logic [1:0] rresp;
	logic rready;

	// Instantiate the DUT (Device Under Test)
	memory_reader_noise_estimation #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.BLOCK_SIZE(BLOCK_SIZE)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready),
		.rvalid(rvalid),
		//.arready(arready),
		.rlast(rlast),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.base_addr_out(base_addr_out),
		.noise_estimation_en(noise_estimation_en),
		.start_of_frame(start_of_frame)
		//.frame_ready_for_wiener(frame_ready_for_wiener)
	);

	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_dut (
		.clk(clk),
		.resetn(rst_n),
		// Write Response Channel
		.bvalid(bvalid),
		.bready(bready),
		
		// Read Address Channel
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		
		// Read Data Channel
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		
		// Control signals
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst)
		
	);
	
	// memory for simulation to store data
	reg [31:0] memory [0:MEM_SIZE];

	// Clock generation
	initial clk = 0;
	always #5 clk = ~clk; // 10ns clock period

	// Testbench logic
	initial begin
		// Initialize signals
		rst_n = 0;
		clk = 0;
		frame_ready = 0;
		rvalid = 0;
		arready = 0;
		rlast = 0;
		base_addr_in = 32'h0000_0000;
		// initialize memory
		for(int i=0; i< MEM_SIZE; i++) begin
			memory[i] = i+1;
		end
		
		// Apply reset
		#20 rst_n = 1;
		#20;

		// Test Case 1: Start a new frame
		frame_ready = 1;
		#10 frame_ready = 0;


		#2000;
		$finish;
	end


	// AXI Slave Read Response Simulation
	always @(posedge clk) begin
		if (!rst_n) begin
			arready <= 0;
			rvalid <= 0;
			rdata <= 0;
			len <= 0;
			read_data_count <= 0; // [LK 01.01.24]
		end else begin
			// Simulate arready
			if (arvalid && !arready) begin
				arready <= 1;
			end else begin
				arready <= 0;
			end

			// Simulate rvalid and rdata for burst mode
			if (arvalid && arready) begin
				rvalid <= 1;  // Keep rvalid high during the burst
				len <= read_len;
			end else if (rready && rvalid && rlast) begin
				rvalid <= 0;  // Only deassert rvalid once the burst is finished
				rlast <= 0;   // Reset rlast
				read_data_count <= 0; // [LK 01.01.24]
			end
			
			if (rvalid) begin			
				rdata <= memory[araddr[7:0]];  // Provide read data from memory
				len <= len - 1;
				read_data_count <= read_data_count + 1; // [LK 01.01.24]
				// Set rlast to 1 when it's the last read in the burst
				rlast <= (len == 1); 
			end 
		end
	end

endmodule