/*------------------------------------------------------------------------------
 * File          : RGB_mean_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 19, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
module RGB_mean_tb; 

 // Parameters 
 parameter DATA_WIDTH = 8; 

 // Inputs 
 logic en; 
 logic [DATA_WIDTH*3-1:0] data_in; 

 // Outputs 
 logic [DATA_WIDTH-1:0] data_out; 

 // Internal variables 
 integer i; 

 // DUT instantiation 
 RGB_mean #(.DATA_WIDTH(DATA_WIDTH)) dut ( 
   .en(en), 
   .data_in(data_in), 
   .data_out(data_out) 
 ); 

 // Testbench logic 
 initial begin 
   // Initialize inputs 
   en = 0; 
   data_in = 0; 

   // Apply test cases 
   $display("Starting simulation..."); 

   // Test case 1 
   en = 1; 
   data_in = {8'd50, 8'd100, 8'd150}; // R = 50, G = 100, B = 150 
   #10; 
   $display("Input: R = %0d, G = %0d, B = %0d, Output: %0d",  
			 data_in[7:0], data_in[15:8], data_in[23:16], data_out); 

   // Test case 2 
   data_in = {8'd10, 8'd20, 8'd30}; // R = 10, G = 20, B = 30 
   #10; 
   $display("Input: R = %0d, G = %0d, B = %0d, Output: %0d",  
			 data_in[7:0], data_in[15:8], data_in[23:16], data_out); 

   // Test case 3 
   data_in = {8'd255, 8'd255, 8'd255}; // R = G = B = 255 
   #10; 
   $display("Input: R = %0d, G = %0d, B = %0d, Output: %0d",  
			 data_in[7:0], data_in[15:8], data_in[23:16], data_out); 

   // Test case 4 
   data_in = {8'd0, 8'd128, 8'd255}; // R = 0, G = 128, B = 255 
   #10; 
   $display("Input: R = %0d, G = %0d, B = %0d, Output: %0d",  
			 data_in[7:0], data_in[15:8], data_in[23:16], data_out); 

   // End simulation 
   $display("Simulation completed."); 
   $stop; 
 end 

endmodule 
