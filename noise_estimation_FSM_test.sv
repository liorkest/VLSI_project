/*------------------------------------------------------------------------------
 * File          : noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module tb_noise_estimation_FSM;

	// Parameters
	parameter DATA_WIDTH = 8;
	parameter TOTAL_SAMPLES = 16;

	// Signals
	logic                   clk;
	logic                   rst_n;
	logic                   start_of_frame;
	logic                   end_of_frame;
	logic                   mean_ready;
	logic                   variance_ready;
	logic [31:0]            blocks_per_frame;

	// Outputs
	logic                   shift_en;
	logic                   noise_mean_en;
	logic                   shift_reg_rst_n;
	logic                   variance_start_of_data;

	// Instantiate the DUT
	noise_estimation_FSM #(
		.DATA_WIDTH(DATA_WIDTH),
		.TOTAL_SAMPLES(TOTAL_SAMPLES)
	) uut (
		.clk(clk),
		.rst_n(rst_n),
		.start_of_frame(start_of_frame),
		//.end_of_frame(end_of_frame),
		.mean_ready(mean_ready),
		.variance_ready(variance_ready),
		.blocks_per_frame(blocks_per_frame),
		.shift_en(shift_en),
		.noise_mean_en(noise_mean_en),
		.shift_reg_rst_n(shift_reg_rst_n),
		.variance_start_of_data(variance_start_of_data)
	);

	// Clock generation
	always #5 clk = ~clk;

	// Testbench sequence
	initial begin
		// Initialize signals
		clk = 0;
		rst_n = 0;
		start_of_frame = 0;
		end_of_frame = 0;
		mean_ready = 0;
		variance_ready = 0;
		blocks_per_frame = 4; // Example: 4 blocks per frame

		// Reset the design
		#10 rst_n = 1;

		// Start of frame
		@(posedge clk);
		start_of_frame = 1;
		@(posedge clk);
		start_of_frame = 0;
		for (int i=0; i < blocks_per_frame; i++) begin
			// Simulate 64 samples being read
			repeat (TOTAL_SAMPLES) begin
				@(posedge clk);
			end
	
			// Wait for mean_ready signal
			@(posedge clk);
			mean_ready = 1;
			@(posedge clk);
			mean_ready = 0;
	
			// Simulate 2 more cycles of empty data
			repeat (2) @(posedge clk);
			
			variance_ready = 1;
			@(posedge clk);
			variance_ready = 0;
		end
		
		// End of frame after all blocks
		end_of_frame = 1;
		@(posedge clk);
		end_of_frame = 0;

		// Finish the test
		#100 $finish;
	end

	// Monitor for debugging
	initial begin
		$monitor($time, " clk=%b, rst_n=%b, start_of_frame=%b, shift_en=%b, noise_mean_en=%b, shift_reg_rst_n=%b, variance_start_of_data=%b",
				 clk, rst_n, start_of_frame, shift_en, noise_mean_en, shift_reg_rst_n, variance_start_of_data);
	end

endmodule
