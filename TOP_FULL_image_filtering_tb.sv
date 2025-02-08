/*------------------------------------------------------------------------------
 * File          : TOP_AXI_stream_memory_noise_estimation_wiener_FULL_image_tb_version2.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 20, 2025
 * Description   : opend hex file and reads all blocks
 *------------------------------------------------------------------------------*/



module TOP_FULL_image_filtering_tb #(
// Parameters of TB
parameter 		BYTE_DATA_WIDTH = 8,
parameter 		BLOCK_SIZE = 8,
parameter 		DATA_WIDTH = 32,
parameter 		ADDR_WIDTH = 32,
parameter string		IN_IMG = "hex_data_in.hex",
parameter 		WIDTH = 1280,
parameter 		HEIGHT = 720,
parameter string		OUT_IMG = "hex_data_out.hex"
) ();

parameter 		SAMPLES_PER_BLOCK = BLOCK_SIZE*BLOCK_SIZE;// total number of pixels in frame
parameter 		TOTAL_SAMPLES = WIDTH*HEIGHT; // total number of pixels in frame

logic           clk;
logic           rst_n;
logic [15:0] 	frame_height;
assign frame_height=HEIGHT;
logic [15:0]	frame_width;
assign frame_width=WIDTH;
logic  [31:0] 	blocks_per_frame;
assign blocks_per_frame = TOTAL_SAMPLES/(BLOCK_SIZE*BLOCK_SIZE);
logic [31:0]                pixels_per_frame;
assign pixels_per_frame = TOTAL_SAMPLES;
logic  [DATA_WIDTH-1:0]     s_axis_tdata;
logic                       s_axis_tvalid;
logic                       s_axis_tlast;
logic                       s_axis_tready;
logic 						s_axis_tuser;
logic rlast;
logic noise_estimation_en;
logic start_data_noise_est;
logic start_of_frame_noise_estimation;
logic [4*BYTE_DATA_WIDTH-1:0] estimated_noise;
logic estimated_noise_ready;
logic start_of_frame_wiener;
logic frame_ready_for_noise_est;
logic start_data_wiener;
logic wiener_block_stats_en; 
logic wiener_calc_en;       
logic [31:0] data_count ; 
logic [DATA_WIDTH-1:0] data_out_wiener;


/***************************
 *  AXI memory slave wires 
 ***************************/
// Read Address Channel 1
logic [ADDR_WIDTH-1:0] araddr;
logic [7:0] arlen;
logic [2:0] arsize;
logic [1:0] arburst;
logic arvalid;

// Read Data Channel 1
logic [DATA_WIDTH-1:0] rdata;
logic [1:0] rresp;
logic rready;

// Read Address Channel 2
logic arready_2;
logic rlast_2;
logic [ADDR_WIDTH-1:0] araddr_2;
logic [7:0] arlen_2;
logic arvalid_2;

// Read Data Channel 
logic [DATA_WIDTH-1:0] rdata_2;
logic rvalid_2;
logic rready_2;

// Write Address Channel
logic [ADDR_WIDTH-1:0] awaddr;
logic [7:0] awlen;
logic [2:0] awsize;
logic [1:0] awburst;
logic awvalid;
logic awready;

// Write Data Channel
logic [DATA_WIDTH-1:0] wdata;
logic [DATA_WIDTH/8-1:0] wstrb;
logic wlast;
logic wvalid;
logic wready;

// Write Response Channel
logic [1:0] bresp;
logic bvalid;
logic bready;

/***************************
 *       TOP module
 ***************************/
