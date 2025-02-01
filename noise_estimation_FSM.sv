/*------------------------------------------------------------------------------
 * File          : noise_estimation_FSM.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 24, 2024
 * Description   :
 *------------------------------------------------------------------------------*/


module noise_estimation_FSM #(
	parameter DATA_WIDTH = 8,         // Width of input data
	parameter TOTAL_SAMPLES = 64     // Total number of samples per block (MUST be power of 2)
)(
	input logic                   clk,
	input logic                   rst_n,
	input logic                   start_of_frame, 
	//input logic                   end_of_frame, // [LS 31.01.25] removing - not used
	input logic                   mean_ready, 
	input logic                   variance_ready,
	input logic [31:0]            blocks_per_frame,
	// outputs
	output logic                   shift_en,
	output logic                   noise_mean_en, ///
	output logic                   shift_reg_rst_n,
	output logic                   variance_start_of_data,
	output logic                   start_data_mean2
);

logic [31:0] count;
logic [31:0] block_count;
logic updated_block_count;
logic [1:0] mean_ready_counter;


typedef enum logic [2:0] {
	IDLE = 0,
	READ_BLOCK = 1,
	WAIT_FOR_MEAN = 2
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
	shift_en  = 0;
	shift_reg_rst_n = 1;
	case (state) 
		IDLE: begin
			if (start_of_frame) begin
				next_state = READ_BLOCK;
				//shift_en = 1; // shift reg needs stable shift_en, no transition - to sample the data in the next cycle. [01.12.24]
				shift_reg_rst_n = 1;
				shift_en = 1;
			end else begin
				next_state = IDLE;
				shift_reg_rst_n = 0;
			end
		end
		READ_BLOCK: begin
			if (count == TOTAL_SAMPLES) begin
				next_state = WAIT_FOR_MEAN;
			end else begin
				shift_en = 1; // output
				next_state = READ_BLOCK;
			end
		end
		WAIT_FOR_MEAN: begin
			if (block_count == blocks_per_frame + 1) begin // refers to FULL BLOCKS number and NOT pixels(data)
				next_state = IDLE;
			end else if (mean_ready_counter == 2) begin
				next_state = READ_BLOCK;
			end else begin
				next_state = WAIT_FOR_MEAN;
			end

		end
		default: begin
			next_state = IDLE;
		end
	endcase
end


// Data processing logic
always_ff @(posedge clk or negedge rst_n) begin
	variance_start_of_data <= 0;
	noise_mean_en <= 0;
	if (!rst_n) begin
		count<= 0;
		block_count <= 0;
		updated_block_count <= 0;
		mean_ready_counter <= 0;
		start_data_mean2 <= 0;
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
			end
			
			if (mean_ready) begin
				mean_ready_counter <= mean_ready_counter + 1;
				variance_start_of_data <= 0;
			end
			if (mean_ready_counter == 2) begin
				variance_start_of_data <= 1;
				mean_ready_counter <= 0;
			end
		end	
		if (variance_ready && block_count > 0) begin
			noise_mean_en <= 1;
			if (block_count == 1) begin  // changed at [05.12.24]
				start_data_mean2 <= 1;
			end else begin
				start_data_mean2 <= 0;
			end			
		end
	end
end

endmodule




