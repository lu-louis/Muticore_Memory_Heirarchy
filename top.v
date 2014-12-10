
`ifndef DEFFILE
	`include "define.v"
`endif

module	top(
	plusclk, minusclk, 
	plusclk2, minusclk2, 
	plusclk8, minusclk8, 
	rst, rst2, rst8,
	addr_proc_0, 
	addr_proc_1,
	addr_proc_2,
	addr_proc_3,
	din_proc_0,
	din_proc_1,
	din_proc_2,
	din_proc_3,
	dout_proc_0,
	dout_proc_1,
	dout_proc_2,
	dout_proc_3
	);
	
	/* parameter */
	parameter	NUM_PROC	 	= 4;
	parameter	NUM_L2CACHE		= 2;
	parameter	NUM_DRAM		= 2;
	parameter	ADDR_WIDTH	 	= `_4B;
	parameter	DATA_PROC_WIDTH = `_1B;
	parameter	BUS_WIDTH	 = 38;
	localparam	PROC_ID_0	 = 0;
	localparam	PROC_ID_1	 = 1;
	localparam	PROC_ID_2	 = 2;
	localparam	PROC_ID_3	 = 3;
	
	input	plusclk;
	input	minusclk;
	input	plusclk2;
	input	minusclk2;
	input	plusclk8;
	input	minusclk8;
	input	rst;
	input	rst2;
	input 	rst8;
	input	[ADDR_WIDTH 	 - 1 : 0]	addr_proc_0;
	input	[ADDR_WIDTH 	 - 1 : 0]	addr_proc_1;
	input	[ADDR_WIDTH 	 - 1 : 0]	addr_proc_2;
	input	[ADDR_WIDTH 	 - 1 : 0]	addr_proc_3;
	input	[DATA_PROC_WIDTH - 1 : 0]	din_proc_0;
	input	[DATA_PROC_WIDTH - 1 : 0]	din_proc_1;
	input	[DATA_PROC_WIDTH - 1 : 0]	din_proc_2;
	input	[DATA_PROC_WIDTH - 1 : 0]	din_proc_3;
	output	[DATA_PROC_WIDTH - 1 : 0]	dout_proc_0;
	output	[DATA_PROC_WIDTH - 1 : 0]	dout_proc_1;
	output	[DATA_PROC_WIDTH - 1 : 0]	dout_proc_2;
	output	[DATA_PROC_WIDTH - 1 : 0]	dout_proc_3;

	/********* internal signal *********/
	// processor <= cache
	wire	[NUM_PROC 		 - 1 : 0]	cache_hit;
	wire	[NUM_PROC 		 - 1 : 0]	stall;
	wire	[NUM_PROC		 - 1 : 0]	cache_request;
	wire	[ADDR_WIDTH 	 - 1 : 0]	next_inst	[NUM_PROC - 1 : 0];
	wire	[DATA_PROC_WIDTH - 1 : 0]	dout_cache	[NUM_PROC - 1 : 0];
	wire	[DATA_PROC_WIDTH - 1 : 0]	din_cache	[NUM_PROC - 1 : 0];

	// arbiter <=> cache/mem
	// L1 cache only have one side
	wire	[NUM_PROC 		- 1 : 0]	req_cache_L1;
	wire	[NUM_PROC 		- 1 : 0]	type_cache_L1;	
	wire	[NUM_PROC 		- 1 : 0]	hold_cache_L1;	
	wire	[NUM_PROC 		- 1 : 0]	grant_cache_L1;	
	// L2 cache 
	wire	[NUM_L2CACHE 	- 1 : 0]	req_cache_L2_bus_0;
	wire	[NUM_L2CACHE 	- 1 : 0]	type_cache_L2_bus_0;
	wire	[NUM_L2CACHE 	- 1 : 0]	hold_cache_L2_bus_0;
	wire	[NUM_L2CACHE 	- 1 : 0]	grant_cache_L2_bus_0;
	wire	[NUM_L2CACHE 	- 1 : 0]	req_cache_L2_bus_1;
	wire	[NUM_L2CACHE 	- 1 : 0]	type_cache_L2_bus_1;
	wire	[NUM_L2CACHE 	- 1 : 0]	hold_cache_L2_bus_1;
	wire	[NUM_L2CACHE 	- 1 : 0]	grant_cache_L2_bus_1;
	// dram
	wire	[NUM_DRAM 		- 1 : 0]	req_dram;
	wire	[NUM_DRAM 		- 1 : 0]	type_dram;
	wire	[NUM_DRAM 		- 1 : 0]	hold_dram;
	wire	[NUM_DRAM 		- 1 : 0]	grant_dram;
	
	wire	[ 2 - 1 : 0]				bus_active_bus_0;
	wire								bus_active_bus_1;


	wire	[BUS_WIDTH		- 1 : 0]	bus_0		[2-1:0];
	wire	[BUS_WIDTH		- 1 : 0]	bus_1;
	wire	[ 1 : 0 ]	proc_id_0	= 2'b00;
	wire	[ 1 : 0 ]	proc_id_1	= 2'b01;
	wire	[ 1 : 0 ]	proc_id_2	= 2'b10;
	wire	[ 1 : 0 ]	proc_id_3	= 2'b11;
	
//	reg	 	plusclk2, plusclk3;
//	reg		minusclk2, 

	wire	zero_wire;
	wire	empty_wire;
	// testing purpose
	assign	rst_1				= 1;	// set processor 1 off
//	assign	req_cache_L2[0]		= 0;	
//	assign	type_cache_L2[0]	= 0;
//	assign	hold_cache_L2[0]	= 0;
	assign	zero_wire			= 0;

	/********** Processor 0 **********/
	processor	proc_0(
					// input
					.plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst		), 
					.proc_id	( proc_id_0 ), 
					.pid		( addr_proc_0[27:26] ), 
					.op			( addr_proc_0[29:28] ), 
					.addr_v		( addr_proc_0[25: 0] ), 
					.din		( din_proc_0		 ),
					.cache_hit	( cache_hit[0]	), 
					.stall		( stall[0]		), 
					.din_cache	( din_cache[0]	),
					// output
					.instruction ( next_inst[0]	), 
					.request	( cache_request[0]	),
					.dout		( dout_proc_0	), 
					.dout_cache	( dout_cache[0]	)		
				); 


	cache_L1	cache_L1_0(
					// input
					.plusclk	( plusclk 	),  		// global
					.minusclk	( minusclk	), 
					.rst		( rst 		),
					.next_inst	( next_inst[0]	), 
					.request	( cache_request[0]	),
					.din_proc	( dout_cache[0]		), 		// processor
					.bus_grant	( grant_cache_L1[0]	), 
					.bus_active	( bus_active_bus_0[0] ),		// arbiter
					.bus_1		( bus_1 ),					// bus between L2- mem
					// output
					.dout_proc	( din_cache[0]		), 
					.cache_hit	( cache_hit[0]		), 
					.stall		( stall[0]			),		// processor
					.bus_req	( req_cache_L1[0]	), 
					.bus_req_type	( type_cache_L1[0]	), 
					.bus_hold	( hold_cache_L1[0]	),		// arbiter
					// inout
					.bus_0		( bus_0[0] )
				);

	/********** Processor 1 **********/
	processor	proc_1(
					// input
					.plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst_1		), 
					.proc_id	( proc_id_1 ), 
					.pid		( addr_proc_1[27:26] ), 
					.op			( addr_proc_1[29:28] ), 
					.addr_v		( addr_proc_1[25: 0] ), 
					.din		( din_proc_1		 ),
					.cache_hit	( cache_hit[1]	), 
					.stall		( stall[1]		), 
					.din_cache	( din_cache[1]	),
					// output
					.instruction ( next_inst[1]	), 
					.request	( cache_request[1]	),
					.dout		( dout_proc_1	), 
					.dout_cache	( dout_cache[1]	)		
				); 
	cache_L1	cache_L1_1(
					// input
					.plusclk	( plusclk 	),  		// global
					.minusclk	( minusclk	), 
					.rst		( rst_1 		),
					.next_inst	( next_inst[1]	), 
					.request	( cache_request[1]	),
					.din_proc	( dout_cache[1]		), 		// processor
					.bus_grant	( grant_cache_L1[1]	), 
					.bus_active	( bus_active_bus_0[0] ),		// arbiter
					.bus_1		( bus_1 ),					// bus between L2- mem
					// output
					.dout_proc	( din_cache[1]		), 
					.cache_hit	( cache_hit[1]		), 
					.stall		( stall[1]			),		// processor
					.bus_req	( req_cache_L1[1]	), 
					.bus_req_type	( type_cache_L1[1]	), 
					.bus_hold	( hold_cache_L1[1]	),		// arbiter
					// inout
					.bus_0		( bus_0[0] )
				);

	/********** Arbiter bus 0 a **********/
	arbiter		arbiter_bus_0_a(
				    // input
				    .plusclk	( minusclk	), 
					.minusclk	( plusclk	), 
					.rst		( rst		),
				    .req_1		( req_cache_L1[0] ), 
					.req_2		( req_cache_L1[1] ), 
					.req_3		( req_cache_L2_bus_0[0] ),
					.req_4		( zero_wire ),
					.type_1		( type_cache_L1[0] ),
					.type_2		( type_cache_L1[1] ),
					.type_3		( type_cache_L2_bus_0[0] ),
					.type_4		( zero_wire ),
					.hold_1		( hold_cache_L1[0] ),
					.hold_2		( hold_cache_L1[1] ),
					.hold_3		( hold_cache_L2_bus_0[0] ),
					.hold_4		( zero_wire ),
				    // output
				    .grant_1		( grant_cache_L1[0]	), 
					.grant_2		( grant_cache_L1[1]	), 
					.grant_3		( grant_cache_L2_bus_0[0]	),
					.grant_4		( empty_wire		),
					.bus_active		( bus_active_bus_0[0] )
				);
	/********** Processor 2 **********/
	processor	proc_2(
					// input
					.plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst		), 
					.proc_id	( proc_id_2 ), 
					.pid		( addr_proc_2[27:26] ), 
					.op			( addr_proc_2[29:28] ), 
					.addr_v		( addr_proc_2[25: 0] ), 
					.din		( din_proc_2		 ),
					.cache_hit	( cache_hit[2]	), 
					.stall		( stall[2]		), 
					.din_cache	( din_cache[2]	),
					// output
					.instruction ( next_inst[2]	), 
					.request	( cache_request[2]	),
					.dout		( dout_proc_2	), 
					.dout_cache	( dout_cache[2]	)		
				); 


	cache_L1	cache_L1_2(
					// input
					.plusclk	( plusclk 	),  		// global
					.minusclk	( minusclk	), 
					.rst		( rst 		),
					.next_inst	( next_inst[2]	), 
					.request	( cache_request[2]	),
					.din_proc	( dout_cache[2]		), 		// processor
					.bus_grant	( grant_cache_L1[2]	), 
					.bus_active	( bus_active_bus_0[1] ),		// arbiter
					.bus_1		( bus_1 ),					// bus between L2- mem
					// output
					.dout_proc	( din_cache[2]		), 
					.cache_hit	( cache_hit[2]		), 
					.stall		( stall[2]			),		// processor
					.bus_req	( req_cache_L1[2]	), 
					.bus_req_type	( type_cache_L1[2]	), 
					.bus_hold	( hold_cache_L1[2]	),		// arbiter
					// inout
					.bus_0		( bus_0[1] )
				);

	/********** Processor 3 **********/
	processor	proc_3(
					// input
					.plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst_1		), 
					.proc_id	( proc_id_3 ), 
					.pid		( addr_proc_3[27:26] ), 
					.op			( addr_proc_3[29:28] ), 
					.addr_v		( addr_proc_3[25: 0] ), 
					.din		( din_proc_3		 ),
					.cache_hit	( cache_hit[3]	), 
					.stall		( stall[3]		), 
					.din_cache	( din_cache[3]	),
					// output
					.instruction ( next_inst[3]	), 
					.request	( cache_request[3]	),
					.dout		( dout_proc_3	), 
					.dout_cache	( dout_cache[3]	)		
				); 
	cache_L1	cache_L1_3(
					// input
					.plusclk	( plusclk 	),  		// global
					.minusclk	( minusclk	), 
					.rst		( rst_1 		),
					.next_inst	( next_inst[3]	), 
					.request	( cache_request[3]	),
					.din_proc	( dout_cache[3]		), 		// processor
					.bus_grant	( grant_cache_L1[3]	), 
					.bus_active	( bus_active_bus_0[1] ),		// arbiter
					.bus_1		( bus_1 ),					// bus between L2- mem
					// output
					.dout_proc	( din_cache[3]		), 
					.cache_hit	( cache_hit[3]		), 
					.stall		( stall[3]			),		// processor
					.bus_req	( req_cache_L1[3]	), 
					.bus_req_type	( type_cache_L1[3]	), 
					.bus_hold	( hold_cache_L1[3]	),		// arbiter
					// inout
					.bus_0		( bus_0[1] )
				);
	/********** Arbiter bus 0 b **********/

	arbiter		arbiter_bus_0_b(
				    // input
				    .plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst		),
				    .req_1		( req_cache_L1[2] ), 
					.req_2		( req_cache_L1[3] ), 
					.req_3		( req_cache_L2_bus_0[1] ),
					.req_4		( zero_wire ),
					.type_1		( type_cache_L1[2] ),
					.type_2		( type_cache_L1[3] ),
					.type_3		( type_cache_L2_bus_0[1] ),
					.type_4		( zero_wire ),
					.hold_1		( hold_cache_L1[2] ),
					.hold_2		( hold_cache_L1[3] ),
					.hold_3		( hold_cache_L2_bus_0[1] ),
					.hold_4		( zero_wire ),
				    // output
				    .grant_1		( grant_cache_L1[2]	), 
					.grant_2		( grant_cache_L1[3]	), 
					.grant_3		( grant_cache_L2_bus_0[1]	),
					.grant_4		( empty_wire		),
					.bus_active		( bus_active_bus_0[1] )
				);

	/********** Cache L2a **********/
	cache_L2 	cache_L2_0(
					// input
					.plusclk		( plusclk2 	),	// global 
					.minusclk		( minusclk2	), 
					.rst			( rst2		),	
					.bus_grant_0	( grant_cache_L2_bus_0[0] 	),	// bus 0 a		
					.bus_active_0	( bus_active_bus_0[0] 		),
					.bus_grant_1	( grant_cache_L2_bus_1[0] 	),	// bus 1
					.bus_active_1	( bus_active_bus_1			),	
					// output
					.bus_hold_0		( hold_cache_L2_bus_0[0]	),	// bus 0
					.bus_req_0		( req_cache_L2_bus_0[0]		),	
					.bus_req_type_0	( type_cache_L2_bus_0[0]	),	
					.bus_hold_1		( hold_cache_L2_bus_1[0]	), // bus 1 
					.bus_req_1		( req_cache_L2_bus_1[0]		),
					.bus_req_type_1	( type_cache_L2_bus_1[0]	),
					// inout
					.bus_0			( bus_0[0]	), 
					.bus_1			( bus_1		)
				);
	/********** Cache L2b **********/
	cache_L2 	cache_L2_1(
					// input
					.plusclk		( plusclk2 	),	// global 
					.minusclk		( minusclk2	), 
					.rst			( rst2		),	
					.bus_grant_0	( grant_cache_L2_bus_0[1] 	),	// bus 0 a		
					.bus_active_0	( bus_active_bus_0[1] 		),
					.bus_grant_1	( grant_cache_L2_bus_1[1] 	),	// bus 1
					.bus_active_1	( bus_active_bus_1			),	
					// output
					.bus_hold_0		( hold_cache_L2_bus_0[1]	),	// bus 0
					.bus_req_0		( req_cache_L2_bus_0[1]		),	
					.bus_req_type_0	( type_cache_L2_bus_0[1]	),	
					.bus_hold_1		( hold_cache_L2_bus_1[1]	), // bus 1 
					.bus_req_1		( req_cache_L2_bus_1[1]		),
					.bus_req_type_1	( type_cache_L2_bus_1[1]	),
					// inout
					.bus_0			( bus_0[1]	), 
					.bus_1			( bus_1		)
			);


	/********** Arbiter bus 1 **********/

	arbiter		#(.CYCLE_RATIO (4))
				arbiter_bus_1(
				    // input
				    .plusclk	( plusclk	), 
					.minusclk	( minusclk	), 
					.rst		( rst		),
				    .req_1		( req_cache_L2_bus_1[0] ), 
					.req_2		( req_cache_L2_bus_1[1] ), 
					.req_3		( req_dram[0] ),	
					.req_4		( zero_wire ),			// need change
					.type_1		( type_cache_L2_bus_1[0] ),
					.type_2		( type_cache_L2_bus_1[1] ),
					.type_3		( type_dram[0] ),
					.type_4		( zero_wire ),			// need modify
					.hold_1		( hold_cache_L2_bus_1[0] ),
					.hold_2		( hold_cache_L2_bus_1[1] ),
					.hold_3		( hold_dram[0] ),
					.hold_4		( zero_wire ),			// need modify
				    // output
				    .grant_1		( grant_cache_L2_bus_1[0]	), 
					.grant_2		( grant_cache_L2_bus_1[1]	), 
					.grant_3		( grant_dram[0]	),
					.grant_4		( empty_wire		),		// need modify
					.bus_active		( bus_active_bus_1 	)
				);


	/********** DRAM 0 **********/
	dram		memory_0 (
					// input
					.plusclk		( plusclk8		), 			// global
					.minusclk		( minusclk8		), 
					.rst			( rst8 			),		
					.bus			( bus_1			),			// bus
					.bus_grant		( grant_dram[0] ), 			// arbiter
					.bus_active		( bus_active_bus_1	),		
					// output	
					.bus_req		( req_dram[0]	), 
					.bus_req_type	( type_dram[0]	), 
					.bus_hold		( hold_dram[0]	)// arbiter
	);

//	always @ ( plusclk )
			
	
endmodule



