/*------------------------------------------------------------------------------
 * File          : wiener_block_stats_FSM.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/


module wiener_block_stats_FSM #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples per block (MUST be power of 2)
)(
	input logic                   clk,
	input logic                   rst_n,
	input logic                   start_of_frame, 
	// input logic                   end_of_frame, // [LS 31.01.25] removing - never used
	input logic                   mean_ready, 
	input logic                   variance_ready,
	input logic [31:0]            blocks_per_frame,
	// outputs
	output logic                   shift_en_1,
	output logic                   shift_en_2,
	output logic                   shift_en_mean,
	output logic                   shift_reg_rst_n,
	output logic                   variance_start_of_data
);

logic [31:0] count;
logic [31:0] block_count;
logic updated_block_count;
logic [1:0] mean_ready_counter;
logic variance_ready_flag; // [19.12.24 LK added]

typedef enum logic [2:0] {
	IDLE = 0,
	READ_BLOCK = 1,
	WAIT_FOR_MEAN = 2,
	EMPTY_BUFFER = 3
 } state_t;

state_t state, next_state;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state <= IDLE;
	end else begin
		state <= next_state;
	end
end

always_comb begin
	// default
	shift_en_1  = 0;
	shift_en_2  = 0;
	shift_reg_rst_n = 1;
	case (state) 
		IDLE: begin
			if (start_of_frame) begin
				next_state = READ_BLOCK;
				shift_reg_rst_n = 1;
				shift_en_1 = 1;
				shift_en_2 = 1;
			end else begin
				next_state = IDLE;
				shift_reg_rst_n = 0;
			end
		end
		READ_BLOCK: begin
			if (count == TOTAL_SAMPLES) begin
				next_state = WAIT_FOR_MEAN;
			end else begin
				shift_en_1 = 1; // output
				shift_en_2 = 1;
				next_state = READ_BLOCK;
			end
		end
		WAIT_FOR_MEAN: begin
			if (block_count == blocks_per_frame + 1) begin // refers to FULL BLOCKS number and NOT pixels(data)
				next_state = EMPTY_BUFFER;
			end else if (mean_ready_counter == 2) begin
				next_state = READ_BLOCK;
			end else begin
				next_state = WAIT_FOR_MEAN;
			end

		end
		EMPTY_BUFFER: begin
			if (count == TOTAL_SAMPLES+2) begin
				next_state = IDLE;
			end else begin
				shift_en_1 = 0;
				if (variance_ready_flag) begin // LK [19.12.24]  to fix
					shift_en_2 = 1;
				end
				next_state = EMPTY_BUFFER;
			end
		end
		default: begin
			next_state = IDLE;
		end
	endcase
end

// added by [LK 19.12.24]
always_comb begin
	if (mean_ready && mean_ready_counter == 1) begin   
		shift_en_mean = 1;
	end else begin
		shift_en_mean = 0;
	end
end

// Data processing logic
always_ff @(posedge clk or negedge rst_n) begin
	variance_start_of_data <= 0;
	if (!rst_n) begin
		count<= 0;
		block_count <= 0;
		updated_block_count <= 0;
		mean_ready_counter <= 0;
		variance_ready_flag <=0; // LK [19.12.24] 
	end else begin
		if (state == IDLE) begin
			count <= 0;
			block_count <= 0;
			updated_block_count <= 0;
			mean_ready_counter <= 0;
		end else if (state == READ_BLOCK) begin
			updated_block_count <= 0;
			mean_ready_counter <= 0;
			if (count == TOTAL_SAMPLES) begin
				count <= 0;
			end else begin
				count <= count + 1;
			end
		end else if (state == WAIT_FOR_MEAN) begin
			if (!updated_block_count) begin
				block_count <= block_count + 1;
				updated_block_count <= 1;
				count <= 0;
				variance_ready_flag <=0; // LK [19.12.24] 
			end
			
			if (mean_ready) begin
				mean_ready_counter <= mean_ready_counter + 1;
				variance_start_of_data <= 0;
			end
			if (mean_ready_counter == 2) begin
				variance_start_of_data <= 1;
				mean_ready_counter <= 0;
			end	
		end else if (state == EMPTY_BUFFER) begin
			// LK [19.12.24] 
			if (variance_ready) begin
				variance_ready_flag <= 1; 
			end
			if (count == TOTAL_SAMPLES+2) begin
				count <= 0;
			end else begin
				count <= count + 1;
			end
		end
	end
end

endmodule




