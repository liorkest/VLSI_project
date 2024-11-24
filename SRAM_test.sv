/*------------------------------------------------------------------------------
 * File          : SRAM_test.sv
 * Project       : RTL
 * Author        : eplkls
 * Creation date : Nov 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
`include "/users/eplkls/memory/dpram512x8_cb/dpram512x8_cb.v"
`timescale 1ns/100fs
`define numAddr $clog2(512)
`define numOut 8
//`define wordDepth 32
module SRAM_test;
dpram512x8_cb	RAM_U1(.*);
logic [`numAddr-1:0] A1;
logic[`numAddr-1:0] A2;
logic CEB1,WEB1, OEB1, CSB1, CEB2,WEB2, OEB2, CSB2;
logic [`numOut-1:0] I1,I2;
logic [`numOut-1:0] O1,O2;

always begin // clocks
	#5;
	CEB1 = ~CEB1;
	CEB2 = ~CEB2;
end

task write_1(logic [`numOut-1:0] data, logic [`numAddr-1:0] addr);
	begin
		WEB2=1;
		WEB1=0;

		I1=data;
		A1=addr;

		#10;
		WEB2=1;
		WEB1=1;

		
	end
endtask

	
task read_1(logic [`numAddr-1:0] addr);
begin
	WEB1=1;
	A1=addr;
	#10;
end
endtask
	

initial begin
	//initialize CEB1 and CEB2
	CEB1 = 1;
	CEB2 = 1;
	OEB1=0;
	OEB2=0;
	CSB1=0;
	CSB2=0;
	I2=8'h44;
	@(posedge CEB1);
	//code for SRAM signals
	A2 = 9'h30;
	write_1(8'h7B, 9'h0F);
	read_1(9'h0F);
	#30 $finish;
end





endmodule
