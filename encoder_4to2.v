
module	encoder_4to2(
	in,
	out
	);
	input	[4-1:0]	in;
	output	[2-1:0]	out;

	reg		[2-1:0]	result;

	assign 	out	= result;

	always @ (*) begin
		case(in)
		4'b0001:	result <= 2'b00;
		4'b0010:	result <= 2'b01;
		4'b0100:	result <= 2'b10;
		4'b1000:	result <= 2'b11;
		default:	result <= 2'b00;
		endcase
	end

endmodule
