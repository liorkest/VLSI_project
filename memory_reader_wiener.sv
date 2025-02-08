/*------------------------------------------------------------------------------
 * File          : memory_reader_wiener.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 5, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_reader_wiener #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter BLOCK_SIZE = 8
) (
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal
	input  logic [15:0]                frame_height, // max value allowed <= 720
	input  logic [15:0]                frame_width, // max value allowed <= 1280
	input  logic 					   estimated_noise_ready,
	input  logic                   	   rvalid, //from AXI memory slave
	// input  logic                       arready, //from AXI memory slave // [LS 31.01.25] removing - not used
	input  logic                       rlast, //from AXI memory slave
	input  logic [ADDR_WIDTH-1:0] 	   base_addr_in,
	input  logic [31:0]            	   wiener_calc_data_count,
	
	output  logic                    start_read,
	output  logic [ADDR_WIDTH-1:0]   read_addr,
	output  logic [31:0]             read_len,
	output  logic [2:0]              read_size,
	output  logic [1:0]              read_burst,
	output  logic                    wiener_block_stats_en,
	output  logic                    wiener_calc_en,
	output  logic                    start_of_frame,
	output  logic                    start_data,
	output  logic					 end_of_frame, // [LK 09.01.25] added for clarity - will assert pulse when finished reading frame
	// output  logic					 frame_ready_for_output_reader,
	output  logic                    start_write
);

logic [15:0] row_counter;
logic [15:0] col_counter;
logic [3:0] pixel_x;
logic [3:0] pixel_y;
logic [ADDR_WIDTH-1:0] curr_base_addr;
logic start_read_flag;
logic [ADDR_WIDTH-1:0] addr_holder;
logic [1:0] frame_ready_block_count;
logic [7:0] start_write_counter;


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
		start_read <= 1'd0;
		start_read_flag <= 1'd0;
		wiener_block_stats_en <= 1'd0;
		wiener_calc_en <= 1'd0;
		read_addr <= 0;
		addr_holder <= 0;
		// frame_ready_for_output_reader <= 0;
		row_counter <= 16'd0;
		col_counter <= 16'd0;
		pixel_x <= 4'd0;
		pixel_y <= 4'd0;
		start_of_frame <= 1'd0;
		end_of_frame <= 1'd0;
		start_data <= 1'd0;
		frame_ready_block_count <= 2'd0;
		curr_base_addr <= 0;

	end else begin
		state <= next_state;
		
		if (state == IDLE) begin
			wiener_block_stats_en <= 1'd0;
			wiener_calc_en <= wiener_block_stats_en;
			read_addr <= 0;
			row_counter <= 16'd0;
			col_counter <= 16'd0;
			pixel_x <= 4'd0;
			pixel_y <= 4'd0;
			start_of_frame <= 1'd0;
			end_of_frame <= 1'd0;
			start_data <= 1'd0;
			frame_ready_block_count <= 2'd0;
			// frame_ready_for_output_reader <= 0;
			
			if (next_state == READ_HANDSHAKE) begin
				curr_base_addr <= base_addr_in;
				read_addr <= base_addr_in;
				if (!start_read_flag) begin
					start_read <= 1'd1;
				end
			end
			
		end else if (state == READ_HANDSHAKE) begin
			start_of_frame <= 1'd0;
			start_data <= 1'd0;
			if (start_read) begin
				start_read_flag <= 1'd1;
				start_read <= 1'd0;
			end	
			wiener_block_stats_en <= 1'd0;
			wiener_calc_en <= wiener_block_stats_en;
			
			if (next_state == READ) begin
				if (pixel_x == 0 && pixel_y == 0) begin
					start_data <= 1'd1;
					wiener_block_stats_en <= 1'd1;
					wiener_calc_en <= wiener_block_stats_en;
					if (row_counter == 0 && col_counter == 0) begin
						start_of_frame <= 1'd1;
					end
				end
			end	
		
		end else if (state == READ) begin
			start_of_frame <= 1'd0;
			start_data <= 1'd0;
			start_read_flag <= 1'd0;
			wiener_block_stats_en <= 1'd1;
			wiener_calc_en <= wiener_block_stats_en;
			
			if (row_counter < (frame_height >> $clog2(BLOCK_SIZE))) begin
				if (col_counter < (frame_width >> $clog2(BLOCK_SIZE))) begin
					if (pixel_y < BLOCK_SIZE - 1) begin
						if (pixel_x < BLOCK_SIZE - 1) begin
							pixel_x <= pixel_x + 4'd1;
						end else begin
							pixel_x <= 4'd0;
							pixel_y <= pixel_y + 4'd1;
						end
					end else if (pixel_x == BLOCK_SIZE - 1) begin
							pixel_x <= 4'd0;
							pixel_y <= 4'd0;
							col_counter <= col_counter + 16'd1;
					end else begin
						pixel_x <= pixel_x + 4'd1;		
					end
					if (col_counter == (frame_width >> $clog2(BLOCK_SIZE)) - 1 && pixel_y == BLOCK_SIZE -1 && pixel_x == BLOCK_SIZE - 1) begin
						col_counter <= 16'd0;
						row_counter <= row_counter + 16'd1;
					end
				end 
				if (row_counter == (frame_height >> $clog2(BLOCK_SIZE)) - 1 && col_counter == (frame_width >> $clog2(BLOCK_SIZE)) - 1 
						&& pixel_y == BLOCK_SIZE -1 && pixel_x == BLOCK_SIZE - 1) begin
					col_counter <= 16'd0;
					row_counter <= 16'd0;
				end
			end
			if (pixel_x == BLOCK_SIZE - 2) begin
				if (pixel_y < BLOCK_SIZE - 1) begin
					addr_holder <= curr_base_addr + col_counter * BLOCK_SIZE + frame_width * row_counter * BLOCK_SIZE + frame_width * (pixel_y+4'd1);
				end else if (col_counter < (frame_width << $clog2(BLOCK_SIZE)) - 1) begin
					addr_holder <= curr_base_addr + (col_counter+1) * BLOCK_SIZE + frame_width * row_counter * BLOCK_SIZE;
				end else begin
					addr_holder <= curr_base_addr + frame_width * (row_counter+16'd1) * BLOCK_SIZE;
				end
			end

			if (next_state == READ_HANDSHAKE) begin
				if (!start_read_flag) begin
					start_read <= 1'd1;
				end 
				read_addr <= addr_holder;
			end else if (next_state == FRAME_READY) begin
				end_of_frame <= 1'd1;
			end
			
		end else if (state == FRAME_READY) begin
			start_of_frame <= 1'd0;
			start_data <= 1'd0;
			
			if (wiener_calc_data_count == BLOCK_SIZE*BLOCK_SIZE) begin
				frame_ready_block_count <=  frame_ready_block_count + 2'd1;
			end
			
			if (next_state == IDLE) begin
				// frame_ready_for_output_reader <= 1;
				wiener_block_stats_en <= 1'd0;
				wiener_calc_en <= wiener_block_stats_en;
			end
			end_of_frame <= 1'd0;
		end
		
	end
end

// [LK 08.01.25] changed noise_estimation_en to async signal
// assign noise_estimation_en = (state == READ) || start_of_frame; // [LS 12.01.25] Back to FSM

always_comb begin
	next_state = state;
	read_len = BLOCK_SIZE;
	read_size = 3'd2;
	read_burst = 2'd1;
	// start_of_frame = 0;
	// end_of_frame = 0;
	case (state)
		IDLE: begin
			read_len = 0;
			read_burst = 2'd0;
			if (estimated_noise_ready) begin
				next_state = READ_HANDSHAKE;
			end
		end

		READ_HANDSHAKE: begin
			// start_of_frame = arready && (pixel_x == 0) && (pixel_y == 0) && (row_counter == 0) && (col_counter == 0); //start_of_frame == 1 only before first pixel
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
			if (frame_ready_block_count == 3) begin
				next_state = IDLE;
			end
		end
		

		default: next_state = IDLE;
	endcase
end

// [LS 12.01.12] - For the output memory master
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		start_write <= 1'd0;
		start_write_counter <= 8'd0;
	end else if (wiener_calc_data_count == 0 || wiener_calc_data_count == BLOCK_SIZE || wiener_calc_data_count == 2*BLOCK_SIZE || wiener_calc_data_count == 3*BLOCK_SIZE || 
			wiener_calc_data_count == 4*BLOCK_SIZE || wiener_calc_data_count == 5*BLOCK_SIZE || wiener_calc_data_count == 6*BLOCK_SIZE || wiener_calc_data_count == 7*BLOCK_SIZE ||
			wiener_calc_data_count == 8*BLOCK_SIZE) begin
		if (start_write_counter == 0) begin
			start_write <= 1'd1;
			start_write_counter <= start_write_counter + 8'd1;
		end else begin
			start_write <= 1'd0;
			start_write_counter <= start_write_counter + 8'd1;
		end	
	end else begin
		start_write <= 1'd0;
		start_write_counter <= 8'd0;
	end
end

endmodule
