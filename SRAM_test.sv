/*------------------------------------------------------------------------------
 * File          : SRAM_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/eplkls/memory/dpram512x8/dpram512x8.v"
`timescale 1ns/100fs
`define numAddr $clog2(512)
`define numOut 8
//`define wordDepth 32
module SRAM_test;
dpram512x8	RAM_U1(.*);
logic [`numAddr-1:0] A1;
logic[`numAddr-1:0] A2;
logic CE1,WEB1, OEB1, CSB1, CE2,WEB2, OEB2, CSB2;
logic [`numOut-1:0] I1,I2;
logic [`numOut-1:0] O1,O2;

always begin // clocks
	#5;
	CE1 = ~CE1;
	CE2 = ~CE2;
end

task write_1(logic data, logic addr);
	begin
		WEB2=1;
		WEB1=0;
		OEB1=0;
		I1=data;
		A1=addr;

		#10;
		WEB2=1;
		WEB1=1;
		
	end
endtask

	
task read_1(logic addr);
begin
	OEB1=0;
	OEB2=0;
	A1=addr;
	#10;
	OEB1=1;
	OEB2=1;
end
endtask
	

initial begin
	//initialize CE1 and CE2
	CE1 = 1;
	CE2 = 1;
	@(posedge CE1);
	#5;
	//code for SRAM signals
	A2 = 0;
	write_1(8'h7B, 8'h0F);
	read_1(8'h0F);
	#30 $finish;
end





endmodule