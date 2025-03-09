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
parameter TOTAL_SAMPLES = 16;

// Testbench signals
logic                   clk;
logic                   rst_n;
logic [DATA_WIDTH-1:0]  data_in;
logic                   start_data_in;
logic                   en;
logic [DATA_WIDTH-1:0]  mean_out;
logic                   ready;

// Instantiate the variance calculator module
mean_unit #(
	.DATA_WIDTH(DATA_WIDTH)
) uut (
	.clk(clk),
	.rst_n(rst_n),
	.total_samples(TOTAL_SAMPLES), //[06.12.24]
	.data_in(data_in),
	.start_data_in(start_data_in),
	.en(en),
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
		if (i==0) begin
			start_data_in = 1'b1;
			#10;
			start_data_in = 1'b0;
		end
		data_in = sample;
		#10; // Wait one clock cycle
	end
endtask

// Stimulus generation
initial begin
	int i;
	logic [DATA_WIDTH-1:0] sample_data [TOTAL_SAMPLES-1:0]; // Array for test samples
	// Reset the design
	reset;
	
	//TEST [1 ... 64]
	@(posedge clk);
	// Initialize sample data (you can customize this array)
	for (i = 0; i < TOTAL_SAMPLES; i++) begin
		sample_data[i] = i + 1;
	end

	en =1 ;
	#10;
	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(sample_data[i], i);
	end

	//TEST [10 ... 74]
	#10
	for (i = 0; i < TOTAL_SAMPLES; i++) begin
		sample_data[i] = i + 11;
	end


	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(sample_data[i], i);
	end
	
	
	//TEST const [6 ... 6]
	#10
	for (i = 0; i < TOTAL_SAMPLES; i++) begin

		feed_sample(8'd6, i);
	end
	// Wait for ready signal 
	#10;
			
	//TEST  [1 ... 128] with only even enabled => [2,4,...128] are counted
	//// check of en flag /////////
	// Feed samples to the variance calculator
	for (i = 0; i < TOTAL_SAMPLES*2; i++) begin
		en=i[0] + 1; // only odd values get '1'
		feed_sample(i+1, i); // feed 1..128
	end

	// End simulation
	#50;
	$finish;
end
endmodule