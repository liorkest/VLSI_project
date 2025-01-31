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
parameter DATA_WIDTH = 32;

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
logic [3:0]              write_addr;
logic [31:0]             write_data;
logic                    write_en;

logic [3:0]              read_addr;
logic [31:0]             read_data;

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
register_file reg_file (
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

// Reset task
task reset();
  begin
	resetn = 0;
	#20;
	resetn = 1;
  end
endtask

// Testbench procedure
initial begin
  // Initialize signals
  clk = 0;
  awaddr = 0;
  awvalid = 0;
  wdata = 0;
  wstrb = 0;
  wvalid = 0;
  bready = 0;
  araddr = 0;
  arvalid = 0;
  rready = 0;

  // Apply reset
  reset();

  // Write operation
  @(negedge clk);
  awaddr = 4'h3;
  awvalid = 1;
  @(negedge clk);
  wdata = 32'hA5A5A5A5;
  wstrb = 4'b1111;
  wvalid = 1;
  @(posedge awready);
  awvalid = 0;
  @(posedge wready);
  wvalid = 0;
  @(negedge clk);
  bready = 1;
  @(posedge bvalid);
  @(negedge clk);
  bready = 0;

  // Read operation
  @(negedge clk);
  araddr = 4'h3;
  arvalid = 1;
  @(posedge arready);
  arvalid = 0;
  @(posedge rvalid);
  rready = 1;
  @(negedge clk);
  rready = 0;

  // Finish simulation
  #100;
  $finish;
end

endmodule
