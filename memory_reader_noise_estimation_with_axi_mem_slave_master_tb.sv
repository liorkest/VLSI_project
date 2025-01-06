/*------------------------------------------------------------------------------
 * File          : memory_reader_noise_estimation_with_axi_mem_slave&mastertb.sv.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 6, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
module memory_reader_noise_estimation_with_axi_mem_slave_master_tb;

	// Parameters
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter BLOCK_SIZE = 4;
	parameter MEM_SIZE = 64;

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
	) memory_reader_noise_estimation_dut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready),
		.rvalid(rvalid),
		.arready(arready),
		.rlast(rlast),
		.base_addr_in(base_addr_in),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.base_addr_out(base_addr_out),
		.noise_estimation_en(noise_estimation_en),
		.start_of_frame(start_of_frame),
		.frame_ready_for_wiener(frame_ready_for_wiener)
	);

	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_dut (
		.clk(clk),
		.resetn(rst_n),
		
		// Read Address Channel
		.arid(arid),
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		
		// Read Data Channel
		.rid(rid),
		.rdata(rdata),
		.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),

		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst)
		
	);
	
	// Instantiate the AXI memory slave
	AXI_memory_slave #(
	  .ADDR_WIDTH(ADDR_WIDTH),
	  .DATA_WIDTH(DATA_WIDTH),
	  .MEM_SIZE(MEM_SIZE)
	) AXI_memory_slave_uut (
	  .clk(clk),
	  .rst_n(rst_n),

	  .araddr(araddr),
	  .arlen(arlen),
	  .arvalid(arvalid),
	  .arready(arready),
	  .rdata(rdata),
	  .rlast(rlast),
	  .rvalid(rvalid),
	  .rready(rready)
	);

	// Clock generation
	initial clk = 0;
	always #5 clk = ~clk; // 10ns clock period

	// Testbench logic
	initial begin
		// Initialize signals
		rst_n = 0;
		clk = 0;
		frame_ready = 0;
		base_addr_in = 32'h0000_0000;

		
		// Apply reset
		#20 rst_n = 1;
		#20;

		// Test Case 1: Start a new frame
		frame_ready = 1;
		#10 frame_ready = 0;


		#5000;
		$finish;
	end




endmodule