/*------------------------------------------------------------------------------
 * File          : wiener_3_channels.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 19, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module wiener_3_channels #(
	parameter DATA_WIDTH = 32,         // Width of input data (each pixel: [0][R][G][B])
	parameter DATA_WIDTH_1_CH = 8,
	parameter TOTAL_SAMPLES = 64     // Total number of pixels per frame (MUST be power of 2)
)(
	input  logic                   clk,
	input  logic                   rst_n,
	input  logic 				   wiener_block_stats_en, // [LK 10.01.25]
	input  logic 				   wiener_calc_en,	// [LK 10.01.25]
	// controller
	input  logic                   start_of_frame, end_of_frame, 
	input  logic [DATA_WIDTH-1:0]  data_in,   // 32-bit input data
	input  logic                   start_data, // start of each block
	input logic [31:0]            blocks_per_frame,
	input logic [2*DATA_WIDTH_1_CH-1:0]  noise_variance,
   
	output logic [DATA_WIDTH-1:0]   data_out,
	output logic [31:0]   data_count // for debug
);

logic [DATA_WIDTH_1_CH-1:0] data_in_r;
logic [DATA_WIDTH_1_CH-1:0] data_in_g;
logic [DATA_WIDTH_1_CH-1:0] data_in_b;
logic [DATA_WIDTH_1_CH-1:0] data_out_r;
logic [DATA_WIDTH_1_CH-1:0] data_out_g;
logic [DATA_WIDTH_1_CH-1:0] data_out_b;
logic [31:0] data_count_r;
logic [31:0] data_count_g;
logic [31:0] data_count_b;

// DUT instantiation 
wiener_1_channel #( 
  .DATA_WIDTH(DATA_WIDTH_1_CH), 
  .TOTAL_SAMPLES(TOTAL_SAMPLES) 
) red_ch ( 
  .clk(clk), 
  .rst_n(rst_n), 
  .wiener_block_stats_en(wiener_block_stats_en),
  .wiener_calc_en(wiener_calc_en),
  .start_of_frame(start_of_frame),
  .end_of_frame(end_of_frame),
  .noise_variance(noise_variance), 
  .data_in(data_in_r), 
  .start_data(start_data),
  .blocks_per_frame(blocks_per_frame), 
  .data_out(data_out_r), 
  .data_count(data_count_r)
); 

// DUT instantiation 
wiener_1_channel #( 
  .DATA_WIDTH(DATA_WIDTH_1_CH), 
  .TOTAL_SAMPLES(TOTAL_SAMPLES) 
) blue_ch ( 
  .clk(clk), 
  .rst_n(rst_n), 
  .wiener_block_stats_en(wiener_block_stats_en),
  .wiener_calc_en(wiener_calc_en),
  .start_of_frame(start_of_frame),
  .end_of_frame(end_of_frame),
  .noise_variance(noise_variance), 
  .data_in(data_in_g), 
  .start_data(start_data),
  .blocks_per_frame(blocks_per_frame), 
  .data_out(data_out_g), 
  .data_count(data_count_g)
); 

// DUT instantiation 
wiener_1_channel #( 
  .DATA_WIDTH(DATA_WIDTH_1_CH), 
  .TOTAL_SAMPLES(TOTAL_SAMPLES) 
) green_ch ( 
  .clk(clk), 
  .rst_n(rst_n), 
  .wiener_block_stats_en(wiener_block_stats_en),
  .wiener_calc_en(wiener_calc_en),
  .start_of_frame(start_of_frame),
  .end_of_frame(end_of_frame),
  .noise_variance(noise_variance), 
  .data_in(data_in_b), 
  .start_data(start_data),
  .blocks_per_frame(blocks_per_frame), 
  .data_out(data_out_b), 
  .data_count(data_count_b)
); 

// connections
assign	data_in_r = data_in[7:0];
assign	data_in_g = data_in[15:8];
assign	data_in_b = data_in[23:16];

assign	data_out[7:0]=data_out_r;
assign	data_out[15:8]=data_out_g;
assign	data_out[23:16]=data_out_b;
assign	data_out[31:24]=0;

always_comb begin
	if (data_count_r == data_count_g && data_count_r == data_count_b) begin
		data_count = data_count_r;
	end else begin
		data_count = -1;
	end

end

endmodule