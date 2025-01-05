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
assign base_addr =  (1 << write_size) * pixels_per_frame * frame_count; 
logic s_axis_tready_logic;
logic tdata_shift_en; // [LK 01.01.25]
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

// Instantiate the shift register [LK 01.01.25]
shift_register#(
	.BYTE_WIDTH(32),
	.DEPTH(3)
) tdata_shift_reg (
	.clk(clk),
	.rst_n(rst_n),
	.serial_in(s_axis_tdata),
	.shift_en(tdata_shift_en),
	.serial_out(write_data)
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
			base_addr_out <= base_addr;
			write_addr <= base_addr;
			if(next_state == RECEIVE) begin // starting new frame
				pixels_in_line_count <= pixels_in_line_count + 1;
			end
			
		end else if (state == RECEIVE) begin
			pixels_in_line_count <= pixels_in_line_count + 1;
			if (s_axis_tlast && line_count < frame_height) begin
				line_count <= line_count + 1;
			end 
			
			if (s_axis_tlast) begin
				pixels_in_line_count <= 0;
			end
		end else if (state == FRAME_READY) begin
			frame_ready <= 1;
			line_count <= 0;
			pixels_in_line_count <= 0; // [LS 04.01.25]
			frame_count <= frame_count + 1;
			if (line_count == frame_height && frame_count == 2) begin
				frame_count <= 0;
			end
			
		end
		
	end
end


always_comb begin
	// next_state = state;  /// [LK 01.01.25 OMG it is wrong!]
	start_write = 0;
	write_strb = 4'b1111;
	write_burst = 1;
	// write_data = 0; commented out [LK 01.01.25]
	write_size = 2;
	write_len = pixels_per_frame;
	tdata_shift_en = 0;//[LK 01.01.25]
	case (state)
		IDLE: begin
			write_len = 0; // [LS 04.01.25] added so last pixel won't be written again in the next address
			write_burst = 0; // [LS 04.01.25] added so last pixel won't be written again in the next address
			if (s_axis_tready_logic) begin
				next_state = RECEIVE;
				start_write = 1;
				tdata_shift_en = 1;//[LK 01.01.25]
			end
		end

		RECEIVE: begin
			// write_data = s_axis_tdata; [removed LK 1.1.25]
			tdata_shift_en = 1;//[LK 01.01.25]
			
			/*              // [LK 01.01.25] changed because data is now at falling edge 
			if (!s_axis_tvalid && line_count == frame_height-1 && pixels_in_line_count == frame_width-1) begin
				next_state = FRAME_READY;
			end
			*/
			if (!s_axis_tvalid && line_count == frame_height) begin
				next_state = FRAME_READY;
			end
		end
		
		FRAME_READY: begin
			next_state = IDLE;
			tdata_shift_en = 1;//[LK 01.01.25]
		end

		default: next_state = IDLE;
	endcase
end


endmodule