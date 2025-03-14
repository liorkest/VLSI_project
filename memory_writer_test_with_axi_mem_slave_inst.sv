/*------------------------------------------------------------------------------
 * File          : memory_writer_test_with_axi_mem_slave_inst.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module memory_writer_test_with_axi_mem_slave_inst;
	// Parameters
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 32;
	parameter ID_WIDTH = 4;
	parameter MEM_SIZE = 128;
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
	
	// Write Address Channel
	logic [ID_WIDTH-1:0] awid;
	logic [ADDR_WIDTH-1:0] awaddr;
	logic [7:0] awlen;
	logic [2:0] awsize;
	logic [1:0] awburst;
	logic awvalid;
	logic awready;

	// Write Data Channel
	logic [DATA_WIDTH-1:0] wdata;
	logic [DATA_WIDTH/8-1:0] wstrb;
	logic wlast;
	logic wvalid;
	logic wready;

	// Write Response Channel
	logic [ID_WIDTH-1:0] bid;
	logic [1:0] bresp;
	logic bvalid;
	logic bready;
	
	// Control signals
	logic [ID_WIDTH-1:0] write_id=0;

	// Instantiate the AXI_stream_slave module
	memory_writer #(
		.DATA_WIDTH(DATA_WIDTH)
	) memory_writer_uut (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tlast(s_axis_tlast),
		.s_axis_tuser(s_axis_tuser),
		.pixels_per_frame(pixels_per_frame),
		.frame_height(frame_height),
		//.frame_width(frame_width),
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
	
	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH)
	) AXI_memory_master_burst_uut (
		.clk(clk),
		.resetn(rst_n),
		
		// Write Address Channel
		.awaddr(awaddr),
		.awlen(awlen),
		.awsize(awsize),
		.awburst(awburst),
		.awvalid(awvalid),
		.awready(awready),
		
		// Write Data Channel
		.wdata(wdata),
		.wstrb(wstrb),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		
		// Write Response Channel
		.bvalid(bvalid),
		.bready(bready),
		// Control signals
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.start_read(start_read)
	);
	
	AXI_memory_slave #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.MEM_SIZE(MEM_SIZE)
	  ) AXI_memory_slave_uut (
		.clk(clk),
		.rst_n(rst_n),
		.awaddr(awaddr),
		.awlen(awlen),
		.awvalid(awvalid),
		.awready(awready),
		.wdata(wdata),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		.araddr(araddr),
		.arlen(arlen),
		.arvalid(arvalid),
		.arready(arready),
		.rdata(rdata),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready)
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
		for(int frame=0; frame < 4; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin 
				send_transaction((i+1)*(frame+1), (i%frame_width == frame_width-1) ,i==0); // Data: 0x12345678, Last: 0 // [LK 01.01.25 changed to (i+1)]
			end
			// End transaction
			@(negedge clk);
			s_axis_tuser = 1'b0;
			s_axis_tvalid = 1'b0;
			s_axis_tdata = 1'b0; // [LK 01.01.25]
			@(posedge clk);
			#1;
			s_axis_tlast = 1'b0;
			#9;
			#30; // [LK 01.01.25 changed from 20 to 40. Less is not working. MUST have 4 cycles between frames.]
		end
		#50;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data, input last, input user);
	begin
		s_axis_tvalid = 1'b1;
		s_axis_tuser = user;
		@(negedge clk);
		s_axis_tdata = data;
		#1;
		s_axis_tlast = last;
		// #9;
		wait(s_axis_tready);


	end
	endtask
	


endmodule
