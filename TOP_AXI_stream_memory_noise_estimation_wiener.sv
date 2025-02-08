/*------------------------------------------------------------------------------
 * File          : TOP_AXI_stream_memory_noise_estimation_wiener.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module TOP_AXI_stream_memory_noise_estimation_wiener #(
// Parameters

parameter 		BYTE_DATA_WIDTH = 8,
parameter 		BLOCK_SIZE = 8,
parameter 		DATA_WIDTH = 32,
parameter 		ID_WIDTH = 4,
parameter		MEM_SIZE = 256,
parameter 		ADDR_WIDTH = 32,
parameter 		TOTAL_SAMPLES = 8*8*4, // total number of pixels in frame
parameter 		SAMPLES_PER_BLOCK = 64// total number of pixels in frame
) (	
	input logic clk,                          // Clock signal
	input logic rst_n,                        // Active-low reset
	input logic [15:0] frame_height,          // Frame height
	input logic [15:0] frame_width,           // Frame width
	input logic [31:0] blocks_per_frame,      // Number of blocks per frame
	input logic [31:0] pixels_per_frame,      // Number of pixels per frame
	input logic [DATA_WIDTH-1:0] s_axis_tdata, // Input data stream
	input logic s_axis_tvalid,                // Valid signal for input stream
	input logic s_axis_tlast,                 // Last signal for input stream
	output logic s_axis_tready,                // Ready signal for input stream
	input logic s_axis_tuser,                 // User signal for input stream
	output logic rlast,                        // Last signal for result stream
	input logic noise_estimation_en,          // Enable signal for noise estimation
	input logic start_data_noise_est,         // Start signal for data noise estimation
	input logic start_of_frame_noise_estimation, // Start of frame signal for noise estimation
	output logic [2*BYTE_DATA_WIDTH-1:0] estimated_noise, // Estimated noise data
	output logic estimated_noise_ready,        // Signal indicating noise estimation is ready
	input logic start_of_frame_wiener,        // Start of frame signal for Wiener filter
	output logic frame_ready_for_noise_est,    // Frame ready signal for noise estimation
	input logic start_data_wiener,            // Start signal for Wiener filter data
	input logic wiener_block_stats_en,        // Enable signal for Wiener block stats
	input logic wiener_calc_en,               // Enable signal for Wiener calculation
	output logic [31:0] data_count,            // Data count
	output logic [DATA_WIDTH-1:0] data_out_wiener // Output data after Wiener filter

);





logic rvalid;
logic arready;
logic [31:0] len;
logic start_read;
logic [ADDR_WIDTH-1:0] read_addr;
logic [31:0] read_len;
logic [2:0] read_size;
logic [1:0] read_burst;
logic [ADDR_WIDTH-1:0] base_addr_out_memory_writer;
logic [ADDR_WIDTH-1:0] base_addr_out_noise_est;
logic start_of_frame;
logic frame_ready_for_wiener;
logic start_write;

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
	

// Write Address Channel
logic [ID_WIDTH-1:0] awid;
logic [ADDR_WIDTH-1:0] awaddr;
logic [7:0] awlen;
logic [2:0] awsize;
logic [1:0] awburst;
logic awvalid;
logic awready;

// Write Data Channel
logic [DATA_WIDTH-1:0] wdata;
logic [DATA_WIDTH/8-1:0] wstrb;
logic wlast;
logic wvalid;
logic wready;

// Write Response Channel
logic [ID_WIDTH-1:0] bid;
logic [1:0] bresp;
logic bvalid;
logic bready;
	
	

// RGB mean
logic [7:0] rgb_mean_out;



	// Control signals
	logic [ID_WIDTH-1:0] write_id=0;
	logic [ADDR_WIDTH-1:0]   	write_addr;
	logic [31:0]             	write_len;
	logic [2:0]              	write_size;
	logic [1:0]              	write_burst;
	logic [DATA_WIDTH-1:0]  	write_data;
	logic [DATA_WIDTH/8-1:0]	write_strb;

// WIENER SIGNALS



	logic rvalid_2;
	logic arready_2;
	logic rlast_2;

	logic start_read_2;
	logic [ADDR_WIDTH-1:0] read_addr_2;
	logic [31:0] read_len_2;
	logic [2:0] read_size_2;
	logic [1:0] read_burst_2;


	// Read Address Channel
	logic [ADDR_WIDTH-1:0] araddr_2;
	logic [7:0] arlen_2;
	logic arvalid_2;

	// Read Data Channel
	logic [DATA_WIDTH-1:0] rdata_2;
	logic rready_2;


	memory_writer #(
		.DATA_WIDTH(DATA_WIDTH)
	) memory_writer_uut (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tlast(s_axis_tlast),
		.s_axis_tuser(s_axis_tuser),
		.pixels_per_frame(pixels_per_frame),
		.frame_height(frame_height),
		//.frame_width(frame_width),
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.frame_ready(frame_ready_for_noise_est),
		.base_addr_out(base_addr_out_memory_writer)
	);
	
	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) AXI_memory_master_burst_write (
		.clk(clk),
		.resetn(rst_n),
		
		// Write Address Channel
		.awid(awid),
		.awaddr(awaddr),
		.awlen(awlen),
		.awsize(awsize),
		.awburst(awburst),
		.awvalid(awvalid),
		.awready(awready),
		
		// Write Data Channel
		.wdata(wdata),
		.wstrb(wstrb),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		
		// Write Response Channel
		//.bid(bid),
		//.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		
		// Control signals
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.start_read(start_read)
	);
	
	AXI_memory_slave_3channels #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.MEM_SIZE(MEM_SIZE),
		.INIT_OPTION(0)
	  ) AXI_memory_slave_uut (
		.clk(clk),
		.rst_n(rst_n),
		.awaddr(awaddr),
		//.awlen(awlen),
		.awvalid(awvalid),
		.awready(awready),
		.wdata(wdata),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		.araddr(araddr),
		.arlen(arlen),
		.arvalid(arvalid),
		.arready(arready),
		.rdata(rdata),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		
		.araddr_2(araddr_2),
		.arlen_2(arlen_2),
		.arvalid_2(arvalid_2),
		.arready_2(arready_2),
		.rdata_2(rdata_2),
		.rlast_2(rlast_2),
		.rvalid_2(rvalid_2),
		.rready_2(rready_2)
	  );

	
	memory_reader_noise_estimation #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.BLOCK_SIZE(BLOCK_SIZE)
	) memory_reader_noise_estimation_dut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready_for_noise_est),
		.rvalid(rvalid),
		//.arready(arready),
		.rlast(rlast),
		.base_addr_in(base_addr_out_memory_writer),
		.estimated_noise_ready(estimated_noise_ready),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.base_addr_out(base_addr_out_noise_est),
		//.noise_estimation_en(noise_estimation_en),
		.start_of_frame(start_of_frame)
		//.frame_ready_for_wiener(frame_ready_for_wiener)
	);

	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_read_noise_estimation (
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
	
	// RGB mean
	RGB_mean #(.DATA_WIDTH(BYTE_DATA_WIDTH)) RGB_mean_dut ( 
		.en(1), 
		.data_in(rdata), 
		.data_out(rgb_mean_out) 
	 ); 
	
	// DUT instantiation
	noise_estimation #(
		.DATA_WIDTH(BYTE_DATA_WIDTH),
		.TOTAL_SAMPLES(BLOCK_SIZE*BLOCK_SIZE) // Total number of pixels per frame (MUST be power of 2)
	) noise_estimation_dut (
		.clk(clk & noise_estimation_en), 
		.rst_n(rst_n),
		.start_of_frame(start_of_frame_noise_estimation), //08.01.25
		.data_in(rgb_mean_out),
		.start_data(start_data_noise_est),  
		.blocks_per_frame(blocks_per_frame),
		.estimated_noise(estimated_noise),
		.estimated_noise_ready(estimated_noise_ready)
	);


/////////// WIENER BEGIN




	memory_reader_wiener #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.BLOCK_SIZE(BLOCK_SIZE)
	) memory_reader_wiener_dut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.rvalid(rvalid_2),
		//.arready(arready_2),
		.rlast(rlast_2),
		.base_addr_in(base_addr_out_noise_est),
		.wiener_calc_data_count(data_count),
		.start_read(start_read_2),
		.read_addr(read_addr_2),
		.read_len(read_len_2),
		.read_size(read_size_2),
		.read_burst(read_burst_2),
		//.wiener_block_stats_en(wiener_block_stats_en),
		//.wiener_calc_en(wiener_calc_en),
		//.start_of_frame(start_of_frame),
		//.start_data_wiener(start_data_wiener),
		.estimated_noise_ready(estimated_noise_ready),
		.end_of_frame(end_of_frame_wiener)
	);

	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_wiener (
		.clk(clk),
		.resetn(rst_n),
		
		// Read Address Channel
		//.arid(arid),
		.araddr(araddr_2),
		.arlen(arlen_2),
		.arsize(arsize_2),
		.arburst(arburst_2),
		.arvalid(arvalid_2),
		.arready(arready_2),
		
		// Read Data Channel
		//.rid(rid),
		//.rdata(rdata_2),
		//.rresp(rresp_2),
		.rlast(rlast_2),
		.rvalid(rvalid_2),
		.rready(rready_2),

		.start_read(start_read_2),
		.read_addr(read_addr_2),
		.read_len(read_len_2),
		.read_size(read_size_2),
		.read_burst(read_burst_2)
		
	);


	wiener_3_channels #( 
		.DATA_WIDTH(DATA_WIDTH), 
		.TOTAL_SAMPLES(SAMPLES_PER_BLOCK) 
	  ) wiener_3_channels_dut ( 
		.clk(clk),
		.wiener_block_stats_en(wiener_block_stats_en),
		.wiener_calc_en(wiener_calc_en),
		.rst_n(rst_n), 
		.start_of_frame(start_of_frame_wiener),
		.end_of_frame(end_of_frame_wiener),
		.noise_variance(estimated_noise), 
		.data_in(rdata_2), 
		.start_data(start_data_wiener),
		.blocks_per_frame(blocks_per_frame), 
		.data_out(data_out_wiener), 
		.data_count(data_count)
	  ); 




endmodule
