/*------------------------------------------------------------------------------
 * File          : AXI_lite_slave.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jul 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
module AXI_lite_slave #(
	parameter ADDR_WIDTH = 4,
	parameter DATA_WIDTH = 32
)(
	input  wire                    clk,
	input  wire                    resetn,

	// Write Address Channel
	input  wire [ADDR_WIDTH-1:0]   awaddr,
	input  wire                    awvalid,
	output wire                    awready,

	// Write Data Channel
	input  wire [DATA_WIDTH-1:0]   wdata,
	input  wire  wstrb,
	input  wire                    wvalid,
	output wire                    wready,

	// Write Response Channel
	output wire               bresp,
	output wire                    bvalid,
	input  wire                    bready,

	// Read Address Channel
	input  wire [ADDR_WIDTH-1:0]   araddr,
	input  wire                    arvalid,
	output wire                    arready,

	// Read Data Channel
	output wire [DATA_WIDTH-1:0]   rdata,
	output wire              rresp,
	output wire                    rvalid,
	input  wire                    rready,
	
	// register file read/write channel
	output  logic [ADDR_WIDTH-1:0]  write_addr,  
	output  logic [DATA_WIDTH-1:0] write_data,  // 32-bit write data
	output  logic        write_en,    // Write enable
	
	output  logic [ADDR_WIDTH-1:0]  read_addr,   
	input logic [DATA_WIDTH-1:0] read_data    // 32-bit read data
);

	// Write State Machine
	typedef enum logic [1:0] {
		WRITE_IDLE,
		WRITE_ADDR,
		WRITE_DATA,
		WRITE_RESP
	} write_state_t;

	write_state_t write_state, write_state_next;

	// Read State Machine
	typedef enum logic [1:0] {
		READ_IDLE,
		READ_ADDR,
		READ_DATA
	} read_state_t;

	read_state_t read_state, read_state_next;


	// Write State Machine - Sequential Logic
	always_ff @(posedge clk or negedge resetn) begin
		if (!resetn)
			write_state <= WRITE_IDLE;
		else
			write_state <= write_state_next;
	end

	// Write State Machine - Combinational Logic
	always_comb begin
		write_state_next = write_state;
		case (write_state)
			WRITE_IDLE: begin
				if (awvalid)
					write_state_next = WRITE_ADDR;
			end
			WRITE_ADDR: begin
				if (awvalid && awready)
					write_state_next = WRITE_DATA;
			end
			WRITE_DATA: begin
				if (wvalid && wready)
					write_state_next = WRITE_RESP;
			end
			WRITE_RESP: begin
				if (bvalid && bready)
					write_state_next = WRITE_IDLE;
			end
		endcase
	end

	// Write Address Channel
	assign awready = (write_state == WRITE_ADDR);

	// Write Data Channel
	always_ff @(posedge clk or negedge resetn) begin
		if (!resetn) begin
			// Reset logic
			write_addr <= 0;
			write_en<= 0;
					write_data<= 0;
		end else if (write_state == WRITE_DATA && wvalid && wready && wstrb != '0) begin
			// Write to register file
				write_en <= 1'b1;
				write_addr <= awaddr[ADDR_WIDTH-1:0];
				write_data <= wdata;		
		end
	end

	assign wready = (write_state == WRITE_DATA);

	// Write Response Channel
	assign bresp = 0; // OKAY response
	assign bvalid = (write_state == WRITE_RESP);

	// Read State Machine - Sequential Logic
	always_ff @(posedge clk or negedge resetn) begin
		if (!resetn)
			read_state <= READ_IDLE;
		else
			read_state <= read_state_next;
	end

	// Read State Machine - Combinational Logic
	always_comb begin
		read_state_next = read_state;
		read_addr=0;
		case (read_state)
			READ_IDLE: begin
				read_addr=0;
				if (arvalid)
					read_state_next = READ_ADDR;
			end
			READ_ADDR: begin
				read_addr=0;
				if (arvalid && arready)
					read_state_next = READ_DATA;
			end
			READ_DATA: begin
				read_addr = araddr[ADDR_WIDTH-1:0];
				if (rvalid && rready)
					read_state_next = READ_IDLE;
			end
		endcase
	end

	// Read Address Channel
	assign arready = (read_state == READ_ADDR);

	// Read Data Channel
	assign rvalid = (read_state == READ_DATA);
	assign rdata = read_data;
	assign rresp = 0;

endmodule

