/*------------------------------------------------------------------------------
 * File          : memory_writer.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Dec 22, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module memory_writer #() (

output  wire                    start_write,
output  wire [ID_WIDTH-1:0]     write_id,
output  wire [ADDR_WIDTH-1:0]   write_addr,
output  wire [7:0]              write_len,
output  wire [2:0]              write_size,
output  wire [1:0]              write_burst,
output  wire [DATA_WIDTH-1:0]   write_data,
output  wire [DATA_WIDTH/8-1:0] write_strb
);


endmodule