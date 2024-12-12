/*------------------------------------------------------------------------------
 * File          : Image_loading_test_AXI.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 6, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns / 1ps 

module AXI_image_loading_test #() ();

// AXI Stream signals 
reg clk; 
reg resetn; 
reg tvalid; 
reg [31:0] tdata; // 4 bytes per pixel 
wire tready; 

// AXI Lite signals 
reg [31:0] s_axi_awaddr; 
reg [31:0] s_axi_wdata; 
reg s_axi_awvalid; 
reg s_axi_wvalid; 
wire s_axi_awready; 
wire s_axi_wready; 

// Width and height parameters 
reg [31:0] width; 
reg [31:0] height; 

// DUT instantiation 
AXI_stream_slave dut ( 
   .clk(clk), 
   .rst_n(resetn),
   .m_axis_tvalid(tvalid), 
   .m_axis_tdata(tdata), 
   .m_axis_tready(tready), 
   .s_axi_awaddr(s_axi_awaddr), 
   .s_axi_wdata(s_axi_wdata), 
   .s_axi_awvalid(s_axi_awvalid), 
   .s_axi_wvalid(s_axi_wvalid), 
   .s_axi_awready(s_axi_awready), 
   .s_axi_wready(s_axi_wready) 
); 

// Clock generation 
always #5 clk = ~clk; // 100MHz clock 

// Testbench initialization 
initial begin 
   clk = 0; 
   resetn = 0; 
   tvalid = 0; 
   s_axi_awvalid = 0; 
   s_axi_wvalid = 0; 
   width = 0; 
   height = 0; 

   // Reset the DUT 
   #20 resetn = 1; 

   // Configure width and height using AXI Lite 
   axi_write(32'h00, 128); // Width address 
   axi_write(32'h04, 128); // Height address 
   width = 128; 
   height = 128; 

   // Load and send image data 
   send_image_data("image_data.txt"); 

   #5000; // Wait for simulation 
   $stop; 
end 

// AXI Lite Write Task 
task axi_write(input [31:0] addr, input [31:0] data); 
   begin 
	   s_axi_awaddr = addr; 
	   s_axi_awvalid = 1; 
	   s_axi_wdata = data; 
	   s_axi_wvalid = 1; 
	   wait (s_axi_awready && s_axi_wready); 
	   s_axi_awvalid = 0; 
	   s_axi_wvalid = 0; 
   end 
endtask 

// Send image data via AXI Stream 
task send_image_data(input string filename); 
   integer file, status, r, g, b; 
   begin 
	   file = $fopen(filename, "r"); 
	   if (file == 0) begin 
		   $display("Failed to open image data file."); 
		   $stop; 
	   end 
	   while (!$feof(file)) begin 
		   status = $fscanf(file, "%d %d %d\n", r, g, b); 
		   tdata = {8'b0, r[7:0], g[7:0], b[7:0]}; 
		   tvalid = 1; 
		   wait (tready); 
		   #10; // Wait for the next clock 
	   end 
	   tvalid = 0; 
	   $fclose(file); 
   end 
endtask 

endmodule 