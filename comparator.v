
module comparator(
	// input
	din1, din2,
	// output
	equal
	);

	/********** parameter *********/
	parameter	DATA_WIDTH = 32;

	/********** interface signal *********/
	input	[DATA_WIDTH - 1 : 0]	din1;
	input	[DATA_WIDTH	- 1 : 0]	din2;
	output	equal;

	/********** internal structure *********/
	reg 	cmp_result;

	assign 	equal = cmp_result;

	always @ (*) begin
		if( din1 == din2 )
			cmp_result = 1;
		else
			cmp_result = 0;
	end

endmodule
