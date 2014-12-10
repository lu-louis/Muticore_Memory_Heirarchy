/*

Interface:
-- input --
@index	: request entry index 
@we		: write enable
@din	: input data
-- output --
@dout	: data value of request entry

*/

`ifndef DEFFILE
	`include "define.v"
`endif

`tscale

module	tb_cache_block_rd;
	/********** simulation time *********/	
	initial begin 
	#(`CYCLE*3)		$stop;
	end
	/********** parameter *********/
	parameter	NUM_OF_ENTRY	= `_1K;
	parameter	ENTRY_WIDTH		= 10;
	parameter	DATA_WIDTH		= `_4B;
	parameter	OFFSET_WIDTH	= 2;
	
	/********** input *********/	
	reg		[ENTRY_WIDTH - 1: 0]	index = 32'h02;
	initial begin
	#(`CYCLE)		index = 32'h04;
	#(`CYCLE)		index = 32'h06;
	end

	reg		we = 0;
	reg		[DATA_WIDTH - 1	: 0]	din = 32'h0FF0;

	/********** output *********/	
	wire	[DATA_WIDTH - 1	: 0]	dout;

	/********** modeling *********/	
	cache_block		u_cache_block(
						.index		( index ),
						.we			( we 	),
						.din		( din 	),
						.dout		( dout 	)
					);

endmodule
