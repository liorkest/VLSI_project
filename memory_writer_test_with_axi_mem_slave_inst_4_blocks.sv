/*------------------------------------------------------------------------------
 * File          : memory_writer_test_with_axi_mem_slave_inst.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module memory_writer_test_with_axi_mem_slave_inst_4_blocks;
	// Parameters
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 32;
	parameter ID_WIDTH = 4;
	parameter MEM_SIZE = 256;
	// Testbench signals
	logic                       clk;
	logic                       rst_n;
	logic [31:0]                pixels_per_frame=8*8*4;
	int 						frames_num = 1;
	logic [15:0]                frame_height=8*2;	
	logic [15:0]                frame_width=8*2;	
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
	
	/* [commented by LK 01.12.25]
	// Read Address Channel
	logic [ID_WIDTH-1:0] arid;
	logic [ADDR_WIDTH-1:0] araddr;
	logic [7:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	logic arvalid;
	logic arready;

	// Read Data Channel
	logic [ID_WIDTH-1:0] rid;
	logic [DATA_WIDTH-1:0] rdata;
	logic [1:0] rresp;
	logic rlast;
	logic rvalid;
	logic rready;
	*/ 
	
	// Control signals
	logic [ID_WIDTH-1:0] write_id=0;
	/* [commented by LK 01.12.25]
	logic start_read;
	logic [ID_WIDTH-1:0] read_id;
	logic [ADDR_WIDTH-1:0] read_addr;
	logic [31:0] read_len;
	logic [2:0] read_size;
	logic [1:0] read_burst;
	*/

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
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) AXI_memory_master_burst_uut (
		.clk(clk),
		.resetn(rst_n),
		
		// Write Address Channel
		.awid(awid),
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
		//.bid(bid),
		//.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		
		/* [commented by LK 01.12.25]
		// Read Address Channel
		.arid(arid),
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		
		// Read Data Channel
		.rid(rid),
		.rdata(rdata),
		.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		*/
		
		// Control signals
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.start_read(start_read)
		/* [commented by LK 01.12.25]
		, .read_id(read_id),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst)
		*/
	);
	
	AXI_memory_slave #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.MEM_SIZE(MEM_SIZE),
		.INIT_OPTION(0)
	  ) AXI_memory_slave_uut (
		.clk(clk),
		.rst_n(rst_n),
		//.awid(awid),
		.awaddr(awaddr),
		.awlen(awlen),
		//.awsize(awsize),
		//.awburst(awburst),
		.awvalid(awvalid),
		.awready(awready),
		.wdata(wdata),
		//.wstrb(wstrb),
		.wlast(wlast),
		.wvalid(wvalid),
		.wready(wready),
		//.bid(bid),
		.bresp(bresp),
		.bvalid(bvalid),
		.bready(bready),
		//.arid(arid),
		.araddr(araddr),
		.arlen(arlen),
		//.arsize(arsize),
		//.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		//.rid(rid),
		.rdata(rdata),
		//.rresp(rresp),
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready)
	  );

	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end
	
	// 17.01.25 added the data of 4 blocks
	logic [7:0] data [0:255] = {46,18,253,180,124,96,88,49,208,206,155,1,179,123,138,250,216,127,228,182,254,188,95,142,26,80,2,31,75,25,112,107,247,119,91,68,236,6,240,149,225,183,131,124,66,250,80,62,0,23,239,96,218,77,79,47,37,175,123,49,143,147,10,39,130,77,75,73,99,27,186,150,129,2,251,3,67,216,64,156,85,11,146,136,190,216,114,108,18,236,166,44,93,144,108,13,15,182,216,161,7,40,168,93,121,217,227,115,180,239,158,178,140,166,205,71,207,108,151,84,52,110,206,210,52,99,166,193,38,46,0,86,143,0,247,120,224,252,191,48,192,130,86,238,229,115,50,73,163,152,176,42,236,194,4,118,41,254,30,199,165,165,180,98,126,42,242,23,169,244,101,58,149,25,122,174,199,52,7,152,12,123,254,78,66,89,47,213,150,92,64,206,62,83,81,41,192,42,230,141,99,33,46,19,140,202,184,93,17,78,74,17,188,6,66,246,238,155,85,52,88,149,191,10,158,30,7,32,76,177,176,50,224,115,12,246,175,226,144,144,111,130,4,55,201,207,189,66,95,25,181,111,80,186,234,113};


	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		s_axis_tdata = 0;
		s_axis_tvalid = 1'b0;
		s_axis_tlast = 1'b0;
		s_axis_tuser = 1'b0;
		
		/* [commented by LK 01.12.25]
		start_read = 0;
		read_id = 0;
		read_addr = 0;
		read_len = 0;
		read_size = 0;
		read_burst = 0;
		*/
		
		// Reset the system
		#20;
		rst_n = 1'b1;
		@(posedge clk);

		// Send a single transaction
		#10;
		// Send a multi-cycle transaction
		//#50;
		for(int frame=0; frame < frames_num; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin 
				send_transaction({0,data[i],data[i],data[i]}, (i%frame_width == frame_width-1) ,i==0); // Data: 0x12345678, Last: 0 
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
