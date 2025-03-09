//------------------------------------------------------------------------------
// Testbench for noise_estimation module
//------------------------------------------------------------------------------

module noise_estimation_tb_more_data;

	// Parameters [06.12.24]:
	parameter DATA_WIDTH = 8;
	parameter BLOCKS_NUM = 4;
	parameter DATA_LEN  = BLOCKS_NUM * 8 * 8; // pixels in each block
	parameter TOTAL_SAMPLES = 8 * 8; // pixels in each block
	logic [7:0] data [0:DATA_LEN-1] = {
			46,18,253,180,124,96,88,49,216,127,228,182,254,188,95,142,247,119,91,68,236,6,240,149,0,23,239,96,218,77,79,47,130,77,75,73,99,27,186,150,85,11,146,136,190,216,114,108,15,182,216,161,7,40,168,93,140,166,205,71,207,108,151,84,208,206,155,1,179,123,138,250,26,80,2,31,75,25,112,107,225,183,131,124,66,250,80,62,37,175,123,49,143,147,10,39,129,2,251,3,67,216,64,156,18,236,166,44,93,144,108,13,121,217,227,115,180,239,158,178,52,110,206,210,52,99,166,193,38,46,0,86,143,0,247,120,229,115,50,73,163,152,176,42,165,165,180,98,126,42,242,23,199,52,7,152,12,123,254,78,62,83,81,41,192,42,230,141,17,78,74,17,188,6,66,246,158,30,7,32,76,177,176,50,111,130,4,55,201,207,189,66,224,252,191,48,192,130,86,238,236,194,4,118,41,254,30,199,169,244,101,58,149,25,122,174,66,89,47,213,150,92,64,206,99,33,46,19,140,202,184,93,238,155,85,52,88,149,191,10,224,115,12,246,175,226,144,144,95,25,181,111,80,186,234,113			};
	
	
	int curr_data_idx;
			
	// Testbench signals
	logic                   clk;
	logic                   rst_n;
	logic                   start_of_frame;
	logic                   end_of_frame;
	logic [DATA_WIDTH-1:0]  data_in;
	logic                   start_data;
	logic [31:0]            blocks_per_frame;
	
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
		//.end_of_frame(end_of_frame),
		.data_in(data_in),
		.start_data(start_data),
		.blocks_per_frame(blocks_per_frame),
		.mean_ready(mean_ready),
		.estimated_noise(estimated_noise),
		.estimated_noise_ready(estimated_noise_ready)
	);


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
			wait(mean_ready == 1);
			#30;
		end 
		start_data = 1;
		
		// Feed data for the first block
		repeat (TOTAL_SAMPLES) begin

			#5; 
			data_in = data[curr_data_idx]; // added  [06.12.24]
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
		blocks_per_frame = BLOCKS_NUM; 
		
		curr_data_idx = 0; // [06.12.24]
		// Reset sequence
		#25 rst_n = 1;

		// Send blocks
		for(int i = 0; i < blocks_per_frame; i++) begin
			send_block(i);            
		end

		// Finish simulation
		#(DATA_LEN*3.5);
		$finish;
	end

endmodule