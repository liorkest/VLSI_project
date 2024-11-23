/*------------------------------------------------------------------------------
 * File          : mean_unit_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 10, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module mean_unit_tb #(parameter data_len = 25, frac_bits = 8);

// Inputs
reg clk;
reg reset;
reg [31:0] data_in;
reg valid;
reg start_data;

// Outputs
wire [31:0] mean;

// Instantiate the Unit Under Test (UUT)
mean_unit #(.frac_bits(frac_bits)) uut (
  .clk(clk),
  .reset(reset),
  .data_len(data_len),
  .data_in(data_in),
  .valid(valid),
  .start_data(start_data),
  .mean(mean)
);

// Clock generation
always #5 clk = ~clk;

// Testbench logic
initial begin
  // Initialize signals
  clk <= 0;
  reset <= 1;
  data_in <= 0;
  valid <= 0;
  start_data <= 0;

  // Apply reset
  #10 reset <= 0;

  // Test case 1: Empty input sequence
  #10 start_data <= 1;
  #10 start_data <= 0;

  // Test case 2: Single-value input sequence
  #10 start_data <= 1;
  #10 data_in <= 10;
  valid <= 1;
  #10 valid <= 0;
  #10 start_data <= 0;

  // Test case 3: Multiple-value input sequence
  #10 start_data <= 1;
  for (int i = 0; i < data_len; i++) begin
	data_in <= 3;
	valid <= 1;
	#10
	start_data <= 0;
	
  end
  #10
  start_data <= 1;
  for (int i = 0; i < data_len ; i++) begin
	data_in <= 2;
	#10
	start_data <= 0;
	valid <= 1;
  end

  // Finish simulation
  #10 $finish;
end

endmodule