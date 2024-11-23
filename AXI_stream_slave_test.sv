/*------------------------------------------------------------------------------
 * File          : AXI_stream_slave_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jul 9, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

`timescale 1ns / 1ps

module AXI_stream_slave_tb;

	// Parameters
	parameter DATA_WIDTH = 32;

	// Testbench signals
	logic                       clk;
	logic                       rst_n;
	logic  [DATA_WIDTH-1:0]     s_axis_tdata;
	logic                       s_axis_tvalid;
	logic                       s_axis_tlast;
	logic                       s_axis_tready;
	logic 						s_axis_tuser;

	// Instantiate the AXI_stream_slave module
	AXI_stream_slave #(
		.DATA_WIDTH(DATA_WIDTH)
	) uut (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tlast(s_axis_tlast),
		.s_axis_tuser(s_axis_tuser)
	);

	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end

	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		s_axis_tdata = 0;
		s_axis_tvalid = 1'b0;
		s_axis_tlast = 1'b0;
		s_axis_tuser = 1'b0;

		// Reset the system
		#20;
		rst_n = 1'b1;

		// Send a single transaction
		#10;
		send_transaction(32'hA5A5A5A5, 1'b0,1'b0 ); // Data: 0xA5A5A5A5, Last: 1

		// Send a multi-cycle transaction
		#50;
		send_transaction(32'h12345678, 1'b0,1'b1); // Data: 0x12345678, Last: 0
		#10;
		send_transaction(32'hDEADBEEF, 1'b1,1'b0); // Data: 0xDEADBEEF, Last: 1		
		#10;
		send_transaction(32'hFACEFADE, 1'b1,1'b1); // Data: 0xFACEFADE, Last: 1
		send_transaction(32'hABEDDEAF, 1'b0,1'b1); // Data: 0xABEDDEAF, Last: 1
		// End simulation
		#50;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data, input last, input user);
	begin
		s_axis_tdata = data;
		s_axis_tvalid = 1'b1;
		s_axis_tlast = last;
		s_axis_tuser = user;
		wait(s_axis_tready);
		#10;
		s_axis_tvalid = 1'b0;
		s_axis_tlast = 1'b0;
		s_axis_tuser = 1'b0;
	end
	endtask

endmodule
