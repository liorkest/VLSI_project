/*------------------------------------------------------------------------------
 * File          : memory_reader_output.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 26, 2025
 * Description   : Memory Reader that reads frame pixel by pixel from AXI memory and sends it to AXI Stream Master
 *------------------------------------------------------------------------------
 */

module memory_reader_output #(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32
)(
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal
	input  logic [15:0]                frame_height, // Max value allowed <= 720
	input  logic [15:0]                frame_width,  // Max value allowed <= 1280
	input  logic                       frame_ready,  // Indicates the frame is ready in memory
	input  logic [ADDR_WIDTH-1:0]      base_addr,    // Starting address of the frame in memory

	// AXI Memory Master Interface
	output logic                       start_read,
	output logic [ADDR_WIDTH-1:0]      read_addr,
	output logic [31:0]                read_len,
	output logic [2:0]                 read_size,
	output logic [1:0]                 read_burst,
	input  logic                       arready,
	input  logic [DATA_WIDTH-1:0]      rdata,
	input  logic                       rvalid,
	//input  logic                       rlast,

	// AXI Stream Master Interface
	output logic [DATA_WIDTH-1:0]      m_axis_tdata,
	output logic                       m_axis_tvalid,
	input  logic                       m_axis_tready,
	output logic                       m_axis_tlast,
	output logic                       m_axis_tuser
);

// Internal signals
logic [31:0] current_pixel_count;
logic [15:0] current_line_count;
logic [ADDR_WIDTH-1:0] current_read_addr;
assign m_axis_tdata = (m_axis_tvalid) ? rdata : 0;

// State machine states
typedef enum logic [1:0] {
	IDLE,
	READ,
	STREAM
} state_t;

state_t state, next_state;

// State machine sequential logic
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		current_pixel_count <= 0;
		current_line_count <= 16'd0;
		current_read_addr <= 0;
	end else begin
		state <= next_state;
		
		if (state == IDLE) begin
			current_pixel_count <= 0;
			current_line_count <= 16'd0;
			if (next_state == READ) begin
				current_read_addr <= base_addr;
			end
		end
		
		if (state == STREAM) begin
			if( rvalid && m_axis_tready) begin
				current_pixel_count <= current_pixel_count + 1;
				if (current_pixel_count == frame_width - 1) begin
					current_pixel_count <= 0;
					current_line_count <= current_line_count + 16'd1;
				end
			end
		end
	end
end

// State machine combinational logic
always_comb begin
	next_state = state;
	start_read = 1'b0;
	read_addr = current_read_addr;
	read_len = frame_height * frame_width;
	read_size = 3'b010; 
	read_burst = 2'b01;
	m_axis_tvalid = 1'b0;
	m_axis_tlast = 1'b0;
	m_axis_tuser = 1'b0;

	case (state)
		IDLE: begin
			if (frame_ready) begin
				next_state = READ;
				start_read = 1'b1;
			end
		end

		READ: begin
			if (arready) begin
				next_state = STREAM;
			end
		end

		STREAM: begin
			if (rvalid) begin
				m_axis_tvalid = 1'b1;
				m_axis_tuser = (current_pixel_count == 0 && current_line_count == 0); // Start of frame
				m_axis_tlast = (current_pixel_count == frame_width - 1); // End of line

				if (current_pixel_count == frame_width-1 && current_line_count == frame_height-1) begin
					next_state = IDLE;
				end
			end
		end

		default: next_state = IDLE;
	endcase
end

endmodule
