/*------------------------------------------------------------------------------
 * File          : memory_writer_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_writer_tb;

	// Parameters
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 32;

	// Testbench signals
	logic                       clk;
	logic                       rst_n;
	logic [31:0]                pixels_per_frame=8;
	logic [15:0]                frame_height=2;	
	logic [15:0]                frame_width=4;	
	logic  [DATA_WIDTH-1:0]     s_axis_tdata;
	logic                       s_axis_tvalid;
	logic                       s_axis_tlast;
	logic                       s_axis_tready;
	logic 						s_axis_tuser;
	logic                    	start_write;
	logic [ADDR_WIDTH-1:0]   	write_addr;
	logic [31:0]             	write_len;
	logic [2:0]              	write_size;
	logic [1:0]              	write_burst;
	logic [DATA_WIDTH-1:0]  	write_data;
	logic [DATA_WIDTH/8-1:0]	write_strb;
			
	logic frame_ready;
	logic [ADDR_WIDTH-1:0] base_addr_out;

	// Instantiate the AXI_stream_slave module
	memory_writer #(
		.DATA_WIDTH(DATA_WIDTH)
	) uut (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tlast(s_axis_tlast),
		.s_axis_tuser(s_axis_tuser),
		.pixels_per_frame(pixels_per_frame),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.frame_ready(frame_ready),
		.base_addr_out(base_addr_out)
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
		@(posedge clk);
		// Send a single transaction
		#10;
		// Send a multi-cycle transaction
		//#50;
		for(int frame=0; frame < 10; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin
				send_transaction(i*100, (i%frame_width == frame_width-1) ,i==0); // Data: 0x12345678, Last: 0
			end
			// End transaction
			s_axis_tuser = 1'b0;
			s_axis_tvalid = 1'b0;
			#1;
			s_axis_tlast = 1'b0;
			#9;
			#20;
		end
		#50;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data, input last, input user);
	begin
		s_axis_tdata = data;
		s_axis_tvalid = 1'b1;
		s_axis_tuser = user;
		#1;
		s_axis_tlast = last;
		#9;
		wait(s_axis_tready);


	end
	endtask

endmodule
