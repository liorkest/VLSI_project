/*------------------------------------------------------------------------------
 * File          : AXI_stream_master_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 3, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

// `timescale 1ns / 1ps

module Weiner_filter_tb;

	// Parameters
	parameter DATA_WIDTH = 32;

	// Testbench signals
	logic                      clk;
	logic                      rst_n;
	
	// Data generation outputs
	logic [DATA_WIDTH-1:0]    data_out;      // Data from data generator
	logic                      valid_out;     // Valid signal from data generator
	logic                      last_out;      // Last signal from data generator
	logic                      user_out;      // User signal from data generator

	// AXI Stream Master signals
	logic [DATA_WIDTH-1:0]    m_axis_tdata;  // Data to send
	logic                      m_axis_tvalid; // Valid signal to send
	logic                      m_axis_tready; // Ready signal from slave
	logic                      m_axis_tlast;  // Last signal for AXI
	logic                      m_axis_tuser;  // User signal for AXI

	// Instantiate the data_gen module
	data_gen #(
		.DATA_WIDTH(DATA_WIDTH)
	) data_gen_inst (
		.clk(clk),
		.rst_n(rst_n),
		.data_out(data_out),
		.valid_out(valid_out),
		.last_out(last_out),
		.user_out(user_out)
	);

	// Instantiate the AXI_stream_master module
	AXI_stream_master #(
		.DATA_WIDTH(DATA_WIDTH)
	) axi_master_inst (
		.clk(clk),
		.rst_n(rst_n),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tuser(m_axis_tuser),
		.data_in(data_out),
		.valid_in(valid_out),
		.last_in(last_out),
		.user_in(user_out)
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
		m_axis_tready = 1'b0;

		// Allow the data_gen to run for a while
		#100;
		m_axis_tready = 1'b1;

		// Observe AXI stream outputs for some time
		#200;
		m_axis_tready = 1'b0;

		#50;
		m_axis_tready = 1'b1;
		#50
		// End simulation
		$finish;
	end

	// Monitor and display transactions
	initial begin
		$monitor("Time=%0t | m_axis_tdata=%h | m_axis_tvalid=%b | m_axis_tready=%b | m_axis_tlast=%b | m_axis_tuser=%b",
				 $time, m_axis_tdata, m_axis_tvalid, m_axis_tready, m_axis_tlast, m_axis_tuser);
	end

endmodule