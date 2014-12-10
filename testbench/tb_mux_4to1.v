
/*

Reference
// input
@clk, 
@sel, 
@din1, 
@din2,
@din3,
@din4
// output
@dout


*/

`ifndef DEFFILE
	`include "define.v"
`endif


module 	tb_mux_4to1;
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
	reg 	[1:0]	sel = 0;
	initial begin
	#(`CYCLE)		sel = 1;
	#(`CYCLE)		sel = 2;
	#(`CYCLE)		sel = 3;
	end
	// data input 1
	reg		[DATA_WIDTH - 1:0]	din1 = 32'h0AA0;
	//always	din1 = din1 + 32'h04;
	// data input 2
	reg		[DATA_WIDTH - 1:0]	din2 = 32'h0BB0;
	//always	din2 = din2 + 32'h04;
	// data input 3
	reg		[DATA_WIDTH - 1:0]	din3 = 32'h0CC0;
	//always	din3 = din3 + 32'h04;
	// data input 2
	reg		[DATA_WIDTH - 1:0]	din4 = 32'h0DD0;
	//always	din4 = din4 + 32'h04;

	// output
	wire	[DATA_WIDTH - 1:0]	dout;
	/*********** Simulation time **********/
	mux_4to1	#(.DATA_WIDTH (DATA_WIDTH))	u_mux4to1(
												.sel	( sel ),
												.din1	( din1 ),
												.din2	( din2 ),
												.din3	( din3 ),
												.din4	( din4 ),
												.dout	( dout )
											);
endmodule
	
	
