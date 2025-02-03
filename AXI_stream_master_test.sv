/*------------------------------------------------------------------------------
 * File          : AXI_stream_master_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 3, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

// `timescale 1ns / 1ps

module AXI_stream_master_tb;

	// Parameters
	parameter DATA_WIDTH = 32;

	// Testbench signals
	logic                       clk;
	logic                       rst_n;
	logic [DATA_WIDTH-1:0]      m_axis_tdata;
	logic                       m_axis_tvalid;
	logic                       m_axis_tready;
	logic                       m_axis_tlast;
	logic                       m_axis_tuser;

	// Instantiate the AXI_stream_master module
	AXI_stream_master #(
		.DATA_WIDTH(DATA_WIDTH)
	) uut (
		.clk(clk),
		.rst_n(rst_n),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tuser(m_axis_tuser)
		
	);

	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100 MHz clock
	end

	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		m_axis_tready = 1'b0;

		// Reset the system
		#20;
		rst_n = 1'b1;

		// Enable m_axis_tready to accept data
		#10;
		m_axis_tready = 1'b1;

		// Wait for some transactions
		#200;

		// Toggle m_axis_tready to simulate back-pressure
		m_axis_tready = 1'b0;
		#20;
		m_axis_tready = 1'b1;

		// Continue running to observe a few more frames
		#200;
		
		// End simulation
		$finish;
	end

	// Monitor transactions
	initial begin
		$monitor("Time=%0t | tdata=%h | tvalid=%b | tready=%b | tlast=%b | tuser=%b",
				 $time, m_axis_tdata, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tuser);
	end

endmodule