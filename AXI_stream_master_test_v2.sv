/*------------------------------------------------------------------------------
 * File          : AXI_stream_master_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 26, 2025
 * Description   : Testbench for AXI_stream_master with AXI_stream_slave
 ------------------------------------------------------------------------------*/


module AXI_stream_master_test_new;

	// Parameters
	parameter DATA_WIDTH = 32;

	// Testbench signals
	logic                      clk;
	logic                      rst_n;

	// Master interface signals
	logic [DATA_WIDTH-1:0]     m_axis_tdata;
	logic                      m_axis_tvalid;
	logic                      m_axis_tlast;
	logic                      m_axis_tuser;
	logic                      m_axis_tready;

	// Slave interface signals
	logic [DATA_WIDTH-1:0]     s_axis_tdata;
	logic                      s_axis_tvalid;
	logic                      s_axis_tlast;
	logic                      s_axis_tuser;
	logic                      s_axis_tready;

	// Input to master
	logic [DATA_WIDTH-1:0]     data_in;
	logic                      valid_in;
	logic                      last_in;
	logic                      user_in;

	// Instantiate the AXI_stream_master module
	AXI_stream_master #(
		.DATA_WIDTH(DATA_WIDTH)
	) master_inst (
		.clk(clk),
		.rst_n(rst_n),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tuser(m_axis_tuser),
		.data_in(data_in),
		.valid_in(valid_in),
		.last_in(last_in),
		.user_in(user_in)
	);

	// Instantiate the AXI_stream_slave module
	AXI_stream_slave #(
		.DATA_WIDTH(DATA_WIDTH)
	) slave_inst (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready)
		//.s_axis_tlast(s_axis_tlast),
		//.s_axis_tuser(s_axis_tuser)
	);

	// Connect master and slave
	assign s_axis_tdata = m_axis_tdata;
	assign s_axis_tvalid = m_axis_tvalid;
	assign m_axis_tready = s_axis_tready;
	assign s_axis_tlast = m_axis_tlast;
	assign s_axis_tuser = m_axis_tuser;

	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100 MHz clock
	end

	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		data_in = 0;
		valid_in = 1'b0;
		last_in = 1'b0;
		user_in = 1'b0;

		// Reset the system
		#20;
		rst_n = 1'b1;

		// Send a single transaction
		//#10;
		//send_transaction(32'hA5A5A5A5, 1'b0, 1'b1); // Data: 0xA5A5A5A5, User: 1

		// Send a multi-cycle transaction
		send_transaction(32'h12345678, 1'b0, 1'b1); // Data: 0x12345678
		#10;
		send_transaction(32'hDEADBEEF, 1'b0, 1'b0); // Data: 0xDEADBEEF
		#10;
		send_transaction(32'hFACEFADE, 1'b0, 1'b0); // Data: 0xFACEFADE
		#10;
		send_transaction(32'hABEDDEAF, 1'b1, 1'b0); // Data: 0xABEDDEAF
		#20;	
		
		// Burst transaction
		send_burst_transaction();
		
		// End simulation
		#10;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data, input last, input user);
	begin
		data_in = data;
		valid_in = 1'b1;
		last_in = last;
		user_in = user;
		#10;
		data_in = {DATA_WIDTH{1'b0}};
		valid_in = 1'b0;
		last_in = 1'b0;
		user_in = 1'b0;
	end
	endtask
	
	// Task to send a burst transaction
	task send_burst_transaction();
	  integer i;
	  begin
		valid_in = 1'b1;
		user_in = 1'b1; // Start of frame
		for (i = 0; i < 5; i = i + 1) begin
		  data_in = 32'hDEADBEEF + i; // Increment data for each cycle
		  last_in = (i == 4);        // Set last_in high on the last transfer
		  wait(m_axis_tready);       // Wait for the master to be ready
		  #10;
		  user_in = 1'b0;
		end
		valid_in = 1'b0;             // De-assert valid after burst
		last_in = 1'b0;
		user_in = 1'b0;
	  end
	endtask


endmodule