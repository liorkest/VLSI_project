/*------------------------------------------------------------------------------
 * File          : from_memory_writer_output_to_axi_stream_master.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 26, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module memory_writer_output_to_axi_stream_master_test;
	// Parameters
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 32;
	parameter ID_WIDTH = 4;
	parameter MEM_SIZE = 256;
	parameter BLOCK_SIZE = 8;
	// Testbench signals
	logic                       clk;
	logic                       rst_n;
	logic [31:0]                pixels_per_frame=8*8*4;
	int 						frames_num = 1;
	logic [15:0]                frame_height=8*2;	
	logic [15:0]                frame_width=8*2;	
	logic                    	start_write_wiener;
	logic [DATA_WIDTH-1:0]      data_in;
	logic                    	start_write;
	logic [ADDR_WIDTH-1:0]   	write_addr;
	logic [31:0]             	write_len;
	logic [2:0]              	write_size;
	logic [1:0]              	write_burst;
	logic [DATA_WIDTH-1:0]  	write_data;
	logic [DATA_WIDTH/8-1:0]	write_strb;
			
	logic frame_ready;
	logic [ADDR_WIDTH-1:0] base_addr;
	
	// AXI memory master signals
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
	 
	// Control signals
	logic start_read;
	logic [ID_WIDTH-1:0] read_id;
	logic [ADDR_WIDTH-1:0] read_addr;
	logic [31:0] read_len;
	logic [2:0] read_size;
	logic [1:0] read_burst;
	
	// Memory Reader AXI Stream Master Interface
	logic [DATA_WIDTH-1:0] m_axis_tdata;
	logic m_axis_tvalid;
	logic m_axis_tready;
	logic m_axis_tlast;
	logic m_axis_tuser;
	logic [DATA_WIDTH-1:0] reader_data_in;
	logic valid_in;
	logic last_in;
	logic user_in;

	// AXI Stream Slave Interface
	logic [DATA_WIDTH-1:0] s_axis_tdata;
	logic s_axis_tvalid;
	logic s_axis_tready;
	logic s_axis_tlast;
	logic s_axis_tuser;

	memory_writer_output #(
		.DATA_WIDTH(DATA_WIDTH)
	) memory_writer_output_uut (
		.clk(clk),
		.rst_n(rst_n),
		.pixels_per_frame(pixels_per_frame),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.start_write_in(start_write_wiener),
		.data_in(data_in),
		.wvalid(wvalid),
		.wlast(wlast),
		.start_write_out(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.frame_ready(frame_ready),
		.base_addr_out(base_addr)
	);
	
	memory_reader_output #(
		.DATA_WIDTH(DATA_WIDTH),
		.ADDR_WIDTH(ADDR_WIDTH)
	) memory_reader_output_uut (
		.clk(clk),
		.rst_n(rst_n),
		.frame_height(frame_height),
		.frame_width(frame_width),
		.frame_ready(frame_ready),
		.base_addr(base_addr),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst),
		.arready(arready),
		.rdata(rdata),
		.rvalid(rvalid),
		.m_axis_tdata(reader_data_in),
		.m_axis_tvalid(valid_in),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(last_in),
		.m_axis_tuser(user_in)
	);

	// AXI Stream Master
	AXI_stream_master #(
		.DATA_WIDTH(DATA_WIDTH)
	) axi_stream_master (
		.clk(clk),
		.rst_n(rst_n),
		.m_axis_tdata(m_axis_tdata),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tlast(m_axis_tlast),
		.m_axis_tuser(m_axis_tuser),
		.data_in(reader_data_in),
		.valid_in(valid_in),
		.last_in(last_in),
		.user_in(user_in) 
	);

	// AXI Stream Slave - for simulation (outside of TOP)
	AXI_stream_slave #(
		.DATA_WIDTH(DATA_WIDTH)
	) axi_stream_slave (
		.clk(clk),
		.rst_n(rst_n),
		.s_axis_tdata(s_axis_tdata),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready)
	);

	// Connect AXI Stream Master to AXI Stream Slave
	assign s_axis_tdata = m_axis_tdata;
	assign s_axis_tvalid = m_axis_tvalid;
	assign m_axis_tready = s_axis_tready;
	assign s_axis_tlast = m_axis_tlast;
	assign s_axis_tuser = m_axis_tuser;
	
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
		
		// Read Address Channel
		.araddr(araddr),
		.arlen(arlen),
		.arsize(arsize),
		.arburst(arburst),
		.arvalid(arvalid),
		.arready(arready),
		
		// Read Data Channel
		.rlast(rlast),
		.rvalid(rvalid),
		.rready(rready),
		
		// Control signals
		.start_write(start_write),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.start_read(start_read),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst)
		
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
	
	// 17.01.25 added the data of 4 blocks
	logic [7:0] data [0:255];
	assign data = {46,18,253,180,124,96,88,49,216,127,228,182,254,188,95,142,247,119,91,68,236,6,240,149,0,23,239,96,218,77,79,47,130,77,75,73,99,27,186,150,85,11,146,136,190,216,114,108,15,182,216,161,7,40,168,93,140,166,205,71,207,108,151,84,208,206,155,1,179,123,138,250,26,80,2,31,75,25,112,107,225,183,131,124,66,250,80,62,37,175,123,49,143,147,10,39,129,2,251,3,67,216,64,156,18,236,166,44,93,144,108,13,121,217,227,115,180,239,158,178,52,110,206,210,52,99,166,193,38,46,0,86,143,0,247,120,229,115,50,73,163,152,176,42,165,165,180,98,126,42,242,23,199,52,7,152,12,123,254,78,62,83,81,41,192,42,230,141,17,78,74,17,188,6,66,246,158,30,7,32,76,177,176,50,111,130,4,55,201,207,189,66,224,252,191,48,192,130,86,238,236,194,4,118,41,254,30,199,169,244,101,58,149,25,122,174,66,89,47,213,150,92,64,206,99,33,46,19,140,202,184,93,238,155,85,52,88,149,191,10,224,115,12,246,175,226,144,144,95,25,181,111,80,186,234,113};


	// Stimulus generation
	initial begin
		// Initialize inputs
		rst_n = 1'b0;
		data_in = 0;
		
		// Reset the system
		#20;
		rst_n = 1'b1;
		@(posedge clk);

		// Send a single transaction
		#10;
		// Send a multi-cycle transaction
		for(int frame=0; frame < frames_num; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin 
				if (i%BLOCK_SIZE == 0) begin
					start_write_wiener <= 1;
					#10;
					start_write_wiener <= 0;
					#40;
				end
				send_transaction(data[i]);
			end
			// End transaction
			@(posedge clk);
			data_in = 1'b0; 
		end
		#2700;
		$finish;
	end

	// Task to send a single transaction
	task send_transaction(input [DATA_WIDTH-1:0] data);
	begin
		@(posedge clk);
		data_in = data;
		#10;
	end
	endtask
	


endmodule
