
`ifndef DEFFILE
	`include "define.v"
`endif

`tscale

module	tb_arbiter;

	initial begin
	#(`CYCLE*10)	$stop;
	end

	reg	plusclk	= 1;
	always	plusclk	 = #(`CYCLE/2)	~plusclk;
	reg minusclk = 0;
	always	minusclk	 = #(`CYCLE/2)	~minusclk;

	reg	rst = 1;
	initial  rst = 0;

	reg	[3-1 : 0]	req = 3'b000;
	initial begin
	#(`CYCLE)	req = 3'b100;
	#(`CYCLE)	req = 3'b110;
	#(`CYCLE*5) req = 3'b011;
	end
	
	reg [3-1 : 0]	type = 3'b000;
	initial begin
	#(`CYCLE*7)		type = 3'b001;
	end

	reg [3-1 : 0]	hold = 3'b000;
	initial begin	
	#(`CYCLE*2)		hold = 3'b100;
	#(`CYCLE*5)		hold = 3'b000;
	end

	// output
	wire	[3-1 : 0]	grant;
	

	arbiter		u_arbiter(
				    // input
				    .plusclk	( plusclk 	), 
					.minusclk	( minusclk 	), 
					.rst		( rst		),
					.req_1		( req[0]	),
					.req_2		( req[1]	),
					.req_3		( req[2]	),
					.type_1		( type[0]	), 
					.type_2		( type[1]	), 
					.type_3		( type[2]	),
					.hold_1		( hold[0]	), 
					.hold_2		( hold[1]	),
					.hold_3		( hold[2]	),
				    // output
					.grant_1	( grant[0]	), 
					.grant_2	( grant[1]	), 
					.grant_3	( grant[2]	)
				);

endmodule

