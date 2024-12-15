/*------------------------------------------------------------------------------
 * File          : divider_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/



module divider_test #() ();
parameter integer a_width  = 32; // changed from 8 to 16 [LK 15.12.24]
parameter integer b_width  = 32; // changed from 8 to 16 [LK 15.12.24]
parameter integer FRACTIONAL_BITS = 16; // added [LK 15.12.24]
DW_div divider (.*);
logic  [a_width-1 : 0] a;
logic  [b_width-1 : 0] b;
logic  [a_width-1 : 0] quotient;
logic  [b_width-1 : 0] remainder;
logic 	               divide_by_0;
		
logic [a_width-1:0] fixed_point_quotient;
assign fixed_point_quotient = (quotient >> 16);

initial begin
	#20;
	a=32'd25<<16;
	b=5;
	#20;
	a=32'd220<<16;
	b=5;	
	#20;
	a=32'd55<<16;
	b=5;	
	#20;
	a=32'd77<<16;
	b=2;
	#20;
	a=32'd50<<16;
	b=48;
	#20;
	a=32'd128<<16;
	b=0;
	#20;
	a=32'd128<<16;
	b=100;
	#20;
	// 16 bit operands
	a=32'd12800<<16;
	b=4020;
	#20;	
	a=32'd42552<<16;
	b=100;
	#20;	
	a=32'd33333<<16;
	b=989;
	#20;
end

endmodule

