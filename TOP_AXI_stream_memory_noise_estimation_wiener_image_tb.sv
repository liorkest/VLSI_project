/*------------------------------------------------------------------------------
 * File          : TOP_AXI_stream_memory_noise_estimation_wiener_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 20, 2025
 * Description   : opend hex file and reads 4 blocks
 *------------------------------------------------------------------------------*/



module TOP_AXI_stream_memory_noise_estimation_wiener_image_tb #(
// Parameters of TB
parameter 		BYTE_DATA_WIDTH = 8,
parameter 		BLOCK_SIZE = 8,
parameter 		DATA_WIDTH = 32,
parameter 		ID_WIDTH = 4,
parameter		MEM_SIZE = 256,
parameter 		ADDR_WIDTH = 32,
parameter 		TOTAL_SAMPLES = 8*8*4, // total number of pixels in frame
parameter 		SAMPLES_PER_BLOCK = 64// total number of pixels in frame
) ();

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

TOP_AXI_stream_memory_noise_estimation_wiener #(
	.BYTE_DATA_WIDTH(BYTE_DATA_WIDTH),
	.BLOCK_SIZE(BLOCK_SIZE),
	.DATA_WIDTH(DATA_WIDTH),
	.ID_WIDTH(ID_WIDTH),
	.MEM_SIZE(MEM_SIZE),
	.ADDR_WIDTH(ADDR_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES),
	.SAMPLES_PER_BLOCK(SAMPLES_PER_BLOCK)
) TOP_AXI_stream_memory_noise_estimation_wiener_inst (
	.clk(clk),                                    // Clock signal
	.rst_n(rst_n),                                // Active-low reset
	.frame_height(frame_height),                  // Frame height
	.frame_width(frame_width),                    // Frame width
	.blocks_per_frame(blocks_per_frame),          // Number of blocks per frame
	.pixels_per_frame(pixels_per_frame),          // Number of pixels per frame
	.s_axis_tdata(s_axis_tdata),                  // Input data stream
	.s_axis_tvalid(s_axis_tvalid),                // Valid signal for input stream
	.s_axis_tlast(s_axis_tlast),                  // Last signal for input stream
	.s_axis_tready(s_axis_tready),                // Ready signal for input stream
	.s_axis_tuser(s_axis_tuser),                  // User signal for input stream
	.rlast(rlast),                                // Last signal for result stream
	.noise_estimation_en(noise_estimation_en),    // Enable signal for noise estimation
	.start_data_noise_est(start_data_noise_est),  // Start signal for data noise estimation
	.start_of_frame_noise_estimation(start_of_frame_noise_estimation), // Start of frame signal
	.estimated_noise(estimated_noise),            // Estimated noise data
	.estimated_noise_ready(estimated_noise_ready), // Signal indicating noise estimation is ready
	.start_of_frame_wiener(start_of_frame_wiener), // Start of frame signal for Wiener filter
	.frame_ready_for_noise_est(frame_ready_for_noise_est), // Frame ready signal for noise estimation
	.start_data_wiener(start_data_wiener),        // Start signal for Wiener filter data
	.wiener_block_stats_en(wiener_block_stats_en), // Enable signal for Wiener block stats
	.wiener_calc_en(wiener_calc_en),               // Enable signal for Wiener calculation
	.data_count(data_count),                       // Data count
	.data_out_wiener(data_out_wiener)              // Output data after Wiener filter
);


	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end
	
	int frames_num = 1;	

/***********
 * This module writes the Wiener output into hex file
 */
	integer out_file;
	always @(data_count) begin
		// Write the 32-bit data_out to the file whenever trigger_signal changes
		if(data_count<=64 && data_count > 0) begin // if not end of block
			$fwrite(out_file, "%h\n", data_out_wiener[23:0]);
		end
	end

/**********
 * The simulation
 */

	initial begin
		// create output wiener file
		out_file = $fopen("output_wiener.txt", "w");
		if (out_file == 0) begin
			$display("Error: Could not open file.");
			$finish;
		end
		
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
			send_image_data("hedgehog_noisy.hex");

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
		$fclose(out_file); 
		$finish;
	end

	// Send image data via AXI Stream 
	task send_image_data(input string filename); 
	   integer file, status, r, g, b; 
	   begin 
		   file = $fopen(filename, "r"); 
		   if (file == 0) begin 
			   $display("Failed to open image data file."); 
			   $stop; 
		   end 
		   for(int i=0; i < pixels_per_frame && !$feof(file); i++) begin 
			   status = $fscanf(file, "%2h%2h%2h\n", r, g, b); 
			   $display("Pixel %0d: Red=%0h, Green=%0h, Blue=%0h", i, r, g, b);
			   send_transaction({8'b0, r[7:0], g[7:0], b[7:0]}, (i%frame_width == frame_width-1) ,i==0); 
		   end
		   $fclose(file); 
	   end 
	endtask 
	
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
