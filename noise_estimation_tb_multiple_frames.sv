/*------------------------------------------------------------------------------
 * File          : noise_estimation_tb_multiple_frames.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 7, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module noise_estimation_tb_multiple_frames;

// Parameters:
parameter DATA_WIDTH = 8;
parameter TOTAL_SAMPLES = 16; // pixels in each block
parameter TOTAL_PIXELS = 128; // total num of pixels in TB
logic [7:0] data [0:TOTAL_PIXELS-1] = {184,76,224,88,37,187,140,171,252,223,127,23,47,63,122,198,133,207,197,187,204,194,2,153,30,27,155,59,232,194,188,183,119,54,24,131,12,18,9,12,195,247,207,9,56,167,78,209,34,90,114,211,207,70,113,47,105,0,151,214,159,4,178,180,5,133,79,159,117,243,114,34,65,245,237,49,4,152,182,247,9,159,142,116,249,177,83,116,203,174,73,171,117,252,105,167,215,184,106,175,2,250,70,201,224,40,33,108,249,12,107,138,115,99,85,178,129,41,183,119,82,233,198,221,135,234,187,89};
logic [31:0]            blocks_per_frame = 4; 

logic [31:0]   frames_num = TOTAL_PIXELS / (blocks_per_frame*TOTAL_SAMPLES);
int curr_data_idx;
		
// Testbench signals
logic                   clk;
logic                   rst_n;
logic                   start_of_frame;
logic                   end_of_frame;
logic [DATA_WIDTH-1:0]  data_in;
logic                   start_data;

logic                   mean_ready;
logic [2*DATA_WIDTH-1:0] estimated_noise;
logic                   estimated_noise_ready;

// Clock generation
initial begin
	clk = 0;
	forever #5 clk = ~clk; // 100 MHz clock
end

// DUT instantiation
noise_estimation #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) dut (
	.clk(clk),
	.rst_n(rst_n),
	.start_of_frame(start_of_frame),
	.end_of_frame(end_of_frame),
	.data_in(data_in),
	.start_data(start_data),
	.blocks_per_frame(blocks_per_frame),
	.mean_ready(mean_ready),
	.estimated_noise(estimated_noise),
	.estimated_noise_ready(estimated_noise_ready)
);


reg [31:0] count = 1;

task send_block(int i);
	if (i==0) begin
		start_of_frame = 1;
	end else if(i==blocks_per_frame - 1) begin
		end_of_frame = 1;
	end else begin
		start_of_frame = 0;  
		end_of_frame = 0; 
	end
	
	if (i!=0) begin
		wait(mean_ready == 1);
		#30;
	end 
	@(negedge clk);
	start_data = 1;
	
	// Feed data of 1 block
	repeat (TOTAL_SAMPLES) begin
		@(negedge clk);
		data_in = data[curr_data_idx]; // added  [06.12.24]
		curr_data_idx = curr_data_idx+1;
		count = count + 1;
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

	
	curr_data_idx = 0;
	// Reset sequence
	#25 rst_n = 1;
	
	#20;
	
	for (int frame_num=0; frame_num < frames_num; frame_num++) begin
		@(posedge clk);
		// Send blocks
		for(int i = 0; i < blocks_per_frame; i++) begin
			send_block(i);            
		end
		wait(estimated_noise_ready);
	end

	// Finish simulation
	#250;
	$finish;
end

endmodule
