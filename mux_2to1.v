



`ifndef DEFFILE
	`include "define.v"
`endif


module mux_2to1 (
	// input
	sel, din1, din2,
	// output
	dout
	);
	/*********** Parameter ***********/
	parameter	DATA_WIDTH = 32;
	/*********** signal declaration ***********/
	// input
	input	sel;
	input	[DATA_WIDTH - 1:0]	din1;
	input	[DATA_WIDTH - 1:0]	din2;
	
	// output
	output	[DATA_WIDTH	- 1:0]	dout;
	reg		[DATA_WIDTH	- 1:0]	dout;

	always @ (*) begin
		if(~sel)
			dout <= din1;
		else
			dout <= din2;
	end

endmodule
