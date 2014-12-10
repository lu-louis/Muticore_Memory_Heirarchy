
module	decoder_2to4(
	in,
	out
	);
	input	[2-1:0]	in;
	output	[4-1:0]	out;

	reg		[4-1:0]	result;

	assign 	out	= result;

	always @ (*) begin
		case(in)
		2'b00:	result <= 4'b0001;
		2'b01:	result <= 4'b0010;
		2'b10:	result <= 4'b0100;
		2'b11:	result <= 4'b1000;
		endcase
	end

endmodule
