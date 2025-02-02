/*------------------------------------------------------------------------------
 * File          : memory_reader_noise_estimation_with_axi_mem_slave&mastertb.sv.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 6, 2025
 * Description   :
 *------------------------------------------------------------------------------*/
module from_memory_slave_to_noise_estimation_tb;

	// Parameters
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter BYTE_DATA_WIDTH = 8;
	parameter BLOCK_SIZE = 8;
	parameter MEM_SIZE = 256;
	logic [15:0] frame_height=16;
	logic [15:0] frame_width=16;
	parameter TOTAL_SAMPLES = 16*16; // total number of pixels in frame
	logic [31:0] blocks_per_frame = TOTAL_SAMPLES/(BLOCK_SIZE*BLOCK_SIZE);
	
	// Testbench Signals
	logic clk;
	logic rst_n;
	
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


	// RGB mean
	logic [7:0] rgb_mean_out;
	
	// noise estimation
	logic [2*DATA_WIDTH-1:0] estimated_noise;
	logic estimated_noise_ready;
	logic start_data;
	logic start_of_frame_noise_estimation;
	
	
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
		//.arready(arready),
		.rlast(rlast),
		.estimated_noise_ready(estimated_noise_ready),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.base_addr_out(base_addr_out),
		//.noise_estimation_en(noise_estimation_en),
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
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		
		// Read Data Channel
		//.rid(rid),
		//.rdata(rdata),
		//.rresp(rresp),
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
	
	// RGB mean
	RGB_mean #(.DATA_WIDTH(BYTE_DATA_WIDTH)) dut ( 
		.en(1), 
		.data_in(rdata), 
		.data_out(rgb_mean_out) 
	 ); 
	
	// DUT instantiation
	noise_estimation #(
		.DATA_WIDTH(BYTE_DATA_WIDTH),
		.TOTAL_SAMPLES(BLOCK_SIZE*BLOCK_SIZE) // Total number of pixels per frame (MUST be power of 2)
	) noise_estimation_dut (
		.clk(clk & noise_estimation_en), /// TBD check if OK
		.rst_n(rst_n),
		.start_of_frame(start_of_frame_noise_estimation), //08.01.25
		//.end_of_frame(end_of_frame), ??????
		.data_in(rgb_mean_out),
		.start_data(start_data),  /// [06.1.25] check this!!!! NOT sure!!  TBD!!!!!
		.blocks_per_frame(blocks_per_frame),
		.estimated_noise(estimated_noise),
		.estimated_noise_ready(estimated_noise_ready)
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
		start_data = 0;
		noise_estimation_en = 0;
		start_of_frame_noise_estimation = 0;
		base_addr_in = 32'h0000_0000;

		
		// Apply reset
		#20 rst_n = 1;
		#20;
		// Start a new frame
		frame_ready = 1;
		base_addr_in = 32'h0000_0000;
		#10;
		frame_ready = 0;
		
		#30;
		noise_estimation_en = 1;
		#5;
		for(int i=0; i < blocks_per_frame; i++) begin
			start_data = 1;
			start_of_frame_noise_estimation = (i==0);
			#10;
			start_of_frame_noise_estimation = 0;
			noise_estimation_en = 0;
			start_data = 0;
			for (int j = 0; j < BLOCK_SIZE; j++) begin
				noise_estimation_en = 1;
				
				// #85;  // option 1
				wait(rlast); // option 2
				#15;
				if(j==BLOCK_SIZE-1) #10; // for mean calculation - last cycle
					
				
				if(j!=BLOCK_SIZE-1) begin
					noise_estimation_en = 0;
					#45;
				end else if (j==BLOCK_SIZE-1) begin
					#25;
					//noise_estimation_en = 0;
				end
			end
		end
		
		#5000;
		$finish;
	end




endmodule