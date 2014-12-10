
`timescale		1ns/1ns
module	tb_decorder_2to4;

	reg	[1:0]	in = 2'b0;
	initial begin
	#(5)	in = 2'b01;
	#(5)	in = 2'b10;
	#(5)	in = 2'b11;
	#(5)	$stop;
	end

	wire	[3:0]	out;

	decoder_2to4	u_decoder_2to4(
						.in	(in),
						.out(out)
					);


endmodule


