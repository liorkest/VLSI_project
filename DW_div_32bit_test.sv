/*------------------------------------------------------------------------------
 * File          : DW_div_32bit_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Jan 31, 2025
 * Description   :
 *------------------------------------------------------------------------------*/



module DW_div_32bit_test #() ();
parameter integer a_width  = 32;
parameter integer b_width  = 32;

DW_div_32bit_inst divider (.*);
logic  [a_width-1 : 0] a;
logic  [b_width-1 : 0] b;
logic  [a_width-1 : 0] quotient;
logic  [b_width-1 : 0] remainder;
logic 	               divide_by_0;

initial begin
	#20;
	a=25;
	b=5;
	#20;
	a=25;
	b=4;	
	#20;
	a=55;
	b=5;	
	#20;
	a=77;
	b=2;
	#20;
	a=54650;
	b=48;
	#20;
	a=128;
	b=0;
	#20;
	a=12008;
	b=100;
	#20;
	a=550;
	b=32;
	#20;	
	a=25632;
	b=100;
	#20;	
	a=3450;
	b=9;
	#50;
	$finish;
end

endmodule

