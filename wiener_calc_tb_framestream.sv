/*------------------------------------------------------------------------------ 
Testbench for: wiener_calc module 
Author: eplkls 
Creation Date: Dec 12, 2024 
------------------------------------------------------------------------------*/ 
 
 
module wiener_calc_tb_framestream; 
 
  // Parameters 
  parameter DATA_WIDTH = 8; 
  parameter TOTAL_SAMPLES = 64; 
 
  // Testbench signals 
  logic clk; 
  logic rst_n; 
  logic stats_ready; 
  logic [2*DATA_WIDTH-1:0] mean_of_block; 
  logic [2*DATA_WIDTH-1:0] variance_of_block; 
  logic [2*DATA_WIDTH-1:0] noise_variance; 
  logic [DATA_WIDTH-1:0] data_in; 
  logic [31:0] blocks_per_frame; 
 
  logic [DATA_WIDTH-1:0] data_out; 
  logic [31:0] data_count; 
 
  // DUT instantiation 
  wiener_calc #( 
	.DATA_WIDTH(DATA_WIDTH), 
	.TOTAL_SAMPLES(TOTAL_SAMPLES) 
  ) dut ( 
	.clk(clk), 
	.rst_n(rst_n), 
	.stats_ready(stats_ready), 
	.mean_of_block(mean_of_block), 
	.variance_of_block(variance_of_block), 
	.noise_variance(noise_variance), 
	.data_in(data_in), 
	//.blocks_per_frame(blocks_per_frame), 
	.data_out(data_out), 
	.data_count_out(data_count) 
  ); 
 
  // Clock generation 
  initial clk = 0; 
  always #5 clk = ~clk; // 100 MHz clock 
 
  // Reset task 
  task reset_dut; 
	begin 
	  rst_n = 0; 
	  stats_ready = 0; 
	  mean_of_block = 16'h0000; 
	  variance_of_block = 16'h0000; 
	  noise_variance = 16'h0000; 
	  data_in = 0; 
	  blocks_per_frame = 0; 
	  #20; 
	  rst_n = 1; 
	end 
  endtask 
 
  // Test vectors 
  initial begin 
	// Initialization 
	reset_dut(); 

	
	// Test case 1: Simple computation 
	@(posedge clk)
	stats_ready = 1; 
	mean_of_block = 16'h0080; // Example mean value 
	variance_of_block = 16'h0040; // Example variance value 
	noise_variance = 16'h0020; // Example noise variance value 
	data_in = 8'hC0; // Example pixel value 
	blocks_per_frame = 1; 
 
	@(posedge clk); 
	stats_ready = 0; 
 
	// Simulate TOTAL_SAMPLES cycles of data processing 
	repeat (TOTAL_SAMPLES) begin 
	  @(posedge clk); 
	  data_in = data_in + 1; // Increment pixel value for testing 
	end 
 
	// Check final outputs 
	@(posedge clk); 
	$display("Final data_out: %h", data_out); 
	$display("Final data_count: %d", data_count); 
 
	// End simulation 
	#50; 
	$stop; 
  end 
 
endmodule 