/*------------------------------------------------------------------------------
 * File          : AXI_stream_slave.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jul 9, 2024
 * Description   : 
 *------------------------------------------------------------------------------*/

module AXI_stream_slave #(
	parameter DATA_WIDTH = 32 // Width of the AXI stream data
	// parameter TID_WIDTH  = 4,  // Width of the AXI stream ID             // CHECK THIS!!
	// parameter TDEST_WIDTH = 4  // Width of the AXI stream destination
	)(
	input  logic                       clk,         // Clock signal
	input  logic                       rst_n,       // Active-low reset signal

	// AXI Stream slave interface
	input  logic [DATA_WIDTH-1:0]      s_axis_tdata, // Data signal
	input  logic                       s_axis_tvalid,// Valid signal
	output logic                      s_axis_tready,// Ready signal           
	//input  logic                       s_axis_tlast, // Last signal - end of line // [LS 31.01.25] - only used by memory_writer
	input  logic                       s_axis_tuser // User custom signal - start of frame // [LS 31.01.25] - only used by memory_writer
	// input  logic [TID_WIDTH-1:0]       s_axis_tid,   // ID signal
	// input  logic [TDEST_WIDTH-1:0]     s_axis_tdest  // Destination signal
	);

	// Internal signals
	logic [DATA_WIDTH-1:0] data_reg;
	logic                  valid_reg;

	// State machine for handling AXI Stream transactions
	typedef enum logic [1:0] {
		IDLE,
		RECEIVE
	} state_t;

	state_t state, next_state;

	// State machine logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	end



	always_comb begin
		next_state = state;
		s_axis_tready = 1'b0;

		case (state)
			IDLE: begin
				if (s_axis_tvalid) begin
					next_state = RECEIVE;
					s_axis_tready = 1'b1;
				end
			end

			RECEIVE: begin
				s_axis_tready = 1'b1;
				if (!s_axis_tvalid) begin
					next_state = IDLE;
				end
			end

			default: next_state = IDLE;
		endcase
	end

	// Data processing logic
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			data_reg <= 32'b0;
			valid_reg <= 1'b0;
		end else begin
			if (state == RECEIVE && s_axis_tvalid) begin
				data_reg <= s_axis_tdata;
				valid_reg <= s_axis_tvalid;
			end
		end
	end

endmodule
