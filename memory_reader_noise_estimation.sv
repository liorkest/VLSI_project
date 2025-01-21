/*------------------------------------------------------------------------------
 * File          : memory_reader_noise_estimation.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_reader_noise_estimation #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter BLOCK_SIZE = 8
) (
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal
	//input  logic [31:0]                pixels_per_frame, // max value allowed: 1280*720
	input  logic [15:0]                frame_height, // max value allowed <= 720
	input  logic [15:0]                frame_width, // max value allowed <= 1280
	//input  logic [31:0]                blocks_per_frame,
	input  logic 					   frame_ready,
	input  logic                   	   rvalid, //from AXI memory slave
	input  logic                       arready, //from AXI memory slave
	input  logic                       rlast, //from AXI memory slave
	input  logic [ADDR_WIDTH-1:0] 	   base_addr_in = 0, 
	input  logic 					   estimated_noise_ready,
	
	output  logic                    start_read,
	output  logic [ADDR_WIDTH-1:0]   read_addr,
	output  logic [31:0]             read_len,
	output  logic [2:0]              read_size,
	output  logic [1:0]              read_burst,
	output  logic [ADDR_WIDTH-1:0]   base_addr_out,
	output  logic                    noise_estimation_en,
	output  logic                    start_of_frame,
	output  logic                    start_data,
	output  logic                    frame_ready_for_wiener
);

logic [15:0] row_counter;
logic [15:0] col_counter;
logic [3:0] pixel_x;
logic [3:0] pixel_y;
logic [ADDR_WIDTH-1:0] curr_base_addr;
logic start_read_flag;
logic [ADDR_WIDTH-1:0] addr_holder;


// State machine for handling AXI Memory transactions
typedef enum logic [1:0] {
	IDLE,
	READ_HANDSHAKE,
	READ,
	FRAME_READY
} state_t;

state_t state, next_state;

// State machine logic
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
		start_read <= 0;
		start_read_flag <= 0;
		base_addr_out <= 0;
		noise_estimation_en <= 0;
		read_addr <= 0;
		addr_holder <= 0;
		frame_ready_for_wiener <= 0;
		row_counter <= 0;
		col_counter <= 0;
		pixel_x <= 0;
		pixel_y <= 0;
		start_of_frame <= 0;
		start_data <= 0;
	end else begin
		state <= next_state;
		
		if (state == IDLE) begin
			noise_estimation_en <= 0;
			read_addr <= 0;
			frame_ready_for_wiener <= 0;
			row_counter <= 0;
			col_counter <= 0;
			pixel_x <= 0;
			pixel_y <= 0;
			start_of_frame <= 0;
			start_data <= 0;
			
			if (next_state == READ_HANDSHAKE) begin
				curr_base_addr <= base_addr_in;
				read_addr <= base_addr_in;
				if (!start_read_flag) begin
					start_read <= 1;
				end
			end
			
		end else if (state == READ_HANDSHAKE) begin
			start_of_frame <= 0;
			start_data <= 0;
			if (start_read) begin
				start_read_flag <= 1;
				start_read <= 0;
			end
			noise_estimation_en <= 0; // [LS 06.01.25] noise estimation should be enabled only when state is READ
			
			if (next_state == READ) begin
				if (pixel_x == 0 && pixel_y == 0) begin
					start_data <= 1;
					noise_estimation_en <= 1; // [LS 06.01.25] noise estimation should be enabled only when state is READ
					if (row_counter == 0 && col_counter == 0) begin
						start_of_frame <= 1;
					end
				end
			end			
		
		end else if (state == READ) begin
			start_of_frame <= 0;
			start_data <= 0;
			start_read_flag <= 0;
			noise_estimation_en <= 1; // [LS 06.01.25] noise estimation should be enabled only when state is READ
			
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
			// -> [LS 06.01.25] because of the multiplication, need to calculate new address one cycle before update 
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
			end
			
		end else if (state == FRAME_READY) begin
			start_of_frame <= 0;
			start_data <= 0;
			base_addr_out <= curr_base_addr;
			if (next_state == IDLE) begin
				// base_addr_out <= curr_base_addr;
				frame_ready_for_wiener <= 1;
				noise_estimation_en <= 0;
			end
		end
		
	end
end

// [LK 08.01.25] changed noise_estimation_en to async signal
// assign noise_estimation_en = (state == READ) || start_of_frame; // [LS 12.01.25] Back to FSM

always_comb begin
	next_state = state;
	read_len = BLOCK_SIZE;
	read_size = 2;
	read_burst = 1;
	//start_of_frame = 0;
	case (state)
		IDLE: begin
			read_len = 0;
			read_burst = 0;
			if (frame_ready) begin
				next_state = READ_HANDSHAKE;
			end
		end

		READ_HANDSHAKE: begin
			//start_of_frame = arready && (pixel_x == 0) && (pixel_y == 0) && (row_counter == 0) && (col_counter == 0); //start_of_frame == 1 only before first pixel
			if (rvalid) begin
				next_state = READ;
			end
		end
		
		READ: begin
			if (rlast && (pixel_x == BLOCK_SIZE-1) && (pixel_y == BLOCK_SIZE-1) && (row_counter == (frame_height >> $clog2(BLOCK_SIZE))-1) 
					&& (col_counter == (frame_width >> $clog2(BLOCK_SIZE))-1)) begin
				next_state = FRAME_READY;
			end else if (rlast) begin
				next_state = READ_HANDSHAKE;
				
			end
		end
		
		FRAME_READY: begin
			if (estimated_noise_ready) begin
				next_state = IDLE;
			end
		end

		default: next_state = IDLE;
	endcase
end

endmodule