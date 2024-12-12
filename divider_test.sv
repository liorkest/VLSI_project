/*------------------------------------------------------------------------------
 * File          : divider_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
`ifdef MACRO_A
`include "/users/eplkls/DW/DW_div.v"
`endif


module divider_test #() ();
parameter integer a_width  = 8;
parameter integer b_width  = 8;
DW_div divider (.*);
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
	a=220;
	b=5;	
	#20;
	a=55;
	b=5;	
	#20;
	a=77;
	b=2;
	#20;
	a=50;
	b=48;
	#20;
	a=128;
	b=0;
	#20;
	a=128;
	b=100;
	#20;
end

endmodule

