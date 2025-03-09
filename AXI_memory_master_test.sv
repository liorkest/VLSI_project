/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_test1.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jul 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module AXI_memory_master_test2;

	// Parameters
	parameter ADDR_WIDTH = 32;
	parameter DATA_WIDTH = 32;
	parameter ID_WIDTH = 4;
	
	// Signals
	reg clk;
	reg resetn;
	
	// Write Address Channel
	wire [ID_WIDTH-1:0] awid;
	wire [ADDR_WIDTH-1:0] awaddr;
	wire [7:0] awlen;
	wire [2:0] awsize;
	wire [1:0] awburst;
	wire awvalid;
	reg awready;
	
	// Write Data Channel
	wire [DATA_WIDTH-1:0] wdata;
	wire [DATA_WIDTH/8-1:0] wstrb;
	wire wlast;
	wire wvalid;
	reg wready;
	
	// Write Response Channel
	reg [ID_WIDTH-1:0] bid;
	reg [1:0] bresp;
	reg bvalid;
	wire bready;
	
	// Read Address Channel
	wire [ID_WIDTH-1:0] arid;
	wire [ADDR_WIDTH-1:0] araddr;
	wire [7:0] arlen;
	wire [2:0] arsize;
	wire [1:0] arburst;
	wire arvalid;
	reg arready;
	
	// Read Data Channel
	reg [ID_WIDTH-1:0] rid;
	reg [DATA_WIDTH-1:0] rdata;
	reg [1:0] rresp;
	reg rlast;
	reg rvalid;
	wire rready;
	
	// Control signals
	reg start_write;
	reg [ID_WIDTH-1:0] write_id;
	reg [ADDR_WIDTH-1:0] write_addr;
	reg [7:0] write_len;
	reg [2:0] write_size;
	reg [1:0] write_burst;
	reg [DATA_WIDTH-1:0] write_data;
	reg [DATA_WIDTH/8-1:0] write_strb;
	reg start_read;
	reg [ID_WIDTH-1:0] read_id;
	reg [ADDR_WIDTH-1:0] read_addr;
	reg [7:0] read_len;
	reg [2:0] read_size;
	reg [1:0] read_burst;
	
	// Instantiate the DUT (Device Under Test)
	AXI_memory_master #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH)
	) dut (
		.clk(clk),
		.resetn(resetn),
	
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
	
		// Control signals
		.start_write(start_write),
		.write_id(write_id),
		.write_addr(write_addr),
		.write_len(write_len),
		.write_size(write_size),
		.write_burst(write_burst),
		.write_data(write_data),
		.write_strb(write_strb),
		.start_read(start_read),
		.read_id(read_id),
		.read_addr(read_addr),
		.read_len(read_len),
		.read_size(read_size),
		.read_burst(read_burst)
	);
	
	// memory for simulation to store data
	reg [31:0] memory [0:1024];
	
	// Clock Generation
	always #5 clk = ~clk; // 10ns clock period
	
	// Initial Block
	initial begin
		// Initialize signals
		clk = 0;
		resetn = 0;
		start_write = 0;
		start_read = 0;
		write_id = 0;
		write_addr = 0;
		write_len = 0;
		write_size = 0;
		write_burst = 0;
		write_data = 0;
		write_strb = 0;
		read_id = 0;
		read_addr = 0;
		read_len = 0;
		read_size = 0;
		read_burst = 0;
		
		// Apply reset
		#10;
		resetn = 1;
		#10;
		// Write Transaction
		AXI_memory_master_write(32'hDEADBEEF, 0);
		#20;
		// Read Transaction
		AXI_memory_master_read(0);
		#20;
		// Write Transaction
		AXI_memory_master_write(32'hBADC0DE1, 3);
		#20;
		// Write Transaction
		AXI_memory_master_write(32'hC0FFEE00, 1);
		#20;
		// Read Transaction
		AXI_memory_master_read(1);
		#20;
		// Read Transaction
		AXI_memory_master_read(3);
		// Write Transaction
		AXI_memory_master_write(32'hCAFEBABE, 0);
		#20;
		// Read Transaction
		AXI_memory_master_read(0);
		#20;
		// Finish simulation
		$finish;
	end
	
	// Task to send a single transaction
	task AXI_memory_master_read(input [ADDR_WIDTH-1:0] addr);
	begin
		start_read = 1;
		read_id = 4'b0001;
		read_addr = addr;
		read_len = 8'd0;
		read_size = 3'b010; // 4 bytes
		read_burst = 2'b01; // INCR
		wait(rvalid);
		start_read = 0;
	end
	endtask
	
	
	task AXI_memory_master_write(input [DATA_WIDTH-1:0] data, input [ADDR_WIDTH-1:0] addr);
	begin
		start_write = 1;
		write_id = 4'b0001;
		write_addr = addr;
		write_len = 8'd0;
		write_size = 3'b010; // 4 bytes
		write_burst = 2'b01; // INCR
		write_data = data;
		write_strb = 4'b1111;
		wait(wready);
		start_write = 0;
	end
	endtask
	
	
	// Monitor signals
	always @(posedge clk) begin
		if (awvalid && awready) begin
			$display("Write Address Channel: ID=%0d, Addr=%0h, Len=%0d, Size=%0d, Burst=%0d", awid, awaddr, awlen, awsize, awburst);
		end
		if (wvalid && wready) begin
			$display("Write Data Channel: Data=%0h, Strb=%0b, Last=%0b", wdata, wstrb, wlast);
		end
		if (bvalid && bready) begin
			$display("Write Response Channel: ID=%0d, Resp=%0d", bid, bresp);
		end
		if (arvalid && arready) begin
			$display("Read Address Channel: ID=%0d, Addr=%0h, Len=%0d, Size=%0d, Burst=%0d", arid, araddr, arlen, arsize, arburst);
		end
		if (rvalid && rready) begin
			$display("Read Data Channel: ID=%0d, Data=%0h, Resp=%0d, Last=%0b", rid, rdata, rresp, rlast);
		end
	end
	
	
	// AXI Slave Write Response Simulation
	always @(posedge clk) begin
		if (!resetn) begin
			awready <= 1'd0;
			wready <= 0;
			bvalid  <= 0;
		end else begin
			// Simulate awready
			if (awvalid && !awready ) begin
				awready  <= 1;
			end else begin
				awready <= 0;
			end

			// Simulate wready
			if (wvalid && !wready ) begin
				wready  <= 1;
				memory[awaddr[7:0]] <= wdata; // Save data to memory
			end else begin
				wready  <= 0;
			end

			// Simulate bvalid
			if (wready  && wvalid) begin
				bvalid <= 1;
			end else if (bready && bvalid) begin
				bvalid <= 0;
			end
		end
	end

	// AXI Slave Read Response Simulation
	always @(posedge clk) begin
		if (!resetn) begin
			arready <= 0;
			rvalid <= 0;
			rdata <= 0;
		end else begin
			// Simulate arready
			if (arvalid && !arready) begin
				arready <= 1;
			end else begin
				arready <= 0;
			end

			// Simulate rvalid and rdata
			if (arvalid && arready) begin
				rvalid <= 1;
				rdata <= memory[araddr[7:0]]; // Provide read data from memory
				rlast = 1;
			end else if (rready && rvalid) begin
				rvalid <= 0;
				rlast = 0;
			end
		end
	end

endmodule
