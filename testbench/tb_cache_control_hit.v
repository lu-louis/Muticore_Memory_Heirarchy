/*
Description:
test scenario included:
- Read Hit in three state	: shared clean / owned clean / own dirty. Requried no further action
- Write hit in three state	: shared clean 		Write back required + status update. This testcase only shows it will change to writeback
							  owned  clean		Update the status
							  owned  dirty 		Required no further action
							  


Reference:

@plusclk
@minusclk
@rst
@op
@hit
@sel_cache_table
@flag
--------------------
@bus_get
@mem_ready
@get_reply

@snp_hit_1
@snp_hit_2
@snp_op_1
@snp_op_2
@snp_block_hit_1
@snp_block_hit_2
@snp_flag_1
@snp_flag_2
--------------------

@bus_req
@bus_req_op
@bus_req_clc
@halt
@tran_buf_input_sel
@bus_direction
@we_0 : 3

@snp_error
@wb_active
@pwb_active
*/

`ifndef	DEFFILE
	`include	"define.v"
`endif

`tscale

module tb_cache_control_hit;
	

	/********** simulation time **********/
	initial begin 
	#(`CYCLE*12)		$stop;
	end
	/************ Parameter ***********/
	// Data valid flag status
	localparam	INVALID			= 0;
	localparam	SHARED_CLEAN	= 1;
	localparam	OWNED_CLEAN		= 2;
	localparam	OWNED_DIRTY		= 3;
	
	// arbiter 
	localparam	CYCLE_NUM_ADDR	= 2;	// number of cycle required to transmit address ( read miss request )
	localparam	CYCLE_NUM_DATA	= 2;	// number of cycle required to transmit data 	( (priority) write back )

	localparam	RD				= 0;
	localparam	WR				= 1;
	/********** input concerned **********/
	
	reg	plusclk = 1;
	always	plusclk = #(`CYCLE/2)	~plusclk;

	reg	minusclk = 0;
	always	minusclk = #(`CYCLE/2)	~minusclk;	
	
	reg	rst = 1;
	initial begin 
	#(`CYCLE)	rst = 0;
	end

	reg	[1:0]	op = 0;				// read
	initial begin
	#(`CYCLE*6)	op = 1;		// write
	end

	reg	hit = 1;

	reg [1:0]	sel_block_in = 2'b10;
	initial begin
	end

	reg	[7:0]		flag = 8'b11010100;		// SHARED_CLEAN
	initial begin
	#(`CYCLE*2)		flag = 8'b11100100;		// OWNED_CLEAN
	#(`CYCLE*2)		flag = 8'b11110100;		// OWNED_DIRTY
	#(`CYCLE*2)		flag = 8'b11100100;			// when write, no WB
	#(`CYCLE*2)		flag = 8'b11110100;			// when write, no WB
	#(`CYCLE*2)		flag = 8'b11010100;			// when write, WB required

	end

	/********** not important **********/
	// arbiter
	reg bus_get;
	// bus interface
	//reg mem_ready;
	reg get_reply;
	// snoop
	reg [ 13 : 0 ]	snp_1;
	reg [ 13 : 0 ]	snp_2;

	/********** output **********/
	// arbiter
	wire 	bus_req;
	wire 	bus_req_op;
	wire 	[3:0]	bus_req_clc;
	// processor
	wire 	halt;
	//bus interface
	wire	tran_buf_input_sel;
	wire	bus_direction;
	// cache table
	wire 	[ 3 : 0 ]	we_flag_vector;
	wire	[ 3 : 0 ]	we_addr_vector;
	wire 	[ 7 : 0 ]	new_flag_vector;

	wire	snp_error;
	wire	wb_active;
	wire	pwb_active;
	wire	[3:0]	st;
	wire	[3:0]	sub_st;
	wire	[3:0]	re_st;
	wire	[3:0]	re_sub_st;

/********** modeling **********/
	cacheL1_control_unit	u_cache_control_unit(
								.plusclk	( plusclk	),
								.minusclk	( minusclk 	),
								.rst		( rst		),
								.op			( op		),
								.hit		( hit		),
								.sel_block_in	( sel_block_in ),
								.flag		( flag		),
								// --------------------
								.bus_get	( bus_get	),
								//.mem_ready	( mem_ready ),
								.get_reply 	( get_reply	),
								.snp_1	( snp_1	),
								.snp_2	( snp_2	),
								// --------------------
								.bus_req	( bus_req	),				// arbiter
								.bus_req_op		( bus_req_op	),
								.bus_req_clc	( bus_req_clc	),
								.halt		( halt 		),				// processor
								.tran_buf_input_sel	( tran_buf_input_sel ),		// bus interface
								//.bus_direction		( bus_direction 	 ),
								.we_flag_vector		( we_flag_vector	 ),					// cache tabe
								.we_addr_vector		( we_addr_vector 	 ),
								.new_flag_vector	( new_flag_vector	 ),

								.snp_error	( snp_error ),
								.wb_active	( wb_active ),
								.pwb_active	( pwb_active ),
								.st			( st 	),
								.sub_st		( sub_st 	),
								.re_st		( re_st 	),
								.re_sub_st	( re_sub_st 	)
							);

endmodule
