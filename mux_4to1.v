




`ifndef DEFFILE
	`include "define.v"
`endif


module mux_4to1 (
	// input
	sel, din1, din2, din3, din4,
	// output
	dout
	);
	/*********** Parameter ***********/
	parameter	DATA_WIDTH = 32;
	/*********** signal declaration ***********/
	// input
	input	[1:0]	sel;
	input	[DATA_WIDTH - 1:0]	din1;
	input	[DATA_WIDTH - 1:0]	din2;
	input	[DATA_WIDTH - 1:0]	din3;
	input	[DATA_WIDTH - 1:0]	din4;
	// output
	output	[DATA_WIDTH	- 1:0]	dout;
	reg		[DATA_WIDTH	- 1:0]	dout;

	always @ (*) begin
		if(sel == 2'b00)
			dout <= din1;
		else if (sel == 2'b01)
			dout <= din2;
		else if(sel == 2'b10)
			dout <= din3;
		else
			dout <= din4;
	end

endmodule