/*------------------------------------------------------------------------------
 * File          : memory_writer_output.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 13, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_writer_output #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter BLOCK_SIZE = 8
) (
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal
	input  logic [31:0]                pixels_per_frame, // max value allowed: 1280*720
	input  logic [15:0]                frame_height, // max value allowed <= 720
	input  logic [15:0]                frame_width, // max value allowed <= 1280
	input  logic                       start_write_in,
	input  logic [31:0]				   data_in,
	
	// from AXI_memory
	input  logic                     wvalid, 
	input  logic                     wlast,
	
	// to AXI_memory
	output  logic                    start_write_out,
	output  logic [ADDR_WIDTH-1:0]   write_addr,
	output  logic [31:0]             write_len,
	output  logic [2:0]              write_size,
	output  logic [1:0]              write_burst,
	output  logic [DATA_WIDTH-1:0]   write_data,
	output  logic [DATA_WIDTH/8-1:0] write_strb,
	
	output  logic frame_ready,
	output  logic [ADDR_WIDTH-1:0] base_addr_out
);

logic [1:0] frame_count; // 0,1,2 values
logic [31:0] frame_base_addr;
assign frame_base_addr = pixels_per_frame * frame_count; 
logic [15:0] row_counter;
logic [15:0] col_counter;
logic [3:0] pixel_x;
logic [3:0] pixel_y;
logic [ADDR_WIDTH-1:0] curr_base_addr;
logic start_write_flag;
logic [ADDR_WIDTH-1:0] addr_holder;
logic frame_ready_flag;

assign write_data = data_in;

// State machine for handling AXI Memory transactions
typedef enum logic [1:0] {
	IDLE,
	WRITE_HANDSHAKE,
	WRITE,
	FRAME_READY
} state_t;

state_t state, next_state;

// State machine logic
		always_ff @(posedge clk or negedge rst_n) begin
			if (!rst_n) begin
				state <= IDLE;
				frame_count <= 0;
				start_write_out <= 0;
				start_write_flag <= 0;
				base_addr_out <= 0;
				write_addr <= 0;
				addr_holder <= 0;
				row_counter <= 0;
				col_counter <= 0;
				pixel_x <= 0;
				pixel_y <= 0;
				frame_ready <= 0;
				frame_ready_flag <= 0;
			end else begin
				state <= next_state;
				
				if (state == IDLE) begin
					start_write_out <= 0;
					start_write_flag <= 0;
					write_addr <= 0;
					addr_holder <= 0;
					row_counter <= 0;
					col_counter <= 0;
					pixel_x <= 0;
					pixel_y <= 0;
					frame_ready <= 0;
					frame_ready_flag <= 0;
					
					if (next_state == WRITE_HANDSHAKE) begin
						curr_base_addr <= frame_base_addr;
						write_addr <= frame_base_addr;
						start_write_out <= 1;
						start_write_flag <= 1;
					end
					
				end else if (state == WRITE_HANDSHAKE) begin
					if (!start_write_flag) begin
						start_write_out <= 1;
						start_write_flag <= 1;
						end else begin
						start_write_out <= 0;
					end		
				
				end else if (state == WRITE) begin
					start_write_flag <= 0;
					
					if (row_counter < (frame_height >> $clog2(BLOCK_SIZE))) begin
						if (col_counter < (frame_width >> $clog2(BLOCK_SIZE))) begin
							if (pixel_y < BLOCK_SIZE - 1) begin
								if (pixel_x < BLOCK_SIZE - 1) begin
									pixel_x <= pixel_x + 1;
								end else begin
									pixel_x <= 0;
									pixel_y <= pixel_y + 1;
								end
							end else if (pixel_x == BLOCK_SIZE - 1) begin
									pixel_x <= 0;
									pixel_y <= 0;
									col_counter <= col_counter + 1;
							end else begin
								pixel_x <= pixel_x + 1;		
							end
							if (col_counter == (frame_width >> $clog2(BLOCK_SIZE)) - 1 && pixel_y == BLOCK_SIZE -1 && pixel_x == BLOCK_SIZE - 1) begin
								col_counter <= 0;
								row_counter <= row_counter + 1;
							end
						end 
						if (row_counter == (frame_height >> $clog2(BLOCK_SIZE)) - 1 && col_counter == (frame_width >> $clog2(BLOCK_SIZE)) - 1 
								&& pixel_y == BLOCK_SIZE -1 && pixel_x == BLOCK_SIZE - 1) begin
							col_counter <= 0;
							row_counter <= 0;
						end
					end
					if (pixel_x == BLOCK_SIZE - 2) begin
						if (pixel_y < BLOCK_SIZE - 1) begin
							addr_holder <= curr_base_addr + col_counter * BLOCK_SIZE + frame_width * row_counter * BLOCK_SIZE + frame_width * (pixel_y+1);
						end else if (col_counter < (frame_width >> $clog2(BLOCK_SIZE)) - 1) begin
							addr_holder <= curr_base_addr + (col_counter+1) * BLOCK_SIZE + frame_width * row_counter * BLOCK_SIZE;
						end else begin
							addr_holder <= curr_base_addr + frame_width * (row_counter+1) * BLOCK_SIZE;
						end
					end

					if (next_state == WRITE_HANDSHAKE) begin
						if (!start_write_flag) begin
							start_write_out <= 1;
						end 
						write_addr <= addr_holder;
					end else if (next_state == FRAME_READY) begin
						frame_ready <= 1;
					end
					
				end else if (state == FRAME_READY) begin
					if (frame_ready_flag) begin
						frame_ready <= 0;
					end else begin
						frame_ready_flag <= 1;
						frame_count <= frame_count + 1;
						if (frame_count == 2) begin
							frame_count <= 0;
						end 
					end
					base_addr_out <= curr_base_addr;
				end
				
			end
		end
		
always_comb begin
	next_state = state; 
	write_strb = 4'b1111;
	write_burst = 1;
	write_size = 2;
	write_len = BLOCK_SIZE;
	case (state)
		IDLE: begin
			write_len = 0; 
			write_burst = 0; 
			if (start_write_in) begin
				next_state = WRITE_HANDSHAKE;
			end
		end
			
		WRITE_HANDSHAKE: begin
			if (wvalid) begin
				next_state = WRITE;
			end
		end
		
		WRITE: begin
			if (wlast && (pixel_x == BLOCK_SIZE-1) && (pixel_y == BLOCK_SIZE-1) && (row_counter == (frame_height >> $clog2(BLOCK_SIZE))-1) 
					&& (col_counter == (frame_width >> $clog2(BLOCK_SIZE))-1)) begin
				next_state = FRAME_READY;
			end else if (wlast) begin
				next_state = WRITE_HANDSHAKE;
			end
		end
				
		FRAME_READY: begin
			if (frame_ready_flag) begin
				next_state = IDLE;
			end
		end
			
		default: next_state = IDLE;
	endcase
end

endmodule
