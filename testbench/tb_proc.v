

`ifndef	DEFFILE
	`include "define.v"
`endif

`tscale

module	tb_proc;
	/****** Simulation time ******/
	initial begin
	#(`CYCLE*12)	$stop;
	end
	/****** Parameter ******/
	parameter 	ADDR_WIDTH 	= 32;
	parameter	DATA_WIDTH	= `_1B;

	/****** input ******/
	reg	plusclk = 1;
	always plusclk = #(`CYCLE/2)	~plusclk;

	reg minusclk = 0;
	always minusclk = #(`CYCLE/2) ~minusclk;

	reg rst = 1;
	initial #(`CYCLE)	rst = 0;

	reg [1:0]	proc_id = 2'b11;
	reg [1:0]	pid		= 2'b10;
	reg [1:0]	op		= 2'b10;

	reg [26-1 : 0]	addr_v = 26'h000C;
	initial begin
	end

	reg [DATA_WIDTH - 1 : 0]	din	= 8'hF0;
	reg	cache_hit = 1;
	initial begin
	#(`CYCLE*4) 	cache_hit = 0;
	#(`CYCLE*2)		cache_hit = 1;
	end

	reg stall = 0;
	initial begin
	#(`CYCLE*7)		stall = 1;
	#(`CYCLE*2)		stall = 0;
	end

	reg [DATA_WIDTH - 1 : 0]	din_cache = 8'h0B;
	initial begin
	#(`CYCLE)		din_cache= 8'h10;
	#(`CYCLE)		din_cache= 8'h11;
	#(`CYCLE)		din_cache= 8'h12;
	#(`CYCLE)		din_cache= 8'h13;
	#(`CYCLE)		din_cache= 8'h14;
	#(`CYCLE)		din_cache= 8'h15;
	#(`CYCLE)		din_cache= 8'h16;
	#(`CYCLE)		din_cache= 8'h17;
	#(`CYCLE)		din_cache= 8'h18;
	#(`CYCLE)		din_cache= 8'h19;
	#(`CYCLE)		din_cache= 8'h20;
	end
	
	// OUTPUT
	wire	[ADDR_WIDTH - 1 : 0]	instruction;
	wire	[DATA_WIDTH - 1 : 0]	dout;
	wire	[DATA_WIDTH - 1 : 0]	dout_cache;

	// modeling
	processor	u_proc (
		// input
		.plusclk	( plusclk 	), 
		.minusclk	( minusclk	), 
		.rst		( rst		), 
		.proc_id	( proc_id	), 
		.pid		( pid		), 
		.op			( op 		), 
		.addr_v		( addr_v	), 
		.din		( din		),
		.cache_hit	( cache_hit	), 
		.stall		( stall		), 
		.din_cache	( din_cache	),
		// output
		.instruction	( instruction	), 
		.dout		( dout		), 
		.dout_cache ( dout_cache )
	);

endmodule

