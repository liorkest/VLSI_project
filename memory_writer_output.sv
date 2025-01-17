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
	input  logic [31:0]				   wiener_calc_data_count,
	input  logic                       start_write_in,
	input  logic [31:0]				   data_in,

	/*// AXI Stream slave interface
	input  logic [DATA_WIDTH-1:0]      s_axis_tdata, // Data signal
	input  logic                       s_axis_tvalid,// Valid signal        
	input  logic                       s_axis_tlast, // Last signal - end of line
	input  logic                       s_axis_tuser, // User custom signal - start of frame
	output logic   					   s_axis_tready,
	*/
	
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
logic [31:0] line_count;
logic [15:0] pixels_in_line_count;
assign frame_base_addr =  1 * pixels_per_frame * frame_count; // [LK 06.01.25] changer from (1 << write_size) to 1

logic [15:0] row_counter;
logic [15:0] col_counter;
logic [3:0] pixel_x;
logic [3:0] pixel_y;
logic [ADDR_WIDTH-1:0] curr_base_addr;
logic start_write_flag;
logic [ADDR_WIDTH-1:0] addr_holder;

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
				start_write_out <= 0;
				start_write_flag <= 0;
				write_addr <= 0;
				addr_holder <= 0;
				row_counter <= 0;
				col_counter <= 0;
				pixel_x <= 0;
				pixel_y <= 0;
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
					
					if (next_state == WRITE_HANDSHAKE) begin
						curr_base_addr <= frame_base_addr;
						write_addr <= frame_base_addr;
						if (!start_write_flag) begin
							start_write <= 1;
						end
					end
					
				end else if (state == WRITE_HANDSHAKE) begin
					if (start_write) begin
						start_write_flag <= 1;
						start_write <= 0;
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

					if (next_state == READ_HANDSHAKE) begin
						if (!start_read_flag) begin
							start_read <= 1;
						end 
						read_addr <= addr_holder;
					end else if (next_state == FRAME_READY) begin
						end_of_frame <= 1;
					end
					
				end else if (state == FRAME_READY) begin
					start_of_frame <= 0;
					start_data <= 0;
					
					if (wiener_calc_data_count == BLOCK_SIZE*BLOCK_SIZE) begin
						frame_ready_block_count <=  frame_ready_block_count + 1;
					end
					
					if (next_state == IDLE) begin
						frame_ready_for_output_reader <= 1;
						wiener_block_stats_en <= 0;
						wiener_calc_en <= wiener_block_stats_en;
					end
					end_of_frame <= 0;
				end
				
			end
		end


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
	next_state = state;  
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