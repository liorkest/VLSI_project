/*------------------------------------------------------------------------------
 * File          : DW_div_32bit_inst.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 31, 2025
 * Description   :
 *------------------------------------------------------------------------------*/

module DW_div_32bit_inst #() (a, b, quotient, remainder, divide_by_0);

parameter integer a_width  = 32;  // changed from default 8 to 32 
parameter integer b_width  = 32;  // changed from default 8 to 32
parameter integer tc_mode  = 0;
parameter integer rem_mode = 1;

input  [a_width-1 : 0] a;
input  [b_width-1 : 0] b;
output [a_width-1 : 0] quotient;
output [b_width-1 : 0] remainder;
output 		 divide_by_0;

DW_div #(a_width, b_width, tc_mode, rem_mode) divider (
.a(a),.b(b),.quotient(quotient),.remainder(remainder),.divide_by_0(divide_by_0));

endmodule

