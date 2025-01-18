/*------------------------------------------------------------------------------
 * File          : from_memory_slave_to_wiener_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 9, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module from_memory_slave_to_wiener_tb_memory_channel2;

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

logic rvalid_2;
logic arready_2;
logic rlast_2;
logic [ADDR_WIDTH-1:0] base_addr_in_wiener;
logic [31:0] len_2;

logic start_read_2;
logic [ADDR_WIDTH-1:0] read_addr_2;
logic [31:0] read_len_2;
logic [2:0] read_size_2;
logic [1:0] read_burst_2;
logic [ADDR_WIDTH-1:0] base_addr_out_2;
// logic wiener_en;
logic start_of_frame_wiener;
logic frame_ready_for_wiener;


// Read Address Channel
logic [ADDR_WIDTH-1:0] araddr_2;
logic [7:0] arlen_2;
logic [2:0] arsize_2;
logic [1:0] arburst_2;
logic arvalid_2;

// Read Data Channel
logic [DATA_WIDTH-1:0] rdata_2;
logic [1:0] rresp_2;
logic rready_2;



// wiener
logic [2*BYTE_DATA_WIDTH-1:0] estimated_noise;
logic estimated_noise_ready;
logic start_data_wiener;
logic wiener_block_stats_en; // [10.01.25]
logic wiener_calc_en;        // [10.01.25]
logic [31:0] data_count ; //[LS 12.01.25]
logic [DATA_WIDTH-1:0] data_out_wiener;


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
	.arready(arready_2),
	.rlast(rlast_2),
	.base_addr_in(base_addr_in_wiener),
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
) AXI_memory_master_burst_dut (
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
	.rdata(rdata_2),
	.rresp(rresp_2),
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
AXI_memory_slave_3channels #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .MEM_SIZE(MEM_SIZE)
) AXI_memory_slave_uut (
  .clk(clk),
  .rst_n(rst_n),

  .araddr_2(araddr_2),
  .arlen_2(arlen_2),
  .arvalid_2(arvalid_2),
  .arready_2(arready_2),
  .rdata_2(rdata_2),
  .rlast_2(rlast_2),
  .rvalid_2(rvalid_2),
  .rready_2(rready_2)
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
	base_addr_in_wiener = 32'h0000_0000;
	estimated_noise = 0;

	// Apply reset
	#20;
	rst_n = 1;
	#20;
	
	//Start a new frame
	estimated_noise_ready = 1;
	estimated_noise = 539;
	base_addr_in_wiener = 32'h0000_0000;
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
				/*
				wiener_block_stats_en = 0; 
				wiener_calc_en = 0;
				#40;
				*/
				wiener_block_stats_en = 0; 
				#10;
				wiener_calc_en = 0;
				#30;
			end


		end
	end
	
	#5000;
	$finish;
end




endmodule