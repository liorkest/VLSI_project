/*------------------------------------------------------------------------------ 
Testbench for: wiener_calc module 
Author: eplkls 
Creation Date: Dec 12, 2024 
------------------------------------------------------------------------------*/ 
 
 
module wiener_1_channel_tb; 
 
  // Parameters 
	parameter DATA_WIDTH = 8;
	parameter TOTAL_SAMPLES = 8; // pixels in each block
	logic [7:0] data [0:63] = {203,222,235,123,69,73,202,162,203,88,29,70,87,205,147,109,61,15,122,84,153,107,55,92,124,191,198,54,204,23,172,117,31,92,85,37,241,185,148,164,69,180,12,188,58,192,133,28,106,247,80,244,10,56,227,11,78,205,177,165,18,225,19,245};
	int curr_data_idx;
	
  // Testbench signals 
	logic                   clk;
	logic                   rst_n;
	logic                   start_of_frame;
	logic                   end_of_frame;
	logic [DATA_WIDTH-1:0]  data_in;
	logic                   start_data;
	logic [31:0]            blocks_per_frame;
	logic [2*DATA_WIDTH-1:0] noise_variance = 16'd5;
	
	logic [DATA_WIDTH-1:0] data_out; 
	logic [31:0] data_count; 
 
  // DUT instantiation 
  wiener_1_channel #( 
	.DATA_WIDTH(DATA_WIDTH), 
	.TOTAL_SAMPLES(TOTAL_SAMPLES) 
  ) dut ( 
	.clk(clk), 
	.rst_n(rst_n), 
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.noise_variance(noise_variance), 
	.data_in(data_in), 
	.start_data(start_data),
	.blocks_per_frame(blocks_per_frame), 
	.data_out(data_out), 
	.data_count(data_count)
  ); 
 
  // Clock generation 
  initial clk = 0; 
  always #5 clk = ~clk; // 100 MHz clock 
 
 
  reg [31:0] count = 1;

  task send_block(int i);
	  //#20; 
	  if (i==0) begin
		  start_of_frame = 1;
	  end else if(i==blocks_per_frame - 1) begin
		  end_of_frame = 1;
	  end else begin
		  start_of_frame = 0;  
		  end_of_frame = 0; 
	  end
	  
	  if (i!=0) begin
		  //wait(mean_ready == 1);
		  #40;
	  end 
	  start_data = 1;
	  
	  // Feed data for the first block
	  repeat (TOTAL_SAMPLES) begin

		  #5; 
		  data_in = data[curr_data_idx];
		  curr_data_idx = curr_data_idx+1;
		  
		  count = count + 1;
		  #5; 
		  start_data = 0;  
		  start_of_frame = 0;  
		  end_of_frame = 0; 
	  end

  endtask

  // Test vectors and stimulus

  initial begin
	  // Initialize signals
	  rst_n = 0;
	  start_of_frame = 0;
	  end_of_frame = 0;
	  data_in = 0;
	  start_data = 0;
	  blocks_per_frame = 8; 
	  
	  curr_data_idx = 0;
	  // Reset sequence
	  #25 rst_n = 1;

	  // Send blocks
	  for(int i = 0; i < blocks_per_frame; i++) begin
		  send_block(i);            
	  end

	  // Finish simulation
	  #250;
	  $finish;
  end

endmodule