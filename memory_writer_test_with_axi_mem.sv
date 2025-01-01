/*------------------------------------------------------------------------------
 * File          : memory_writer_test_with_axi_mem.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 30, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_writer_with_axi_mem_tb;

	// Parameters
	parameter DATA_WIDTH = 32;
	parameter ADDR_WIDTH = 32;
	parameter ID_WIDTH = 4;
	parameter MEM_SIZE = 32;

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
	
	AXI_memory_master_burst #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) dut (
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
		.bid(bid),
		.bresp(bresp),
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
		.write_id(write_id),
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

	// Clock generation
	initial begin
		clk = 1'b0;
		forever #5 clk = ~clk; // 100MHz clock
	end
	
	// memory for simulation to store data
	reg [31:0] memory [0:MEM_SIZE];

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
		for(int frame=0; frame < 10; frame++) begin
			for(int i=0; i < pixels_per_frame; i++) begin 
				send_transaction((i+1)*100, (i%frame_width == frame_width-1) ,i==0); // Data: 0x12345678, Last: 0 // [LK 01.01.25 changed to (i+1)]
			end
			// End transaction
			s_axis_tuser = 1'b0;
			s_axis_tvalid = 1'b0;
			s_axis_tdata = 1'b0; // [LK 1.1.25] added
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
	
	// AXI Slave Write Simulation
	always @(posedge clk) begin
		if (!rst_n) begin
			awready <= 0;
			wready <= 0;
			bvalid <= 0;
		end else begin
			// Simulate awready
			if (awvalid && !awready) begin
				awready <= 1;
			end else begin
				awready <= 0;
			end

			// Keep wready constant during burst
			if (awvalid && awready) begin
				wready <= 1; // Constant wready during burst
			end else if (wlast) begin
				wready <= 0; // Deassert wready at the end of burst
			end

			// Simulate memory write
			if (wvalid && wready) begin
				memory[awaddr[7:0]] <= wdata;
			end

			// Simulate bvalid
			if (wvalid && wlast && wready) begin
				bvalid <= 1;
			end else if (bready && bvalid) begin
				bvalid <= 0;
			end
		end
	end
	
	/* [commented by LK 01.12.25]
	// AXI Slave Read Response Simulation
	always @(posedge clk) begin
		if (!rst_n) begin
			arready <= 0;
			rvalid <= 0;
			rdata <= 0;
			rlast <= 0;
			read_len <= 0;  // Make sure read_len is reset
		end else begin
			// Simulate arready
			if (arvalid && !arready) begin
				arready <= 1;
			end else begin
				arready <= 0;
			end

			// Simulate rvalid and rdata for burst mode
			if (arvalid && arready) begin
				rvalid <= 1;  // Keep rvalid high during the burst
			end else if (rready && rvalid && rlast) begin
				rvalid <= 0;  // Only deassert rvalid once the burst is finished
				rlast <= 0;   // Reset rlast
			end
			
			if (rvalid) begin			
				rdata <= memory[araddr[7:0]];  // Provide read data from memory
				// Set rlast to 1 when it's the last read in the burst
				rlast <= (read_len == 0);

				// Decrement the read length as the burst progresses
				if (read_len > 0) 
					read_len <= read_len - 1;
			end 
		end
	end
	*/

endmodule
