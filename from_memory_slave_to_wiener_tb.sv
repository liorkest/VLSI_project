/*------------------------------------------------------------------------------
 * File          : from_memory_slave_to_wiener_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module from_memory_slave_to_wiener_tb;

// Parameters
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter BYTE_DATA_WIDTH = 8;
parameter BLOCK_SIZE = 8;
parameter MEM_SIZE = 256;
logic [15:0] frame_height=16;
logic [15:0] frame_width=16;
parameter SAMPLES_PER_BLOCK = 64; // total number of pixels in frame
logic [31:0] blocks_per_frame = MEM_SIZE/(BLOCK_SIZE*BLOCK_SIZE);

// Testbench Signals
logic clk;
logic rst_n;

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
logic wiener_en;
logic start_of_frame_wiener;
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

// wiener
logic [2*BYTE_DATA_WIDTH-1:0] estimated_noise;
logic estimated_noise_ready;
logic start_data;


memory_reader_wiener #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH),
	.BLOCK_SIZE(BLOCK_SIZE)
) memory_reader_wiener_dut (
	.clk(clk),
	.rst_n(rst_n),
	.frame_height(frame_height),
	.frame_width(frame_width),
	.rvalid(rvalid),
	.arready(arready),
	.rlast(rlast),
	.base_addr_in(base_addr_in),
	.start_read(start_read),
	.read_addr(read_addr),
	.read_len(read_len),
	.read_size(read_size),
	.read_burst(read_burst),
	//.wiener_en(wiener_en),
	.start_of_frame(start_of_frame),
	.estimated_noise_ready(estimated_noise_ready),
	.end_of_frame(end_of_frame)
);

AXI_memory_master_burst #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH)
) AXI_memory_master_burst_dut (
	.clk(clk),
	.resetn(rst_n),
	
	// Read Address Channel
	//.arid(arid),
	.araddr(araddr),
	.arlen(arlen),
	.arsize(arsize),
	.arburst(arburst),
	.arvalid(arvalid),
	.arready(arready),
	
	// Read Data Channel
	//.rid(rid),
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


wiener_3_channels #( 
	.DATA_WIDTH(DATA_WIDTH), 
	.TOTAL_SAMPLES(SAMPLES_PER_BLOCK) 
  ) wiener_3_channels_dut ( 
	.clk(clk && wiener_en), 
	.rst_n(rst_n), 
	.start_of_frame(start_of_frame_wiener),
	.end_of_frame(end_of_frame),
	.noise_variance(estimated_noise), 
	.data_in(rdata), 
	.start_data(start_data),
	.blocks_per_frame(blocks_per_frame), 
	.data_out(data_out), 
	.data_count(data_count)
  ); 

// Clock generation
initial clk = 0;
always #5 clk = ~clk; // 10ns clock period

// Testbench logic
initial begin
	// Initialize signals
	rst_n = 0;
	clk = 0;
	estimated_noise_ready = 0;
	start_of_frame_wiener = 0;
	start_data = 0;
	wiener_en = 0;
	// start_of_frame_noise_estimation = 0;
	base_addr_in = 32'h0000_0000;
	estimated_noise = 0;

	
	// Apply reset
	#20 rst_n = 1;
	#20;
	// Test Case 1: Start a new frame
	estimated_noise_ready = 1;
	estimated_noise = 5386;
	base_addr_in = 32'h0000_0000;
	#10;
	estimated_noise_ready = 0;
	
	#30;
	wiener_en = 1;
	#5;
	for(int i=0; i < blocks_per_frame; i++) begin
		start_data = 1;
		start_of_frame_wiener = (i==0);
		#10;
		start_of_frame_wiener = 0;
		wiener_en = 0;
		start_data = 0;
		for (int j = 0; j < BLOCK_SIZE; j++) begin
			wiener_en = 1;
			
			// #85;  // option 1
			wait(rlast); // option 2
			#15;
			if(j==BLOCK_SIZE-1) #10; // for mean calculation - last cycle
				
			
			if(j!=BLOCK_SIZE-1) begin
				wiener_en = 0;
				#45;
			end else if (j==BLOCK_SIZE-1) begin
				#25;
			end
		end
	end
	
	#5000;
	$finish;
end




endmodule