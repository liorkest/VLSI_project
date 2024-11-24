/*------------------------------------------------------------------------------
 * File          : mean_unit_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module mean_unit_tb;

// Parameters
parameter DATA_WIDTH = 8;
parameter TOTAL_SAMPLES = 64;

// Testbench signals
logic                   clk;
logic                   rst_n;
logic [DATA_WIDTH-1:0]  data_in;
logic                   start_data_in;
logic [DATA_WIDTH-1:0]  mean_out;
logic                   ready;

// Instantiate the variance calculator module
mean_unit #(
	.DATA_WIDTH(DATA_WIDTH),
	.TOTAL_SAMPLES(TOTAL_SAMPLES)
) uut (
	.clk(clk),
	.rst_n(rst_n),
	.data_in(data_in),
	.start_data_in(start_data_in),
	.mean_out(mean_out),
	.ready(ready)
);

// Clock generation
initial begin
	clk = 1'b0;
	start_data_in = 1'b0;
	forever #5 clk = ~clk; // 100 MHz clock
end

// Task to reset the design
task reset;
	begin
		rst_n = 0;
		#20;
		rst_n = 1;
	end
endtask

// Task to feed sample data
task feed_sample(input [DATA_WIDTH-1:0] sample, int i);
	begin
		data_in = sample;
		#10; // Wait one clock cycle
	end
endtask

// Stimulus generation
initial begin
	integer i;
	logic [DATA_WIDTH-1:0] sample_data [TOTAL_SAMPLES-1:0]; // Array for test samples
	// Reset the design
	reset;
	// Initialize sample data (you can customize this array)
	for (i = 0; i < TOTAL_SAMPLES; i++) begin
		sample_data[i] = i; // Example: Sequential data values
	end

	// Set a known mean value (can be any value for testing)
//	mean = 8'd31;
	
	start_data_in = 1'b1;
	#10;
	start_data_in = 1'b0;
	// Feed samples to the variance calculator
	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(sample_data[i], i);
	end

	// Wait for ready signal and check the result
	@(posedge ready);
	$display("Variance calculated: %d", mean_out);
	#10
	// Initialize sample data (you can customize this array)
	for (i = 0; i < TOTAL_SAMPLES; i++) begin
		sample_data[i] = i + 10; // Example: Sequential data values
	end

	// Set a known mean value (can be any value for testing)
//	mean = 8'd41;
	
	start_data_in = 1'b1;
	#10;
	start_data_in = 1'b0;
	// Feed samples to the variance calculator
	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(sample_data[i], i);
	end
	
	// Wait for ready signal and check the result
	@(posedge ready);
	$display("Variance calculated: %d", mean_out);
	#10
	// Set a known mean value (can be any value for testing)
//	mean = 8'd6;
	
	start_data_in = 1'b1;
	#10;
	start_data_in = 1'b0;
	// Feed samples to the variance calculator
	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(8'd6, i);
	end

	// End simulation
	#50;
	$finish;
end
endmodule