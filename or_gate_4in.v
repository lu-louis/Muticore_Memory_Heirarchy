
module	or_gate_4in(
	// input
	din1, din2, din3, din4,
	// output
	result
	);

	/********* parameter *********/
	parameter	DATA_WIDTH	= 32;

	input	[DATA_WIDTH - 1 : 0]	din1;
	input	[DATA_WIDTH - 1 : 0]	din2;
	input	[DATA_WIDTH - 1 : 0]	din3;
	input	[DATA_WIDTH - 1 : 0]	din4;

	output	[DATA_WIDTH - 1 : 0]	result;

	assign result = din1 | din2 | din3 | din4;

endmodule
