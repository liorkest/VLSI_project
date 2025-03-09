/*------------------------------------------------------------------------------
 * File          : AXI_memory_master_burst_write_only_tb.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   : AXI Memory Master with Burst Support
 *------------------------------------------------------------------------------*/

module AXI_memory_master_burst_write_only_tb;

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 10;

logic clk;
logic resetn;

// AXI Signals
logic [ADDR_WIDTH-1:0] awaddr;
logic [31:0] awlen;
logic [2:0] awsize;
logic [1:0] awburst;
logic awvalid;
logic awready;

logic [DATA_WIDTH-1:0] wdata;
logic wlast;
logic wvalid;
logic wready;

logic bvalid;
logic bready;

// Control Signals
logic start_write;
logic [ADDR_WIDTH-1:0] write_addr;
logic [31:0] write_len;
logic [2:0] write_size;
logic [1:0] write_burst;
logic [DATA_WIDTH-1:0] write_data;

// DUT Instantiation
AXI_memory_master_burst_write_only #(
  .ADDR_WIDTH(ADDR_WIDTH),
  .DATA_WIDTH(DATA_WIDTH)
) dut (
  .clk(clk),
  .resetn(resetn),
  .awaddr(awaddr),
  .awlen(awlen),
  .awsize(awsize),
  .awburst(awburst),
  .awvalid(awvalid),
  .awready(awready),
  .wdata(wdata),
  .wlast(wlast),
  .wvalid(wvalid),
  .wready(wready),
  .bvalid(bvalid),
  .bready(bready),
  .start_write(start_write),
  .write_addr(write_addr),
  .write_len(write_len),
  .write_size(write_size),
  .write_burst(write_burst),
  .write_data(write_data)
);

// Clock Generation
always #(CLK_PERIOD/2) clk = ~clk;

// Test Sequence
initial begin
  clk = 0;
  resetn = 0;
  start_write = 0;
  awready = 1;
  wready = 1;
  bvalid = 0;

  #20;
  resetn = 1;

  // First burst transaction (8 data points)
  write_addr = 32'h1000;
  write_len = 8;
  write_size = 3'b010; // 4 bytes per transfer
  write_burst = 2'b01; // Incrementing burst
  write_data = 32'hA5A5A5A5;
  start_write = 1;

  #10;
  start_write = 0;

  // Wait for transaction completion
  wait (bvalid);
  #10;
  bvalid = 0;

  // Second burst transaction (8 data points)
  write_addr = 32'h2000;
  write_len = 8;
  write_size = 3'b010;
  write_burst = 2'b01;
  write_data = 32'h5A5A5A5A;
  start_write = 1;

  #10;
  start_write = 0;

  // Wait for transaction completion
  wait (bvalid);
  #10;
  bvalid = 0;

  #50;
  $finish;
end

// AXI Response Simulation
always @(posedge clk) begin
  if (awvalid && awready) begin
	$display("AWADDR: %h, AWLEN: %d", awaddr, awlen);
  end
  if (wvalid && wready) begin
	$display("WDATA: %h, WLAST: %b", wdata, wlast);
  end
  if (wlast) begin
	bvalid <= 1;
  end
end


endmodule
