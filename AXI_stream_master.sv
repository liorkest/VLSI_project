/*------------------------------------------------------------------------------
 * File          : AXI_stream_master.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 3, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module AXI_stream_master #(
	parameter DATA_WIDTH = 32  // Width of the AXI stream data
) (
	input  wire                     clk,           // Clock signal
	input  wire                     rst_n,         // Active-low reset signal

	// AXI Stream master interface
	output logic [DATA_WIDTH-1:0]   m_axis_tdata,  // Data signal
	output logic                    m_axis_tvalid, // Valid signal
	input  wire                     m_axis_tready, // Ready signal
	output logic                    m_axis_tlast,  // Last signal - end of line
	output logic                    m_axis_tuser,   // User custom signal - start of frame
	
	input logic [DATA_WIDTH-1:0] data_in,
	input logic                  valid_in,
	input logic                  last_in,
	input logic                  user_in
);

	// Internal signals and variables
	logic [DATA_WIDTH-1:0]          data_reg;      // Register to hold data
	logic                           last_reg;      // Register to hold tlast
	logic                           user_reg;      // Register to hold tuser

	// State machine to control AXI Stream transactions
	typedef enum logic [1:0] {
		IDLE,
		SEND
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
		// Default values
		next_state = state;
		m_axis_tvalid = 1'b0;
		m_axis_tdata = data_reg;
		m_axis_tlast = 1'b0;  // Default to de-assert
		m_axis_tuser = 1'b0;  // Default to de-assert

		case (state)
		  IDLE: begin
			if (valid_in) begin
			  next_state = SEND;  // Transition to SEND when valid data is available
			end
		  end

		  SEND: begin
			m_axis_tvalid = 1'b1;  // Assert valid signal
			m_axis_tdata = data_reg;
			m_axis_tlast = last_reg; // Pass last_reg value to m_axis_tlast
			m_axis_tuser = user_reg; // Pass user_reg value to m_axis_tuser

			if (m_axis_tready) begin
			  if (!valid_in) begin
				next_state = IDLE;  // Transition to IDLE if no more data is available
			  end
			end
		  end

		  default: next_state = IDLE;
		endcase
	  end
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
		  data_reg <= 32'd0;
		  last_reg <= 1'b0;
		  user_reg <= 1'b0;
		end else begin
		  if (state == IDLE && valid_in) begin
			data_reg <= data_in;
			last_reg <= last_in;
			user_reg <= user_in;
		  end else if (state == SEND && m_axis_tready) begin
			if (valid_in) begin
			  data_reg <= data_in;
			  last_reg <= last_in;
			  user_reg <= user_in;
			end else begin
			  data_reg <= 32'd0;
			  last_reg <= 1'b0;
			  user_reg <= 1'b0;
			end
		  end
		end
	  end

endmodule


