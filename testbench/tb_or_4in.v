
`ifndef DEFFILE
	`include "define.v"
`endif

`tscale

module tb_or_4in;

	/* simulatino time */
	initial begin 
	#(`CYCLE*2)	$stop;	
	end
	parameter	DATA_WIDTH = 32;
	
	reg		[DATA_WIDTH - 1 : 0]	din1 = 32'hF000;
	reg		[DATA_WIDTH - 1 : 0]	din2 = 32'h0F00;
	reg		[DATA_WIDTH - 1 : 0]	din3 = 32'h00F0;
	reg		[DATA_WIDTH - 1 : 0]	din4 = 32'h000F;

	wire	[DATA_WIDTH - 1 : 0]	dout;

	or_gate_4in		u_or_gate_4in(
						.din1	( din1 ),
						.din2	( din2 ),
						.din3	( din3 ),
						.din4	( din4 ),
						.result	( dout )
					);

endmodule
