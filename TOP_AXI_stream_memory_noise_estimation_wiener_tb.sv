/*------------------------------------------------------------------------------
 * File          : TOP_AXI_stream_memory_noise_estimation_wiener_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 20, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module TOP_AXI_stream_memory_noise_estimation_wiener_tb #(
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
		
);

logic           clk;
logic           rst_n;
logic [15:0] 	frame_height=8*2;
logic [15:0]	frame_width=8*2;
logic  [31:0] 	blocks_per_frame = TOTAL_SAMPLES/(BLOCK_SIZE*BLOCK_SIZE);
logic [31:0]                pixels_per_frame=8*8*4;
logic  [DATA_WIDTH-1:0]     s_axis_tdata;
logic                       s_axis_tvalid;
logic                       s_axis_tlast;
logic                       s_axis_tready;
logic 						s_axis_tuser;
logic rlast;
logic noise_estimation_en;
logic start_data_noise_est;
logic start_of_frame_noise_estimation;
logic [2*BYTE_DATA_WIDTH-1:0] estimated_noise;
logic estimated_noise_ready;
logic start_of_frame_wiener;
logic frame_ready_for_noise_est;
logic start_data_wiener;
logic wiener_block_stats_en; 
logic wiener_calc_en;       
logic [31:0] data_count ; 
logic [DATA_WIDTH-1:0] data_out_wiener;
	// Clock generation
	
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end
	
	// 17.01.25 added the data of 4 blocks
	logic [7:0] data [0:255] = {46,18,253,180,124,96,88,49,208,206,155,1,179,123,138,250,216,127,228,182,254,188,95,142,26,80,2,31,75,25,112,107,247,119,91,68,236,6,240,149,225,183,131,124,66,250,80,62,0,23,239,96,218,77,79,47,37,175,123,49,143,147,10,39,130,77,75,73,99,27,186,150,129,2,251,3,67,216,64,156,85,11,146,136,190,216,114,108,18,236,166,44,93,144,108,13,15,182,216,161,7,40,168,93,121,217,227,115,180,239,158,178,140,166,205,71,207,108,151,84,52,110,206,210,52,99,166,193,38,46,0,86,143,0,247,120,224,252,191,48,192,130,86,238,229,115,50,73,163,152,176,42,236,194,4,118,41,254,30,199,165,165,180,98,126,42,242,23,169,244,101,58,149,25,122,174,199,52,7,152,12,123,254,78,66,89,47,213,150,92,64,206,62,83,81,41,192,42,230,141,99,33,46,19,140,202,184,93,17,78,74,17,188,6,66,246,238,155,85,52,88,149,191,10,158,30,7,32,76,177,176,50,224,115,12,246,175,226,144,144,111,130,4,55,201,207,189,66,95,25,181,111,80,186,234,113};

	int 						frames_num = 1;	


	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		// axi
		s_axis_tdata = 0;
		s_axis_tvalid = 1'b0;
		s_axis_tlast = 1'b0;
		s_axis_tuser = 1'b0;
		// noise estimation
		start_data_noise_est = 0;
		noise_estimation_en = 0;
		start_of_frame_noise_estimation = 0;
		base_addr_in = 32'h0000_0000;
		// wiener
		start_of_frame_wiener = 0;
		start_data_wiener = 0;
		// wiener_en = 0;
		wiener_block_stats_en = 0; // [10.01.25]
		wiener_calc_en = 1;		
		// Reset the system
		#20;
		rst_n = 1'b1;
		@(posedge clk);
	
		#10;
		// Send AXI stream
		for(int frame=0; frame < frames_num; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin 
				send_transaction({0,data[i],data[i],data[i]}, (i%frame_width == frame_width-1) ,i==0); // Data: 0x12345678, Last: 0 
			end
			// End transaction
			@(negedge clk);
			s_axis_tuser = 1'b0;
			s_axis_tvalid = 1'b0;
			s_axis_tdata = 1'b0; // [LK 01.01.25]
			@(posedge clk);
			#1;
			s_axis_tlast = 1'b0;
			//#9;
			//#30; 
		end
				
		// frame is ready in memory - begin noise estimation
		wait(frame_ready_for_noise_est)	;
		#10; // wait 1 cycle till frame_ready_for_noise_est = 0
		#30;
		noise_estimation_en = 1;
		#10;//#5;
		for(int i=0; i < blocks_per_frame; i++) begin
			start_data_noise_est = 1;
			start_of_frame_noise_estimation = (i==0);
			#10;
			start_of_frame_noise_estimation = 0;
			noise_estimation_en = 0;
			start_data_noise_est = 0;
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
		wait(estimated_noise_ready);
		
		#10;
		#5;
		// estimated_noise_ready = 0; [18.01.25] try to use the non-synthetic signal
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
		
		#100;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data, input last, input user);
	begin
		s_axis_tvalid = 1'b1;
		s_axis_tuser = user;
		@(negedge clk);
		s_axis_tdata = data;
		#1;
		s_axis_tlast = last;
		// #9;
		wait(s_axis_tready);


	end
	endtask
	


endmodule