TOP_AXI_stream_memory_noise_estimation_wiener_NO_AXI_mem_slave #(
	.BYTE_DATA_WIDTH(BYTE_DATA_WIDTH),
	.BLOCK_SIZE(BLOCK_SIZE),
	.DATA_WIDTH(DATA_WIDTH),
	.MEM_SIZE(TOTAL_SAMPLES),
	.TOTAL_SAMPLES(TOTAL_SAMPLES),
	.SAMPLES_PER_BLOCK(SAMPLES_PER_BLOCK)
) TOP_AXI_stream_memory_noise_estimation_wiener_NO_AXI_mem_slave_inst (
	.clk(clk),                                    // Clock signal
	.rst_n(rst_n),                                // Active-low reset
	// general parameters
	.frame_height(frame_height),                  // Frame height
	.frame_width(frame_width),                    // Frame width
	.blocks_per_frame(blocks_per_frame),          // Number of blocks per frame
	.pixels_per_frame(pixels_per_frame),          // Number of pixels per frame
	// AXI stream in
	.s_axis_tdata(s_axis_tdata),                  // Input data stream
	.s_axis_tvalid(s_axis_tvalid),                // Valid signal for input stream
	.s_axis_tlast(s_axis_tlast),                  // Last signal for input stream
	.s_axis_tready(s_axis_tready),                // Ready signal for input stream
	.s_axis_tuser(s_axis_tuser),                  // User signal for input stream
	// control signals
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
	// output from wiener
	.data_count(data_count),                       // Data count
	.data_out_wiener(data_out_wiener) ,             // Output data after Wiener filter
	// wires from YOP to AXI memory slave
	//.awid(awid),
	.awaddr(awaddr),
	.awlen(awlen),
	//.awsize(awsize),
	//.awburst(awburst),
	.awvalid(awvalid),
	.awready(awready),
	.wdata(wdata),
	//.wstrb(wstrb),
	.wlast(wlast),
	.wvalid(wvalid),
	.wready(wready),
	//.bid(bid),
	//.bresp(bresp),
	.bvalid(bvalid),
	.bready(bready),
	//.arid(arid),
	.araddr(araddr),
	.arlen(arlen),
	//.arsize(arsize),
	//.arburst(arburst),
	.arvalid(arvalid),
	.arready(arready),
	//.rid(rid),
	.rdata(rdata),
	//.rresp(rresp),
	.rlast(rlast),
	.rvalid(rvalid),
	.rready(rready),
	.araddr_2(araddr_2),
	.arlen_2(arlen_2),
	.arvalid_2(arvalid_2),
	.arready_2(arready_2),
	.rdata_2(rdata_2),
	.rvalid_2(rvalid_2),
	.rready_2(rready_2),
	.rlast_2(rlast_2)
);


/****************************************
 *  AXI memory slave (Non synthesizable)
 ***************************************/ 
AXI_memory_slave_3channels #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH),
	.MEM_SIZE(TOTAL_SAMPLES),
	.INIT_OPTION(0)
  ) AXI_memory_slave_uut (
	.clk(clk),
	.rst_n(rst_n),
	.awaddr(awaddr),
	//.awlen(awlen),
	.awvalid(awvalid),
	.awready(awready),
	.wdata(wdata),
	.wlast(wlast),
	.wvalid(wvalid),
	.wready(wready),
	.bresp(bresp),
	.bvalid(bvalid),
	.bready(bready),
	.araddr(araddr),
	.arlen(arlen),
	.arvalid(arvalid),
	.arready(arready),
	.rdata(rdata),
	.rlast(rlast),
	.rvalid(rvalid),
	.rready(rready),
	
	.araddr_2(araddr_2),
	.arlen_2(arlen_2),
	.arvalid_2(arvalid_2),
	.arready_2(arready_2),
	.rdata_2(rdata_2),
	.rlast_2(rlast_2),
	.rvalid_2(rvalid_2),
	.rready_2(rready_2)
  );


	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end
	

	/// FOR DEBUG - can be deleted on synthesis
	always @(posedge estimated_noise_ready) begin
		$display("Estimated noise: ");
		$display(estimated_noise);
	end

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
		out_file = $fopen(OUT_IMG, "w");
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
			send_image_data(IN_IMG);
			// End transaction
			@(negedge clk);
			s_axis_tuser = 1'b0;
			s_axis_tvalid = 1'b0;
			s_axis_tdata = 1'b0; 
			@(posedge clk);
			#1;
			s_axis_tlast = 1'b0;

				
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
				if(j==BLOCK_SIZE-1) begin
					#10; // for mean calculation - last cycle
				end
					
				
				if (j!=BLOCK_SIZE-1) begin
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
			   //$display("Pixel %0d: Red=%0h, Green=%0h, Blue=%0h", i, r, g, b);
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
