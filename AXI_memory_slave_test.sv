/*------------------------------------------------------------------------------
 * File          : AXI_memory_slave_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 3, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module AXI_memory_slave_test;
// Parameters
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter ID_WIDTH = 4;
parameter MEM_SIZE = 32;

// Signals for AXI interface
logic clk;
logic rst_n;

// Write Address Channel
logic [ID_WIDTH-1:0]     awid;
logic [ADDR_WIDTH-1:0]   awaddr;
logic [7:0]              awlen;
logic [2:0]              awsize;
logic [1:0]              awburst;
logic                    awvalid;
logic                    awready;

// Write Data Channel
logic [DATA_WIDTH-1:0]   wdata;
logic [DATA_WIDTH/8-1:0] wstrb;
logic                    wlast;
logic                    wvalid;
logic                    wready;

// Write Response Channel
logic [ID_WIDTH-1:0]     bid;
logic [1:0]              bresp;
logic                    bvalid;
logic                    bready;

// Read Address Channel
logic [ID_WIDTH-1:0]     arid;
logic [ADDR_WIDTH-1:0]   araddr;
logic [7:0]              arlen;
logic [2:0]              arsize;
logic [1:0]              arburst;
logic                    arvalid;
logic                    arready;

// Read Data Channel
logic [ID_WIDTH-1:0]     rid;
logic [DATA_WIDTH-1:0]   rdata;
logic [1:0]              rresp;
logic                    rlast;
logic                    rvalid;
logic                    rready;

// Instantiate the AXI memory slave
AXI_memory_slave #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .ID_WIDTH(ID_WIDTH),
  .MEM_SIZE(MEM_SIZE)
) uut (
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
always begin
  #5 clk = ~clk; // 100 MHz clock
end

// Stimulus generation
initial begin
  // Initialize signals
  clk = 0;
  rst_n = 0;
  awid = 0;
  awaddr = 0;
  awlen = 0;
  awsize = 0;
  awburst = 0;
  awvalid = 0;
  wdata = 0;
  wstrb = 0;
  wlast = 0;
  wvalid = 0;
  bready = 1; // Ready for bresp
  arid = 0;
  araddr = 0;
  arlen = 0;
  arsize = 0;
  arburst = 0;
  arvalid = 0;
  rready = 1; // Ready for rdata

  // Apply reset
  #10;
  rst_n = 1;
  @(posedge clk);
  
  // Write burst sequence (Write to address 0, length 3)
  awid = 4'h1;
  awaddr = 32'h0;
  awlen = 8'h3;
  awsize = 3'b010;  // 32-bit words
  awburst = 2'b01;   // INCR burst
  awvalid = 1;

  // Wait for AW ready
  wait(awready);
  @(posedge clk);
  awvalid = 0;

  // Write data burst
  wdata = 32'hA5A5A5A5;
  wstrb = 4'b1111;  // Write all 4 bytes
  wvalid = 1;
  wlast = 0;

  #10;
  awaddr = awaddr + 1;
  wdata = 32'h5A5A5A5A;
  #10;

  awaddr = awaddr + 1;
  wdata = 32'h12345678;
  #10;

  wdata = 32'h87654321;
  awaddr = awaddr + 1;
  wlast <= 1;
  #10;
  wlast <= 0;
  // Wait for write response
  wait(bvalid);
  bready = 1;

  // Read burst sequence (Read from address 0, length 3)
  arid = 4'h1;
  araddr = 32'h0;
  arlen = 8'h3;
  arsize = 3'b010;  // 32-bit words
  arburst = 2'b01;   // INCR burst
  arvalid <= 1;

  // Wait for AR ready
  wait(arready);
  @(posedge clk);
  arvalid <= 0;

  // Wait and read data
  #10;
  wait(rvalid);
  $display("Read data: %h", rdata);

  araddr = araddr + 1;
  #10;
  wait(rvalid);
  $display("Read data: %h", rdata);

  araddr = araddr + 1;
  #10;
  wait(rvalid);
  $display("Read data: %h", rdata);
  
  araddr = araddr + 1;
  #10;
  wait(rvalid);
  $display("Read data: %h", rdata);

  // Finish simulation
  #20;
  $finish;
end

endmodule
