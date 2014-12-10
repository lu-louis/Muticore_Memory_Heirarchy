
/*

Reference
// input
@clk, 
@sel, 
@din1, 
@din2,
// output
@dout


*/

`ifndef DEFFILE
	`include "define.v"
`endif


module 	tb_mux_2to1;
	/*********** Simulation time ***********/
	initial begin 
	#(`CYCLE*5)		$stop;
	end
	/*********** Parameter ***********/
	parameter	DATA_WIDTH = 8;
	/*********** signal declaration ***********/
	// input
	// clock 
	reg	clk = 1;
	always	clk = #(`CYCLE/2) ~clk;
	// select
	reg sel = 0;
	initial begin
	#(`CYCLE)		sel = 1;
	#(`CYCLE*2)		sel = 0;
	end
	// data input 1
	reg		[DATA_WIDTH - 1:0]	din1 = 32'h0AA0;
	initial begin 
	#(`CYCLE*3.5)	din1 = 32'h0DD0;
	end
	// data input 2
	reg		[DATA_WIDTH - 1:0]	din2 = 32'h0BB0;
	initial begin 
	#(`CYCLE*2.5)	din2 = 32'h0CC0;
	end
	// output
	wire	[DATA_WIDTH - 1:0]	dout;
	/*********** Simulation time **********/
	mux_2to1	#(.DATA_WIDTH (DATA_WIDTH))	u_mux2to1(
												.sel	( sel ),
												.din1	( din1 ),
												.din2	( din2 ),
												.dout	( dout )
											);

endmodule
	
	