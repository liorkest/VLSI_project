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
// logic wiener_en;
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
logic start_data_wiener;
logic wiener_block_stats_en; // [10.01.25]
logic wiener_calc_en;        // [10.01.25]
logic [31:0] data_count ; //[LS 12.01.25]


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
	.rlast(rlast),
	.base_addr_in(base_addr_in),
	.wiener_calc_data_count(data_count),
	.start_read(start_read),
	.read_addr(read_addr),
	.read_len(read_len),
	.read_size(read_size),
	.read_burst(read_burst),
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
	.clk(clk),
	.wiener_block_stats_en(wiener_block_stats_en),
	.wiener_calc_en(wiener_calc_en),
	.rst_n(rst_n), 
	.start_of_frame(start_of_frame_wiener),
	.end_of_frame(end_of_frame),
	.noise_variance(estimated_noise), 
	.data_in(rdata), 
	.start_data(start_data_wiener),
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
	start_data_wiener = 0;
	// wiener_en = 0;
	wiener_block_stats_en = 0; // [10.01.25]
	wiener_calc_en = 1;
	base_addr_in = 32'h0000_0000;
	estimated_noise = 0;

	// Apply reset
	#20;
	rst_n = 1;
	#20;
	
	//Start a new frame
	estimated_noise_ready = 1;
	estimated_noise = 539;
	base_addr_in = 32'h0000_0000;
	#10;
	estimated_noise_ready = 0;
	
	#30;
	wiener_block_stats_en = 1; // [10.01.25]
	wiener_calc_en = 1;
	#5;
	// reading blocks
	for(int i=0; i < blocks_per_frame + 2; i++) begin 		
		// reading line by row
		for (int j = 0; j < BLOCK_SIZE; j++) begin
			if (j== 0) begin
				wiener_block_stats_en = 1; 
				wiener_calc_en = 1;
				if (i < blocks_per_frame) 
					start_data_wiener = 1;
				start_of_frame_wiener = (i==0);
				#10;
				start_of_frame_wiener = 0;
				start_data_wiener = 0;
			end 
			wiener_block_stats_en = 1; 
			
			if (j==0) #80;
			else begin
				#10;	
				wiener_calc_en= 1;
				#70;
			end
			
			if (j == BLOCK_SIZE - 1) begin
				// wiener_block_stats_en = 0;
				if(i==0) #30;
				else #30;
			end else begin
				wiener_block_stats_en = 0; 
				#10;
				wiener_calc_en = 0;
				#30;
			end


		end
	end
	// process data
	#5000;
	$finish;
end




endmodule