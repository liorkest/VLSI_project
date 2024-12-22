/*------------------------------------------------------------------------------
 * File          : memory_writer.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_writer #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
) (
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal
	input  logic [31:0]                pixels_per_frame, // max value allowed: 1280*720
	input  logic [15:0]                frame_height, // max value allowed <= 720
	input  logic [15:0]                frame_width, // max value allowed <= 1280

	// AXI Stream slave interface
	input  logic [DATA_WIDTH-1:0]      s_axis_tdata, // Data signal
	input  logic                       s_axis_tvalid,// Valid signal        
	input  logic                       s_axis_tlast, // Last signal - end of line
	input  logic                       s_axis_tuser, // User custom signal - start of frame
	output logic   					   s_axis_tready,
	
	// to AXI_memory
	output  logic                    start_write,
	output  logic [ADDR_WIDTH-1:0]   write_addr,
	output  logic [31:0]             write_len,
	output  logic [2:0]              write_size,
	output  logic [1:0]              write_burst,
	output  logic [DATA_WIDTH-1:0]   write_data,
	output  logic [DATA_WIDTH/8-1:0] write_strb,
	
	output  logic frame_ready,
	output  logic [ADDR_WIDTH-1:0] base_addr_out
);

logic [31:0] base_addr ;
logic [1:0] frame_count; // 0,1,2 values
logic [31:0] line_count;
logic [15:0] pixels_in_line_count;
assign base_addr = pixels_per_frame * frame_count;
logic s_axis_tready_logic;
// Instantiate the AXI_stream_slave module
assign s_axis_tready = s_axis_tready_logic;
AXI_stream_slave #(
	.DATA_WIDTH(DATA_WIDTH)
) uut (
	.clk(clk),
	.rst_n(rst_n),
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tvalid(s_axis_tvalid),
	.s_axis_tready(s_axis_tready_logic),
	.s_axis_tlast(s_axis_tlast),
	.s_axis_tuser(s_axis_tuser)
);


// State machine for handling AXI Stream transactions
typedef enum logic [1:0] {
	IDLE,
	RECEIVE,
	FRAME_READY
} state_t;

state_t state, next_state;

// State machine logic
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		line_count <= 0;
		frame_count <= 0;
		pixels_in_line_count <= 0;
		frame_ready <= 0;
		write_addr <= 0;
		base_addr_out <= 0;
	end else begin
		state <= next_state;
		if (state == IDLE) begin
			frame_ready <= 0;
			if(next_state == RECEIVE) begin // starting new frame
				write_addr <= base_addr;
			end
			
		end else if (state == RECEIVE) begin
			pixels_in_line_count <= pixels_in_line_count + 1;
			if (s_axis_tlast && line_count < frame_height) begin
				line_count <= line_count + 1;
			end 
			
			if (line_count == frame_height - 1 && frame_count == 3) begin
				frame_count <= 0;
			end
			if (s_axis_tlast) begin
				pixels_in_line_count <= 0;
			end
		end else if (state == FRAME_READY) begin
			frame_ready <= 1;
			base_addr_out <= base_addr;
			line_count <= 0;
			frame_count <= frame_count + 1;
		end
		
	end
end


always_comb begin
	next_state = state;
	start_write = 0;
	write_strb = 4'b1111;
	write_burst = 1;
	write_data = 0;
	write_size = 1;
	write_len = pixels_per_frame;
	case (state)
		IDLE: begin
			if (s_axis_tready_logic) begin
				next_state = RECEIVE;
				start_write = 1;
			end
		end

		RECEIVE: begin
			write_data = s_axis_tdata;
			if (!s_axis_tvalid && line_count == frame_height-1 && pixels_in_line_count == frame_width-1) begin
				next_state = FRAME_READY;
			end
		end
		
		FRAME_READY: begin
			next_state = IDLE;
		end

		default: next_state = IDLE;
	endcase
end





endmodule