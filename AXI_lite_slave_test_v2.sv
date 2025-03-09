/*------------------------------------------------------------------------------
 * File          : AXI_lite_slave_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Aug 13, 2024
 * Description   : 
 *------------------------------------------------------------------------------*/

module AXI_lite_slave_test;

// Parameters
parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter MEM_SIZE = 2;

// Clock and reset signals
logic clk;
logic resetn;

// AXI Lite Interface signals
logic [ADDR_WIDTH-1:0]   awaddr;
logic                    awvalid;
logic                    awready;

logic [DATA_WIDTH-1:0]   wdata;
logic [DATA_WIDTH/8-1:0] wstrb;
logic                    wvalid;
logic                    wready;

logic [1:0]              bresp;
logic                    bvalid;
logic                    bready;

logic [ADDR_WIDTH-1:0]   araddr;
logic                    arvalid;
logic                    arready;

logic [DATA_WIDTH-1:0]   rdata;
logic [1:0]              rresp;
logic                    rvalid;
logic                    rready;

// Register file Interface signals
logic [ADDR_WIDTH-1:0]   write_addr;
logic [DATA_WIDTH-1:0]   write_data;
logic                    write_en;

logic [ADDR_WIDTH-1:0]   read_addr;
logic [DATA_WIDTH-1:0]   read_data;

// Instantiate the AXI_lite_slave
AXI_lite_slave #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
) dut (
  .clk(clk),
  .resetn(resetn),
  .awaddr(awaddr),
  .awvalid(awvalid),
  .awready(awready),
  .wdata(wdata),
  .wstrb(wstrb),
  .wvalid(wvalid),
  .wready(wready),
  .bresp(bresp),
  .bvalid(bvalid),
  .bready(bready),
  .araddr(araddr),
  .arvalid(arvalid),
  .arready(arready),
  .rdata(rdata),
  .rresp(rresp),
  .rvalid(rvalid),
  .rready(rready),
  .write_addr(write_addr),
  .write_data(write_data),
  .write_en(write_en),
  .read_addr(read_addr),
  .read_data(read_data)
);

// Instantiate the register_file
register_file #(
	.ADDR_WIDTH(ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH),
	.MEM_SIZE(MEM_SIZE)
) reg_file (
  .clk(clk),
  .resetn(resetn),
  .write_addr(write_addr),
  .write_data(write_data),
  .write_en(write_en),
  .read_addr(read_addr),
  .read_data(read_data),
  .res_x(),
  .res_y()
  //.fps()
);

// Clock generation
always #5 clk = ~clk;
// Task for AXI Lite Write Transaction
task write_transaction(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
	begin
		@(negedge clk);
		// Send address
		awaddr = addr;
		awvalid = 1;
		// Wait for address handshake
		wait (awready);
		#10;

		// Send data
		wdata = data;
		wvalid = 1;
		wstrb = 1'b1; // Ensure strobe is active
		// Wait for data handshake
		wait (wready);
		awvalid = 0;
		#10;
		// Wait for write response
		wait (bvalid);
		wvalid = 0;
		bready = 1;
		#20;
		bready = 0;
	end
endtask

// Task for AXI Lite Read Transaction
task read_transaction(input [ADDR_WIDTH-1:0] addr);
	begin
		@(negedge clk);
		araddr = addr;
		arvalid = 1;
		
		// Wait for address handshake
		wait (arready);
		#10;

		
		// Wait for read data valid
		wait (rvalid);
		arvalid = 0;
		rready = 1;
		#20;
		rready = 0;
	end
endtask

initial begin
	// Initialize signals
	clk = 0;
	resetn = 0;
	awaddr = 0;
	awvalid = 0;
	wdata = 0;
	wstrb = 1'b0;
	wvalid = 0;
	bready = 0;
	araddr = 0;
	arvalid = 0;
	rready = 0;
	
	// Reset sequence
	@(posedge clk);
	#20;
	resetn = 1;
	
	// Perform transactions
	#10; write_transaction(32'h0, 32'd1280);
	#10; write_transaction(32'h1, 32'd720);
	#10; read_transaction(32'h0);
	#10; read_transaction(32'h1);
	
	// End of test
	#50;
	$finish;
end
endmodule


