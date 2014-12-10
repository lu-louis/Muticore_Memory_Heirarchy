/*







*/


`ifndef	DEFFILE
	`include "define.v"
`endif

module processor(
	// input
	plusclk, minusclk, rst, 		// global
	proc_id, pid, op, addr_v, din,	// interface
	cache_hit, stall, din_cache,
	// output
	instruction, request,			// cache
	dout_cache, 
	dout							// interface 
	);

	/*********** Signal Definition ***********/
	/****** Parameter ******/
	parameter 	ADDR_WIDTH 	= 32;
	parameter	DATA_WIDTH	= `_1B;

	/****** Interface ******/
	// global signal
	input	plusclk;	// Phase 1 clock
	input 	minusclk;	// Phase 2 clock
	input	rst;		// Reset 
		
	// outer interface
	input	[1:0]		proc_id;	// Processor ID
	input	[1:0]		pid;		// Process ID
	input	[1:0]		op;			// Operation
	input	[26-1:0]	addr_v;		// 28 bit Virtual address
	input	[DATA_WIDTH-1:0]	din;		// Input data
	output	[DATA_WIDTH-1:0]	dout;		// Output data 	
	
	// cache interface
	input	cache_hit;
	input	stall;
	input	[DATA_WIDTH - 1 : 0]	din_cache;
	output	[ADDR_WIDTH - 1 : 0]	instruction;
	output	[DATA_WIDTH - 1 : 0]	dout_cache;
	output	reg		request;

	/****** Internal *****/
	// internal register
	reg		[ADDR_WIDTH - 1 : 0]	next_inst_buf;	
	reg		[ADDR_WIDTH - 1 : 0]	inst_loader;		// *
	reg 	[DATA_WIDTH - 1 : 0]	din_cache_loader;	// *
	reg		[DATA_WIDTH - 1 : 0]	din_loader;
	reg		[DATA_WIDTH - 1 : 0]	dout_cache_buf;
	reg		[DATA_WIDTH - 1 : 0]	dout_buf;
	
	reg		delay;

	// signal assign
	assign 	instruction	= next_inst_buf;
	assign 	dout 		= dout_buf;
	assign	dout_cache	= dout_cache_buf;
	// internal component
	//assign	dout		= cache_hit	?	din_cache	:	32'hzz;
	
	/*********** Implementation ***********/
	/****** Phase 1 - plusclk ******/
	// Instruction fetch
	always @ ( plusclk ) begin
		if( plusclk ) begin
			inst_loader[31:30] <= proc_id;
			inst_loader[29:28] <= op;
			inst_loader[27:26] <= pid;
			if(rst) begin
				inst_loader[25:0]	<= addr_v;
				delay 				<= 0;
				request				<= 1'b1;
			end
			else begin
				if( cache_hit && ~delay && ~stall ) begin			// if 
					inst_loader[25:0]	<= inst_loader[25:0] + 5;	// different offset 
					delay	 			<= 1'b1;
				end
				else begin
					inst_loader[25:0]	<= inst_loader[25:0];
					delay				<= 1'b0;
				end
			end
			din_cache_loader <= din_cache;
		end
	end

	// Data fetch
	always @ ( plusclk ) begin
		if( plusclk ) begin
			din_loader	<= din;
		end
	end

	/****** Phase 2 - minusclk ******/
	// instruction latch
	always @ ( minusclk ) begin
		if( minusclk ) begin
			if( cache_hit && ~delay && ~stall ) begin
				next_inst_buf	<= inst_loader;			
				request			<= 1'b1;
			end	
			else
				request			<= 1'b0;
		end
	end
	// data
	always @ ( minusclk ) begin
		if( minusclk ) begin
			if( cache_hit && ~delay && ~stall ) begin
				dout_buf		<= din_cache;
				dout_cache_buf	<= din_loader;
			end
		end
	end

endmodule
