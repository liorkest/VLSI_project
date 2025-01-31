/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_burst_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   : Testbench for AXI Memory Master with Burst Support
 *------------------------------------------------------------------------------*/

module AXI_memory_master_burst_test_LK;

// Parameters
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter ID_WIDTH = 4;
parameter MEM_SIZE = 128;

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
reg [31:0] write_len;
reg [2:0] write_size;
reg [1:0] write_burst;
reg [DATA_WIDTH-1:0] write_data;
reg [DATA_WIDTH/8-1:0] write_strb;
reg start_read;
reg [ID_WIDTH-1:0] read_id;
reg [ADDR_WIDTH-1:0] read_addr;
reg [31:0] read_len;
reg [2:0] read_size;
reg [1:0] read_burst;
reg [31:0] read_data_count; // [LK 01.01.25]

// Instantiate the DUT (Device Under Test)
AXI_memory_master_burst #(
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
	//.bid(bid),
	//.bresp(bresp),
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
	//.rid(rid),
	//.rdata(rdata),
	//.rresp(rresp),
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
reg [31:0] memory [0:MEM_SIZE];

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
	@(posedge clk);
	// Burst Write Transaction
	AXI_memory_master_write_burst(4'hA, 32'h0, 8, 3'b010, 2'b01);
	#20;
	// Burst Read Transaction
	AXI_memory_master_read_burst(4'hA, 32'h0, 8, 3'b010, 2'b01);
	#200;
	// Finish simulation
	$finish;
end

// Task to send burst read transactions
task AXI_memory_master_read_burst(
	input [ID_WIDTH-1:0] id,
	input [ADDR_WIDTH-1:0] addr,
	input [7:0] len,
	input [2:0] size,
	input [1:0] burst
);
integer i;
begin
	start_read = 1;
	read_id = id;
	read_addr = addr;
	read_len = len; // [LK 01.01.25] 
	read_size = size;
	read_burst = burst;
	wait(arready);
	start_read = 0;
	for (i = 0; i <= len; i = i + 1) begin
		rlast = (i==len) ;		// [LK 01.01.25] this is the fix of rlast:

		wait(rvalid);
		$display("Read Data: %h", rdata);
		/*if (rlast) begin // [LK 01.01.25] this is wrong!!! it should come from TB to dut!
			break;
		end*/
		#10;
	end
	rlast = 0;
end
endtask

// Task to send burst write transactions
task AXI_memory_master_write_burst(
	input [ID_WIDTH-1:0] id,
	input [ADDR_WIDTH-1:0] addr,
	input [7:0] len,
	input [2:0] size,
	input [1:0] burst
);
integer i;
begin
	start_write = 1;
	write_id = id;
	write_addr = addr;
	write_len = len - 1;
	write_size = size;
	write_burst = burst;
	#35; // [LK 01.01.25] changed fro 40 to 35
	for (i = 0; i < len; i = i + 1) begin
		write_data = 10 + i; // [LK 01.01.25 changed to be more readable]
		write_strb = 4'b1111;
		#10;
		start_write = 0;
		//wait(wready);
	end
	start_write = 0;
end
endtask


// AXI Slave Write Response Simulation
always @(posedge clk) begin
	if (!resetn) begin
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

// AXI Slave Read Response Simulation
always @(posedge clk) begin
	if (!resetn) begin
		arready <= 0;
		rvalid <= 0;
		rdata <= 0;
		read_len <= 0;  // Make sure read_len is reset
		read_data_count <= 0; // [LK 01.01.24]
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
			// rlast <= 0;   // Reset rlast
			read_data_count <= 0; // [LK 01.01.24]
		end
		
		if (rvalid) begin			
			rdata <= memory[araddr[7:0]];  // Provide read data from memory
			read_data_count <= read_data_count + 1; // [LK 01.01.24]
			// Set rlast to 1 when it's the last read in the burst
			//rlast <= (read_len == 0); [LK 01.01.24]
			
			/* [LK 01.01.24] remove this -> is stopped the read operation. 
			// Decrement the read length as the burst progresses
			if (read_len > 0) 
				read_len <= read_len - 1;
				*/
		end 
	end
end

endmodule