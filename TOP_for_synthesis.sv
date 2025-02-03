/*------------------------------------------------------------------------------
 * File          : TOP_for_synthesis.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 31, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module TOP_for_synthesis #(
// Parameters
// all parameters are constant for any simulation
parameter 		BYTE_DATA_WIDTH = 8,
parameter 		BLOCK_SIZE = 8,
parameter 		DATA_WIDTH = 32,
parameter 		ID_WIDTH = 4,
parameter 		ADDR_WIDTH = 32,
parameter 		TOTAL_SAMPLES = 1280*720, // [LK 30.01.25] this is the max value - it is a constant parameter no matter what is the resolution!
parameter 		SAMPLES_PER_BLOCK = BLOCK_SIZE*BLOCK_SIZE
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
	output noise_estimation_mean_ready,
	output logic [2*BYTE_DATA_WIDTH-1:0] estimated_noise, // Estimated noise data
	output logic estimated_noise_ready,        // Signal indicating noise estimation is ready
	output logic [31:0] data_count,            // Data count
	output logic [DATA_WIDTH-1:0] data_out_wiener, // Output data after Wiener filter
	
	// first output memory buffer for input frames:
	
	// Write address channel
	output logic [ADDR_WIDTH-1:0]    awaddr,
	output logic [31:0]               awlen,
	output logic [2:0]				awsize,
	output logic                     awvalid,
	output logic [1:0] awburst,
	input                             awready,

	// Write data channel
	output logic [DATA_WIDTH-1:0]    wdata,
	output logic                     wvalid,
	input                             wready,
	output logic                     wlast,

	// Write response channel
	input                             bvalid,
	output logic                     bready,

	// #1 Read address channel
	output logic [ADDR_WIDTH-1:0]    araddr,
	output logic [31:0]               arlen,
	output logic  [2:0]            arsize,
	output logic   [1:0]                arburst,
	output logic                     arvalid,
	input                             arready,

	// #1 Read data channel
	input  [DATA_WIDTH-1:0]          rdata,
	input                             rvalid,
	output logic                     rready,
	input                             rlast,
	
	// #2 Read address channel
	output logic [ADDR_WIDTH-1:0]    araddr_2,
	output logic  [2:0]            arsize_2,
	output logic  [1:0]                 arburst_2,
	output logic [31:0]               arlen_2,
	output logic                     arvalid_2,
	input                             arready_2,

	// #2 Read data channel
	input  [DATA_WIDTH-1:0]          rdata_2,
	input                             rvalid_2,
	output logic                     rready_2,
	input                             rlast_2,
	
	/////// second frames buffer - output frames:
	// AXI memory master signals

	// Write Address Channel
	output logic [ID_WIDTH-1:0]   mem2_awid,
	output logic [ADDR_WIDTH-1:0] mem2_awaddr,
	output logic [7:0]            mem2_awlen,
	output logic [2:0]            mem2_awsize,
	output logic [1:0]            mem2_awburst,
	output logic                  mem2_awvalid,
	input  logic                  mem2_awready,

	// Write Data Channel
	output logic [DATA_WIDTH-1:0]  mem2_wdata,
	output logic [DATA_WIDTH/8-1:0] mem2_wstrb,
	output logic                   mem2_wlast,
	output logic                   mem2_wvalid,
	input  logic                   mem2_wready,

	// Write Response Channel
	input  logic                   mem2_bvalid,
	output logic                   mem2_bready,

	// Read Address Channel
	output logic [ADDR_WIDTH-1:0] mem2_araddr,
	output logic [7:0]            mem2_arlen,
	output logic [2:0]            mem2_arsize,
	output logic [1:0]            mem2_arburst,
	output logic                  mem2_arvalid,
	input  logic                  mem2_arready,

	// Read Data Channel
	input  logic [DATA_WIDTH-1:0] mem2_rdata,
	input  logic                  mem2_rlast,
	input  logic                  mem2_rvalid,
	output logic                  mem2_rready,

	
	// AXI stream output
	output [DATA_WIDTH-1:0] m_axis_tdata,
	output m_axis_tvalid,
	input m_axis_tready,
	output m_axis_tlast,
	output m_axis_tuser
);


wire wiener_block_stats_en;
wire wiener_calc_en;
wire start_of_frame_wiener;
wire start_data_wiener;
//wire frame_ready_for_wiener;


	logic start_read;
	logic [ADDR_WIDTH-1:0] read_addr;
	logic [31:0] read_len;
	logic [2:0] read_size;
	logic [1:0] read_burst;
	logic [ADDR_WIDTH-1:0] base_addr_out_memory_writer;
	logic [ADDR_WIDTH-1:0] base_addr_out_noise_est;
	logic start_of_frame;
	logic start_write;
	

	// RGB mean
	logic [7:0] rgb_mean_out;
	
	// noise est
	logic noise_estimation_en;
	wire start_data_noise_est;


	// Control signals
	logic [ADDR_WIDTH-1:0]   	write_addr;
	logic [31:0]             	write_len;
	logic [2:0]              	write_size;
	logic [1:0]              	write_burst;
	logic [DATA_WIDTH-1:0]  	write_data;
	logic [DATA_WIDTH/8-1:0]	write_strb;

// WIENER SIGNALS

	//wire frame_ready_for_wiener;

	logic start_read_2;
	logic [ADDR_WIDTH-1:0] read_addr_2;
	logic [31:0] read_len_2;
	logic [2:0] read_size_2;
	logic [1:0] read_burst_2;
	logic end_of_frame_wiener;

	logic frame_ready_for_noise_est;

// from wiener to AXI output
	logic                    	start_write_wiener;
	assign start_write_wiener = data_count % BLOCK_SIZE == 0;
	logic [DATA_WIDTH-1:0]      mem2_data_in;
	assign mem2_data_in = data_out_wiener;
	
	logic                    	mem2_start_write;
	logic [ADDR_WIDTH-1:0]   	mem2_write_addr;
	logic [31:0]             	mem2_write_len;
	logic [2:0]              	mem2_write_size;
	logic [1:0]              	mem2_write_burst;
	logic [DATA_WIDTH-1:0]  	mem2_write_data;
	logic [DATA_WIDTH/8-1:0]	mem2_write_strb;
			
	logic frame_ready;
	logic [ADDR_WIDTH-1:0] base_addr;
	
	 
	// Control signals
	logic mem2_start_read;
	logic [ADDR_WIDTH-1:0] mem2_read_addr;
	logic [31:0] mem2_read_len;
	logic [2:0] mem2_read_size;
	logic [1:0] mem2_read_burst;
	
	// Memory Reader AXI Stream Master Interface


	logic [DATA_WIDTH-1:0] reader_data_in;
	logic valid_in;
	logic last_in;
	logic user_in;

memory_writer #(.DATA_WIDTH(DATA_WIDTH)
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
	
AXI_memory_master_burst_write_only #(.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) AXI_memory_master_burst_write_only (
		.clk(clk),
		.resetn(rst_n),
		
		// Write Address Channel
		.awaddr(awaddr),
		.awlen(awlen),
		.awsize(awsize),
		.awburst(awburst),
		.awvalid(awvalid),
		.awready(awready),
		
		// Write Data Channel
		.wdata(wdata),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		
		// Write Response Channel
		.bvalid(bvalid),
		.bready(bready),
		
		// Control signals
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data)
	);

memory_reader_noise_estimation #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .BLOCK_SIZE(BLOCK_SIZE)
	) memory_reader_noise_estimation_dut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready_for_noise_est),
		.rvalid(rvalid),
		.rlast(rlast),
		.base_addr_in(base_addr_out_memory_writer),
		.estimated_noise_ready(estimated_noise_ready),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.base_addr_out(base_addr_out_noise_est),
		.start_of_frame(start_of_frame),
		.noise_estimation_en(noise_estimation_en),
		.start_data(start_data_noise_est)
		//.frame_ready_for_wiener(frame_ready_for_wiener)
	);

	AXI_memory_master_burst_read_only #(
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
		.en(1'b1), 
		.data_in(rdata[23:0]), 
		.data_out(rgb_mean_out) 
	 ); 
	
	// DUT instantiation
	noise_estimation #(
		.DATA_WIDTH(BYTE_DATA_WIDTH),
		.TOTAL_SAMPLES(SAMPLES_PER_BLOCK) // Total number of pixels per frame (MUST be power of 2)
	) noise_estimation_dut (
		.clk(clk & noise_estimation_en), 
		.rst_n(rst_n),
		.start_of_frame(start_of_frame), //08.01.25
		.data_in(rgb_mean_out),
		.start_data(start_data_noise_est),  
		.blocks_per_frame(blocks_per_frame),
		.estimated_noise(estimated_noise),
		.estimated_noise_ready(estimated_noise_ready),
		.mean_ready(noise_estimation_mean_ready)
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
		.rlast(rlast_2),
		.base_addr_in(base_addr_out_noise_est),
		.wiener_calc_data_count(data_count),
		.start_read(start_read_2),
		.read_addr(read_addr_2),
		.read_len(read_len_2),
		.read_size(read_size_2),
		.read_burst(read_burst_2),

		.wiener_block_stats_en(wiener_block_stats_en),
		.wiener_calc_en(wiener_calc_en),
		.start_of_frame(start_of_frame_wiener),
		.start_data(start_data_wiener),
		//.frame_ready_for_output_reader(),
		//.start_write(),
		.estimated_noise_ready(estimated_noise_ready),
		.end_of_frame(end_of_frame_wiener),
		.start_write()
	);

AXI_memory_master_burst_read_only #(.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_read_only_wiener (
		.clk(clk),
		.resetn(rst_n),
		
		// Read Address Channel
		.araddr(araddr_2),
		.arlen(arlen_2),
		.arsize(arsize_2),
		.arburst(arburst_2),
		.arvalid(arvalid_2),
		.arready(arready_2),
		
		// Read Data Channel
		.rlast(rlast_2),
		.rvalid(rvalid_2),
		.rready(rready_2),

		.start_read(start_read_2),
		.read_addr(read_addr_2),
		.read_len(read_len_2),
		.read_size(read_size_2),
		.read_burst(read_burst_2)
		
	);
	



wiener_3_channels #(.DATA_WIDTH(DATA_WIDTH), 
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

	/////////// WIENER END
	
	/////////// from memory to AXI stream


	memory_writer_output #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH),
		.BLOCK_SIZE(BLOCK_SIZE)
	) memory_writer_output_uut (
		.clk(clk),
		.rst_n(rst_n),
		.pixels_per_frame(pixels_per_frame),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.start_write_in(start_write_wiener), // should be output of wiener memory reader
		.data_in(mem2_data_in),
		.wvalid(mem2_wvalid),
		.wlast(mem2_wlast),
		.start_write_out(mem2_start_write),
		.write_addr(mem2_write_addr),
		.write_len(mem2_write_len),
		.write_size(mem2_write_size),
		.write_burst(mem2_write_burst),
		.write_data(mem2_write_data),
		.write_strb(mem2_write_strb),
		.frame_ready(frame_ready),
		.base_addr_out(base_addr)
	);
	
	memory_reader_output #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	) memory_reader_output_uut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready),
		.base_addr(base_addr),
		.start_read(mem2_start_read),
		.read_addr(mem2_read_addr),
		.read_len(mem2_read_len),
		.read_size(mem2_read_size),
		.read_burst(mem2_read_burst),
		.arready(mem2_arready),
		.rdata(mem2_rdata),
		.rvalid(mem2_rvalid),
		//.rlast(mem2_rlast),
		.m_axis_tdata(reader_data_in),
		.m_axis_tvalid(valid_in),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(last_in),
		.m_axis_tuser(user_in)
	);

	// AXI Stream Master
	AXI_stream_master #(
		.DATA_WIDTH(DATA_WIDTH)
	) axi_stream_master (
		.clk(clk),
		.rst_n(rst_n),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tuser(m_axis_tuser),
		.data_in(reader_data_in),
		.valid_in(valid_in),
		.last_in(last_in),
		.user_in(user_in) 
	);

	
	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) AXI_memory_master_burst_uut (
		.clk(clk),
		.resetn(rst_n),
		
		// Write Address Channel
		.awid(mem2_awid),
		.awaddr(mem2_awaddr),
		.awlen(mem2_awlen),
		.awsize(mem2_awsize),
		.awburst(mem2_awburst),
		.awvalid(mem2_awvalid),
		.awready(mem2_awready),
		
		// Write Data Channel
		.wdata(mem2_wdata),
		.wstrb(mem2_wstrb),
		.wlast(mem2_wlast),
		.wvalid(mem2_wvalid),
		.wready(mem2_wready),
		
		// Write Response Channel
		.bvalid(mem2_bvalid),
		.bready(mem2_bready),
		
		// Read Address Channel
		.araddr(mem2_araddr),
		.arlen(mem2_arlen),
		.arsize(mem2_arsize),
		.arburst(mem2_arburst),
		.arvalid(mem2_arvalid),
		.arready(mem2_arready),
		
		// Read Data Channel
		.rlast(mem2_rlast),
		.rvalid(mem2_rvalid),
		.rready(mem2_rready),
		
		// Control signals
		.start_write(mem2_start_write),
		.write_addr(mem2_write_addr),
		.write_len(mem2_write_len),
		.write_size(mem2_write_size),
		.write_burst(mem2_write_burst),
		.write_data(mem2_write_data),
		.write_strb(mem2_write_strb),
		.start_read(mem2_start_read),
		.read_addr(mem2_read_addr),
		.read_len(mem2_read_len),
		.read_size(mem2_read_size),
		.read_burst(mem2_read_burst)
		
	);
	
	
endmodule
