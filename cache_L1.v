/*
Note: 
- Naming principle
	register:
		interface: end with buf (buffer) or loader
		internal : end with reg
	wire:
		end with everything else
*/

`ifndef DEFFILE
	`include "define.v"
`endif



module	cache_L1(
	// input
	plusclk, minusclk, rst, 			// global
	next_inst, din_proc, request,		// processor
	bus_grant, bus_active,				// arbiter
	bus_1,								// bus between L2- mem
	// output
	dout_proc, cache_hit, stall,		// processor
	bus_req, bus_req_type, bus_hold,	// arbiter
	// inout
	bus_0
	);
	/*********** Parameter **********/
	// 2b Processor ID + 2b Process ID + 2b Operation + 32 Addr/Data
	parameter	BUS_WIDTH			= 38;
	parameter	ADDR_WIDTH			= 32;
	parameter	OFFSET_WIDTH		= 2;	// [1:0]
	parameter	ADDR_INDEX_WIDTH	= 10;	// [11:2]
	parameter	ADDR_TAG_WIDTH		= 16;	// [27:12]		[27:26] pid
	parameter	ADDR_V_WIDTH		= 26;	// 28 - 2(offset)
	parameter	DATA_WIDTH			= `_4B;
	parameter	DATA_PROC_WIDTH		= `_1B;
	parameter	FLAG_WIDTH			= 2;
//	parameter	LRU_WIDTH			= 2;

	parameter	PROCESSOR_ID_WIDTH	= 2;
	parameter	PROCESS_ID_WIDTH	= 2;
	parameter	OPERATION_ID_WIDTH	= 2;
	localparam	WAY_ASSOCIATIVE		= 4;


	/*********** Interface signal **********/
	// global
	input	plusclk;
	input	minusclk;
	input	rst;
	// processor
	input	[ADDR_WIDTH 	- 1 : 0]	next_inst;
	input	[DATA_PROC_WIDTH- 1 : 0]	din_proc;
	input								request; 		// instruction might not requires operation. can be decoded in operation
	output	[DATA_PROC_WIDTH- 1 : 0]	dout_proc;
	output	cache_hit;
	output	stall;

	// arbiter
	input	bus_grant;
	input	bus_active;
	output	bus_req;
	output	bus_req_type;
	output	bus_hold;

	// bus
	inout	[BUS_WIDTH - 1 : 0]		bus_0;		// bus between L1 - L2, read / write / snoop
	input	[BUS_WIDTH - 1 : 0]		bus_1;		// bus between L2 - memeory, snooping only.

	/*********** Internal signal**********/
	/**** processor ****/
	// -- instruction
	reg		[ADDR_WIDTH		- 1 : 0]	inst_loader;		// + . reg for loading instruction from processor
	reg		[PROCESSOR_ID_WIDTH-1:0]	proc_id_reg;		// - . processor id. 			constant once load. Reload when reset
	reg		[PROCESS_ID_WIDTH- 1: 0]	pid_reg;
	reg		[OFFSET_WIDTH	- 1 : 0]	offset_reg;			// - . reg for storing offset	use to select data portion
	reg		[1:0]						op_reg;				// - . operation				use to determine SM actoin
	reg		[ADDR_TAG_WIDTH	- 1 : 0]	req_addr_tag_reg;	// - . process id is included, 	use to find data
	reg		[ADDR_V_WIDTH	- 1 : 0]	req_addr_v_reg;		// - . offset not included		use to find corresponding PA
	reg									hit_reg;
	reg									stall_reg;
	reg									write_delay_flag;

	wire	[1:0]						inst_operation_type;// - => + . To controller
	wire	[1:0]						proc_id;
	// -- data
	reg		[DATA_WIDTH		- 1 : 0]	din_proc_loader;	// + . 
	reg		[DATA_PROC_WIDTH -1 : 0]	dout_proc_buf;		// + . send data to processor

	/**** bus interface ****/	
	reg		[BUS_WIDTH 		- 1 : 0]	transmitter;		// + . transmission buffer to L2 cache
	reg		[BUS_WIDTH 		- 1 : 0]	receiver_0;			// + . receive from bus L1-L2
	reg		[BUS_WIDTH		 -1 : 0]	receiver_1;			// + . receive from bus L2-memory
	reg		[BUS_WIDTH 		- 1 : 0]	receiver_buf_0;		// - . receive buffer from bus L1-L2
	reg		[BUS_WIDTH		 -1 : 0]	receiver_buf_1;		// - . receive buffer from bus L2-memory

	reg		get_reply;
	// only for bus 0. Need to transmit
	wire								bus_direction;
	wire								transmitter_input_sel;	// selection of address / data						
	wire	[ 1 : 0 ]					transmitter_addr_sel;	// selection of request addr [read miss], replace addr [preempt], 
															// snoop 1 addr, snoop 2 addr
	wire	[BUS_WIDTH		- 1 : 0]	next_tran_data;		// next transmission data on to bus1
	wire	[BUS_WIDTH 		- 1 : 0]	tran_address;		// address
	wire	[BUS_WIDTH 		- 1 : 0]	tran_data;			// data value
	wire	[BUS_WIDTH 		- 1 : 0]	tran_value;			// transfer value ( result of selection of the above two wire signal )

	/**** cache table ****/
	// cache table - input
	reg		[DATA_WIDTH		- 1 : 0]	new_data_reg;		// - . reg for update cache table input
															// need to load the data first, replace the data and post it
	wire	[DATA_WIDTH		- 1 : 0]	data_selection_mask	[WAY_ASSOCIATIVE - 1 : 0];

	// cache table - output
	reg		[FLAG_WIDTH		- 1 : 0]	flag_reg			[WAY_ASSOCIATIVE - 1 : 0];		// - . data status: INV, SC, OC, OD, 
	reg		[ADDR_TAG_WIDTH - 1 : 0]	addr_tag_reg		[WAY_ASSOCIATIVE - 1 : 0];		// - . address tag
	reg		[ADDR_WIDTH 	- 1 : 0]	addr_pa_reg			[WAY_ASSOCIATIVE - 1 : 0];		// - . address tag
	reg		[DATA_WIDTH		- 1 : 0]	data_reg			[WAY_ASSOCIATIVE - 1 : 0];		// - . data

	// cache table - input retrieve entry
	wire	[ADDR_INDEX_WIDTH-1 : 0]	req_addr_index;
	wire 	[DATA_WIDTH		- 1 : 0]	new_data_value;
	wire	[ADDR_TAG_WIDTH	- 1 : 0]	req_addr_tag;	
	// cache tag  table	- input update entry
	wire	[WAY_ASSOCIATIVE - 1 : 0]	write_enable_flag;	// drive by control unit. flag write enable
	wire	[WAY_ASSOCIATIVE - 1 : 0]	write_enable_addr;	// drive by control unit
	wire	[WAY_ASSOCIATIVE - 1 : 0]	write_enable_data;
	wire	[WAY_ASSOCIATIVE*2-1 : 0]	new_flag_vector;
	wire	[ADDR_TAG_WIDTH  - 1 : 0]	new_addr_tag;
	wire	[ADDR_WIDTH		 - 1 : 0]	new_addr_p;
	wire	[ 1 : 0 ]					data_index_sel;
	wire								data_din_sel;

	// cache tag table - output
	wire	[WAY_ASSOCIATIVE - 1 : 0]	valid_entry;
	wire	[FLAG_WIDTH		 - 1 : 0]	flag 			[WAY_ASSOCIATIVE - 1 : 0];
	wire	[ADDR_TAG_WIDTH	 - 1 : 0]	addr_tag		[WAY_ASSOCIATIVE - 1 : 0];
	wire	[ADDR_WIDTH  	 - 1 : 0]	addr_pa			[WAY_ASSOCIATIVE - 1 : 0];
	wire	[FLAG_WIDTH*WAY_ASSOCIATIVE - 1 : 0]	flag_vector;
	// cache data table - output
	wire	[DATA_WIDTH		 - 1 : 0]	entry_data		[WAY_ASSOCIATIVE - 1 : 0];			// drive by cache entry buffer

	/**** data selection ****/
	// logic wire
	reg		[DATA_WIDTH		- 1 : 0]	entry_data_sel_reg;	// entry data of selected block. load from from data_sel_table, 

	wire								valid_entry_all;	// valid entry check
	wire	[WAY_ASSOCIATIVE - 1 : 0]	addr_tag_cmp;		// tag match check [individual]
	wire								addr_tag_cmp_all;	// tag match check
	wire	[1:0]						sel_data_block;		// stage 1 mux sel signal. based on the tag matching result, 
															// select the correct data block
	wire	[1:0]						sel_data_offset;	// stage 2 mux sel signal. based on the offset, 
															// select the correct portion of data for dout_proc
	wire	[DATA_WIDTH 	- 1 : 0]	data_sel_table;		// entry data with size of cache entry
	wire	[DATA_PROC_WIDTH- 1 : 0]	data_sel_offset;	// final selected entry data [8 bit]
	wire	[ADDR_WIDTH		- 1 : 0]	replace_entry_pa;	// final selected entry physical address 
															// (retrieved if write back is required)
	wire	[DATA_WIDTH		 - 1 : 0]	data_candidate	[WAY_ASSOCIATIVE - 1 : 0];			// drive by cache entry buffer
	wire	[DATA_PROC_WIDTH - 1 : 0]	data_candidate_small	[WAY_ASSOCIATIVE - 1 : 0];			// drive by cache entry buffer

	/**** controller ****/
	// to arbiter interface controller
	wire	bus_req_internal;
	wire	bus_req_op_internal;
	wire	[5:0]	bus_req_clc_internal;

	// debug
	wire	snp_error;
	wire	wb_active;
	wire	pwb_active;
	wire	[3:0]	FSM_state;
	wire	[3:0]	FSM_sub_state;
	wire	[3:0]	FSM_return_state;
	wire	[3:0]	FSM_return_sub_state;

	/**** snooping ****/
	// snoop request
	reg		[ADDR_WIDTH		- 1 : 0]	snp_addr_reg_1		[WAY_ASSOCIATIVE - 1 : 0];
	reg		[ADDR_WIDTH		- 1 : 0]	snp_addr_reg_2		[WAY_ASSOCIATIVE - 1 : 0];
	reg		[FLAG_WIDTH 	- 1 : 0]	snp_flag_reg_1		[WAY_ASSOCIATIVE - 1 : 0];
	reg		[FLAG_WIDTH 	- 1 : 0]	snp_flag_reg_2		[WAY_ASSOCIATIVE - 1 : 0];
	// snoop : cache tag table - input
	wire	[ADDR_WIDTH		 - 1 : 0]	snp_addr_1;	
	wire	[ADDR_WIDTH		 - 1 : 0]	snp_addr_2;
	// snoop : cache tag table - output
	wire	[WAY_ASSOCIATIVE - 1 : 0]	snp_block_hit_1;
	wire	[WAY_ASSOCIATIVE - 1 : 0]	snp_block_hit_2;
	wire	[FLAG_WIDTH		 - 1 : 0]	snp_flag_1		[WAY_ASSOCIATIVE - 1 : 0];
	wire	[FLAG_WIDTH		 - 1 : 0]	snp_flag_2		[WAY_ASSOCIATIVE - 1 : 0];
	wire	[ADDR_INDEX_WIDTH- 1 : 0]	snp_index_1		[WAY_ASSOCIATIVE - 1 : 0];
	wire	[ADDR_INDEX_WIDTH- 1 : 0]	snp_index_2		[WAY_ASSOCIATIVE - 1 : 0];
	// snoop : vector to controller
	wire	[14 - 1 : 0]				snp_vector_1;		// 1 snoop match + 1 read/write + 4 block hit + 8 entry flag value
	wire	[14 - 1 : 0]				snp_vector_2;
	// snoop : information from bus
	wire	[1:0]	snp_pid_1;
	wire	[1:0]	snp_pid_2;
	wire	[1:0]	snp_op_type_1;
	wire	[1:0]	snp_op_type_2;
	// logic wire
	wire	snp_proceed_1;
	wire	snp_proceed_2;
	wire	[1:0]	snp_proc_id_1;
	wire	[1:0]	snp_proc_id_2;
	wire	snp_match_1;
	wire	snp_match_2;
	wire	snp_proc_id_check_1;
	wire	snp_proc_id_check_2;
	wire	[FLAG_WIDTH*WAY_ASSOCIATIVE - 1 : 0] 	snp_flag_vector_1;
	wire	[FLAG_WIDTH*WAY_ASSOCIATIVE - 1 : 0]	snp_flag_vector_2;

	/**** MMU ****/
	wire	[ADDR_V_WIDTH				- 1 : 0] 	request_va;			// input of MMU
	wire	[ADDR_WIDTH	- OFFSET_WIDTH	- 1 : 0]	request_pa;			// output of MMU

	/**** reset ****/
	reg	[3:0]	delay_counter;

//	wire	[WAY_ASSOCIATIVE - 1 : 0]	addr_tag_comp;		// drive by comparator

	/*********** Wiring **********/
	// processor - external
	assign	req_addr_index 			= inst_loader[11:2];		// request data entry index. 10 bits
	assign	proc_id					= inst_loader[31:30];
	assign	dout_proc				= dout_proc_buf;
	assign	cache_hit				= hit_reg;
	//assign	stall					= stall_reg;

	// processor - internal
	assign	inst_operation_type		= op_reg;				// to controller
	assign 	new_data_value			= new_data_reg;			
	assign	sel_data_offset			= offset_reg;			// data offset 
	assign	snp_addr_1				= receiver_0[11:2];			// 
	assign 	snp_addr_2				= receiver_1[11:2];
	assign	request_va				= req_addr_v_reg;

	assign	req_addr_tag			= req_addr_tag_reg;

	// cache table
	assign	new_addr_tag	= inst_loader[27:12];
	assign	new_addr_p		= request_pa;
	/*
	assign	flag[0]			= flag_reg[0];
	assign	flag[3]			= flag_reg[1];
	assign	flag[2]			= flag_reg[2];
	assign	flag[1]			= flag_reg[3];
	*/
	assign	data_candidate[0]		= data_reg[0];
	assign	data_candidate[1]		= data_reg[1];
	assign	data_candidate[2]		= data_reg[2];
	assign	data_candidate[3]		= data_reg[3];

	assign	data_candidate_small[0]	= data_sel_table[DATA_WIDTH -  1 : DATA_WIDTH -  8];
	assign	data_candidate_small[1]	= data_sel_table[DATA_WIDTH -  9 : DATA_WIDTH - 16];
	assign	data_candidate_small[2]	= data_sel_table[DATA_WIDTH - 17 : DATA_WIDTH - 24];
	assign	data_candidate_small[3]	= data_sel_table[DATA_WIDTH - 25 : DATA_WIDTH - 32];

	assign  data_selection_mask[0]	= 32'hFFFF_FF00;
	assign  data_selection_mask[1]	= 32'hFFFF_00FF;
	assign  data_selection_mask[2]	= 32'hFF00_FFFF;
	assign  data_selection_mask[3]	= 32'h00FF_FFFF;

	// Bus signal between L1 - L2 
	assign 	bus_0	= bus_direction ? transmitter : 38'hz;		// direction selection: [1] transmit [0] receive, 
																// set to high impetance and be driven by other device


	assign	flag_vector			= { flag[3], flag[2], flag[1], flag[0]};
	assign	snp_flag_vector_1	= { snp_flag_1[3], snp_flag_1[2], snp_flag_1[1], snp_flag_1[0] };
	assign	snp_flag_vector_2	= { snp_flag_2[3], snp_flag_2[2], snp_flag_2[1], snp_flag_2[0] };
	assign	snp_vector_1		= { snp_proceed_1, snp_op_type_1, snp_block_hit_1, snp_flag_vector_1 };
	assign	snp_vector_2		= { snp_proceed_2, snp_op_type_2, snp_block_hit_2, snp_flag_vector_2 };

	/*********** Interface component **********/
	/****** Cache control unit ******/
	cacheL1_control_unit	controller(
							// input
							.clk		( plusclk	), 				// global
							.rst		( rst	), 	
							.op			( inst_operation_type ),	// processor
							.hit		( hit	),				// internal logic
							.bus_get	( bus_grant	), 				// arbiter
							.get_reply	( get_reply	),				// bus interface
							.sel_block_in	( sel_data_block ),		// cache table
							.flag		( flag_vector 	),						
							.snp_1		( snp_vector_1 	), 
							.snp_2		( snp_vector_2 	),			// snoop

							// output
							.bus_req		( bus_req		), 		// arbiter
							.bus_req_type	( bus_req_type	),
//							.bus_req_clc 	( bus_req_clc_internal	), 		
							.bus_hold		( bus_hold		),
							.bus_direction	( bus_direction	),
							.halt			( stall 			),				// processor
							.transmitter_input_sel 	( transmitter_input_sel ),	// bus_interface
							.transmitter_addr_sel	( transmitter_addr_sel	),
							.we_flag_vector		( write_enable_flag ),			// cache table
							.we_addr_vector		( write_enable_addr	),
							.we_data_vector		( write_enable_data ), 
							.new_flag_vector	( new_flag_vector	),			// new flag vector
							.data_index_sel		( data_index_sel 	),
							.data_din_sel		( data_din_sel 		),

							// debug
							.snp_error	( snp_error		), 
							.wb_active	( wb_active		),
							.pwb_active ( pwb_active	),
							.st			( FSM_state				), 
							.sub_st		( FSM_sub_state 		), 
							.re_st 		( FSM_return_state		),
							.re_sub_st	( FSM_return_sub_state	)
						);
	/****************************************************************************************************************/
	/****** Cache data storage unit ******/
	// Cache data block : 4 way => 4 table 
	cache_block			data_block_0(
							.index		( req_addr_index 	 ),	// index	: from instruction regiseter
							.we			( write_enable_data[0] 	 ),	// we		: from control unit. write enable
							.din		( new_data_value 	 ),	// din		: from receive buffer or data_proc register. 

							.dout		( entry_data[0]		 )
						);
	cache_block			data_block_1(
							.index		( req_addr_index 	 ),	// index	: from instruction regiseter
							.we			( write_enable_data[1] 	 ),	// we		: from control unit. write enable
							.din		( new_data_value 	 ),	// din		: from receive buffer or data_proc register. 

							.dout		( entry_data[1]		 )
						);					
	cache_block			data_block_2(
							.index		( req_addr_index 	 ),	// index	: from instruction regiseter
							.we			( write_enable_data[2] 	 ),	// we		: from control unit. write enable
							.din		( new_data_value 	 ),	// din		: from receive buffer or data_proc register. 

							.dout		( entry_data[2]		 )
						);
	cache_block			data_block_3(
							.index		( req_addr_index 	 ),	// index	: from instruction regiseter
							.we			( write_enable_data[3] 	 ),	// we		: from control unit. write enable
							.din		( new_data_value 	 ),	// din		: from receive buffer or data_proc register. 

							.dout		( entry_data[3]		 )
						);

	// Cache tag block : 4 way => 4 table					
	cache_tag_table		tag_table_0(
							.index		( req_addr_index 	),			// index	: from instruction register
							.snp_addr_1	( snp_addr_1 		),
							.snp_addr_2	( snp_addr_2 		),
							.we_flag	( write_enable_flag[0]	), 		// we_flag	: from control unit. write new flag enable
							.new_flag	( new_flag_vector[1:0]  ),		// new_flag	: from control unit. new flag of entry
							.we_addr	( write_enable_addr[0] 	 ), 	// we_addr	: from control unit. 
							.new_addr_tag	( new_addr_tag	 	),
							.new_addr_p		( new_addr_p 	 	),

							.valid		( valid_entry[0] 	),
							.flag		( flag[0] 			),
							.addr_tag	( addr_tag[0] 		),
							.addr_pa	( addr_pa[0]		),
							.snp_match_1( snp_block_hit_1[0]	),
							.snp_match_2( snp_block_hit_2[0]	),
							.snp_flag_1	( snp_flag_1[0] 	),
							.snp_flag_2	( snp_flag_2[0] 	),
							.snp_index_1( snp_index_1[0] ),	// index_snp: from receiver buffer
							.snp_index_2( snp_index_2[0] )	// index_snp: from receiver buffer
						);


	cache_tag_table		tag_table_1(
							.index			( req_addr_index 	),			// index	: from instruction register
							.snp_addr_1		( snp_addr_1		),
							.snp_addr_2		( snp_addr_2 		),
							.we_flag		( write_enable_flag[1]	),		// we_flag	: from control unit. write new flag enable
							.new_flag		( new_flag_vector[3:2] 	),		// new_flag	: from control unit. new flag of entry
							.we_addr		( write_enable_addr[1] 	 ), 		// we_addr	: from control unit. 
							.new_addr_tag	( new_addr_tag	 	),
							.new_addr_p		( new_addr_p 	 	),
	
							.valid			( valid_entry[1] 	),
							.flag			( flag[1] 			),
							.addr_tag		( addr_tag[1] 		),
							.addr_pa		( addr_pa[1]		),
							.snp_match_1	( snp_block_hit_1[1]	),
							.snp_match_2	( snp_block_hit_2[1]	),
							.snp_flag_1		( snp_flag_1[1] 	),
							.snp_flag_2		( snp_flag_2[1] 	),
							.snp_index_1	( snp_index_1[1] ),	// index_snp: from receiver buffer
							.snp_index_2	( snp_index_2[1] )	// index_snp: from receiver buffer
						);
	
	cache_tag_table		tag_table_2(
							.index			( req_addr_index 	),	// index	: from instruction register
							.snp_addr_1		( snp_addr_1 		),
							.snp_addr_2		( snp_addr_2 		),
							.we_flag		( write_enable_flag[2]	), 		// we_flag	: from control unit. write new flag enable
							.new_flag		( new_flag_vector[5:4] 	),		// new_flag	: from control unit. new flag of entry
							.we_addr		( write_enable_addr[2] 	 ), 		// we_addr	: from control unit. 
							.new_addr_tag	( new_addr_tag	 	),
							.new_addr_p		( new_addr_p 	 	),

							.valid			( valid_entry[2] 	),
							.flag			( flag[2] 			),
							.addr_tag		( addr_tag[2] 		),
							.addr_pa		( addr_pa[2]		),
							.snp_match_1	( snp_block_hit_1[2]	),
							.snp_match_2	( snp_block_hit_2[2]	),
							.snp_flag_1		( snp_flag_1[2] 	),
							.snp_flag_2		( snp_flag_2[2] 	),
							.snp_index_1	( snp_index_1[2] ),	// index_snp: from receiver buffer
							.snp_index_2	( snp_index_2[2] )	// index_snp: from receiver buffer
						);
		
	cache_tag_table		tag_table_3(
							.index			( req_addr_index 	),			// index	: from instruction register
							.snp_addr_1		( snp_addr_1 		),
							.snp_addr_2		( snp_addr_2 		),
							.we_flag		( write_enable_flag[3]	), 		// we_flag	: from control unit. write new flag enable
							.new_flag		( new_flag_vector[7:6] 	),		// new_flag	: from control unit. new flag of entry
							.we_addr		( write_enable_addr[3] 	 ), 		// we_addr	: from control unit. 
							.new_addr_tag	( new_addr_tag	 	),
							.new_addr_p		( new_addr_p 	 	),

							.valid			( valid_entry[3] 	),
							.flag			( flag[3] 			),
							.addr_tag		( addr_tag[3] 		),
							.addr_pa		( addr_pa[3]		),
							.snp_match_1	( snp_block_hit_1[3]	),
							.snp_match_2	( snp_block_hit_2[3]	),
							.snp_flag_1		( snp_flag_1[3] 	),
							.snp_flag_2		( snp_flag_2[3] 	),
							.snp_index_1	( snp_index_1[3] ),	// index_snp: from receiver buffer
							.snp_index_2	( snp_index_2[3] )	// index_snp: from receiver buffer
						);
	/****************************************************************************************************************/
	/****** Data selection and matching section ******/
	/*
		comparator for 4 cache table
		addr_tag_cmp[x]	= compare ( req_addr_tag, addr_tag[x] );
		
	*/
	comparator	#( .DATA_WIDTH (ADDR_TAG_WIDTH) )	
				tag_cmp_0(
					.din1	( req_addr_tag 	),
					.din2	( addr_tag[0] 	),
					.equal	( addr_tag_cmp[0] )
				);

	comparator	#( .DATA_WIDTH (ADDR_TAG_WIDTH) )	
				tag_cmp_1(
					.din1	( req_addr_tag 	),
					.din2	( addr_tag[1] 	),
					.equal	( addr_tag_cmp[1] )
				);

	comparator	#( .DATA_WIDTH (ADDR_TAG_WIDTH) )	
				tag_cmp_2(
					.din1	( req_addr_tag 	),
					.din2	( addr_tag[2] 	),
					.equal	( addr_tag_cmp[2] )
				);

	comparator	#( .DATA_WIDTH (ADDR_TAG_WIDTH) )	
				tag_cmp_3(
					.din1	( req_addr_tag 	),
					.din2	( addr_tag[3] 	),
					.equal	( addr_tag_cmp[3] )
				);
					
	// hit signal generation
	or	valid_data_check (
			valid_entry_all,
			valid_entry[0],
			valid_entry[1],
			valid_entry[2],
			valid_entry[3]
		);

	or	tag_cmp_all	(	
			// output
			addr_tag_cmp_all, 
			// input
			addr_tag_cmp[0], 
			addr_tag_cmp[1], 
			addr_tag_cmp[2], 
			addr_tag_cmp[3]
		);

	and	cache_hit_check (
			// output
			hit,
			// input
			valid_entry_all,
			addr_tag_cmp_all
		);
	
	// selecting the correct portion of the data
	// if all four entry does not match, the first data entry will be selected. since the hit signal is low, it does not matter. 
	encoder_4to2	cmp2sel_transform (
						.in		( addr_tag_cmp	 ),
						.out	( sel_data_block )
					);
	mux_4to1	#( .DATA_WIDTH ( DATA_WIDTH ) )
				data_sel_stage_1(
					.sel	( sel_data_block ),
					.din1	( data_candidate[0] ),
					.din2	( data_candidate[1] ),
					.din3	( data_candidate[2] ),
					.din4	( data_candidate[3] ),
					.dout	( data_sel_table )
				);
	
	mux_4to1	#( .DATA_WIDTH ( DATA_PROC_WIDTH ) )			// !!!!! Not scalable part. Need to be modified
				data_sel_stage_2(
					.sel	( sel_data_offset ),
					.din1	( data_sel_table[DATA_WIDTH - 25 : DATA_WIDTH - 32] ),
					.din2	( data_sel_table[DATA_WIDTH - 17 : DATA_WIDTH - 24] ),
					.din3	( data_sel_table[DATA_WIDTH -  9 : DATA_WIDTH - 16] ),
					.din4	( data_sel_table[DATA_WIDTH -  1 : DATA_WIDTH -  8] ),					
					.dout	( data_sel_offset )
				);
	mux_4to1	#( .DATA_WIDTH ( ADDR_WIDTH ) )
				pa_sel (
					.sel	( sel_data_block ),
					.din1	( addr_pa[0] ),
					.din2	( addr_pa[1] ),
					.din3	( addr_pa[2] ),
					.din4	( addr_pa[3] ),
					.dout	( replace_entry_pa )
				);


	/****** Snooping match check procedure ******/
	/*
		snp_match 			= snp_block_hit_1[0] | snp_block_hit_1[1] | snp_block_hit_1[2] | snp_block_hit_1[3];
		snp_pro_id_check_1	= compare ( proc_id, snp_proc_id_x );
		snp_process_1		= snp_match & snp_pro_id_check_1
	*/
	or	snoop_1_block_hit_check (
			// output
			snp_match_1,
			// input
			snp_block_hit_1[0],
			snp_block_hit_1[1],
			snp_block_hit_1[2],
			snp_block_hit_1[3]
		);

	or	snoop_2_block_hit_check (
			// output
			snp_match_2,
			// input
			snp_block_hit_2[0],
			snp_block_hit_2[1],
			snp_block_hit_2[2],
			snp_block_hit_2[3]
		);

	comparator #(.DATA_WIDTH (2))
				snoop_1_proc_id_checker (
					.din1	( proc_id 		),
					.din2	( snp_proc_id_1  ),
					.equal	( snp_proc_id_check_1 )
				);

	comparator #(.DATA_WIDTH (2))
				snoop_2_proc_id_checker (
					.din1	( proc_id		),
					.din2	( snp_proc_id_2	),
					.equal	( snp_proc_id_check_2 )
				);

	and	snoop_hit_1_proceed_check(
			snp_proceed_1,
			snp_match_1,
			~snp_proc_id_check_1		
		);

	and	snoop_hit_2_proceed_check(
			snp_proceed_2,
			snp_match_2,
			~snp_proc_id_check_2		
		);

	

	/****************************************************************************************************************/
	/****** Memory / bus request  ******/
	// arbiter interaface controller . - 
/*
	arbiter_interface_handler	cache_arbiter_interface_control(
									// input
									.clk			( minusclk 	),
									.rst			( rst		),
									.dev_req		( bus_req_internal		), 	// controller
									.dev_req_type	( bus_req_op_internal	), 	
									.tran_cycle		( bus_req_clc_internal	),		
									.grant			( bus_grant 	),		// arbiter 
									.active			( bus_active 	),
									// output
									.get			( bus_get 		), 		// controller
									.bus_active		( bus_using 	),		
									.request		( bus_req	), 		// arbiter
									.request_type	( bus_req_type	), 	
									.hold			( bus_hold		), 	
									.bus_direction	( bus_direction	)	// bus_interface
								);
*/
	
	mmu 	va2pa	(
				.va		( request_va ),
				.found	( pa_found 	 ),
				.pa		( request_pa )
			);
	// transfer 
	mux_2to1	#( .DATA_WIDTH ( BUS_WIDTH ) )	
				transferDataMUX( 
					.sel	( tran_sel ), 
					.din1	( tran_address ),
					.din2	( tran_data ),
					.dout	( tran_value )
				);
	// 

	/**/



	/****************************************************************************************************************/
	/*********** Logic **********/
	/****** plus clock ******/
	/**** processor ****/
	// load instruction/input data from from interface
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if(rst) begin
				inst_loader		<= 32'h0;
				din_proc_loader	<=  32'h0;
			end
			else if( request ) begin
				inst_loader 			<= next_inst;
				din_proc_loader[7:0] 	<= din_proc;
			end
			else begin
				//$display("processing the same instruction");
			end
		end
	end

	// Output to processor
	always @ ( plusclk ) begin
		if( plusclk ) begin
			// hit
			if( rst )	begin
				hit_reg			<= 1'b1;
				stall_reg		<= 1'b0;
				dout_proc_buf	<= 8'h0;
				delay_counter	<= 1;
//				write_delay_flag = 0;
			end
			else if( delay_counter ) begin
				// it takes a cycle to load the first instruction
				delay_counter <= delay_counter - 1;
			end
			else begin
				hit_reg 		<= hit;
				//stall_reg		<= halt;
				dout_proc_buf	<= data_sel_offset;
//				if( write_delay_flag == 1)
//					write_delay_flag = 0;
			end
		end
	end

	// bus 0 setting. inout port 
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if( rst ) begin
			end
			else begin
				// bus 0
				// receiver
				if( ~bus_grant && ~bus_direction )		receiver_0	<= bus_0;
				else 									receiver_0	<= 38'hz;
	
				// transmitter
				// 38 bit : 2 proc_id, 2 pid, 2 bit op, 32 bit physical address
				transmitter[37:36]	<=  proc_id;				// processor id 
				transmitter[35:34]	<= 	req_addr_v_reg[25:24];	// process id
				transmitter[33:32]	<=	op_reg;
				if( ~transmitter_input_sel ) begin				// address
					//$display("transmitter load addr");
					if		( transmitter_addr_sel == 2'b00 )	// read miss 
						transmitter[31 : 2] <= request_pa;		// result of mmu
					else if ( transmitter_addr_sel == 2'b01 )	// write back 
						transmitter[31 : 2]	<= replace_entry_pa;
					else if ( transmitter_addr_sel == 2'b10 )	// pwb 1
						transmitter[31 : 2]	<= snp_addr_1;
					else if ( transmitter_addr_sel == 2'b11 )	// pwb 1
						transmitter[31 : 2]	<= snp_addr_2;
					transmitter[1:0]		<= offset_reg;
				end
				else begin	// data
					//$display("transmitter load data");
					transmitter[31:0] 		<= entry_data_sel_reg;
				end
	
				// bus 1
				receiver_1	<= bus_1;
			end
		end
	end

	// next data reg
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if(rst)
				new_data_reg	<= 32'hFFFF_FFFF;
			else if ( ~data_din_sel ) begin			// select din processor as new data input
				new_data_reg	<=  ( data_sel_table & data_selection_mask[offset_reg] ) | 
									( din_proc_loader << (offset_reg*8) );
//									( din_proc_loader << ( offset_reg * 2) );
			end
			else if ( bus_active && data_din_sel )begin								// select receiver value as new data input
				new_data_reg	<= 	receiver_buf_0[31:0];
			end
		end
	end

	/****** minus clock ******/
	// Instruction decomposition
	always @ ( minusclk ) begin
		if(  minusclk ) begin
			proc_id_reg	<= inst_loader[31:30];
			op_reg		<= inst_loader[29:28];
			pid_reg		<= inst_loader[29:28];
			offset_reg	<= inst_loader[1:0];

			pid_reg		<= inst_loader[ADDR_WIDTH - 1 : ADDR_WIDTH - 2];
			op_reg		<= inst_loader[ADDR_WIDTH - 3 : ADDR_WIDTH - 4];
			req_addr_tag_reg	<= inst_loader[ 27 : 12];
			req_addr_v_reg		<= inst_loader[ 27 : 2 ];	// 2 bit offset at L1 and 2 bit offset at L2
		end
	end

	// load receiver value
	always @ ( minusclk ) begin
		if( minusclk ) begin
			if( receiver_0[37:36] == proc_id_reg && 	// match processer ID
				receiver_0[35:34] == pid_reg &&			// match process ID
				receiver_0[33:32] == op_reg	)			// match operation
				get_reply	<= 1'b1;
			else
				get_reply	<= 1'b0;
			if( bus_active )
				receiver_buf_0	<= receiver_0;
			receiver_buf_1	<= receiver_1;
		end
	end

	// bus info decomposition
	always @ ( minusclk ) begin
		if( minusclk ) begin
			// bus 1
			/*
			if( ~bus_direction ) begin	// [0] read [1] write
				snp_proc_id_1 	<= recv_buf[37:36];
				snp_pid_1		<= recv_buf[35:34];
				snp_op_type_1	<= recv_buf[33:32];
				snp_addr_1		<= recv_buf[31:0];
			end
			// bus 2
			snp_proc_id_2		<= recv_mem_buf[37:36];
			snp_pid_2			<= recv_mem_buf[35:34];
			snp_op_type_2		<= recv_mem_buf[33:32];
			snp_addr_2			<= recv_mem_buf[31:0];
			*/
		end
	end

	// bus transfer data set


	// Load entry value from cache
	always @ ( minusclk ) begin
		if( minusclk ) begin
			/* data table */
			data_reg[0]			<=	entry_data[0];
			data_reg[1]			<=	entry_data[1];
			data_reg[2]			<=	entry_data[2];
			data_reg[3]			<=	entry_data[3];

			/* tag table */
			// instruction request
			// flag tag
			flag_reg[0]			<= flag[0];
			flag_reg[1]			<= flag[1];
			flag_reg[2]			<= flag[2];
			flag_reg[3]			<= flag[3];
			// address tag
			addr_tag_reg[0]		<= addr_tag[0];
			addr_tag_reg[1]		<= addr_tag[1];
			addr_tag_reg[2]		<= addr_tag[2];
			addr_tag_reg[3]		<= addr_tag[3];
			// physical address
			addr_pa_reg[0]		<= addr_pa[0];
			addr_pa_reg[1]		<= addr_pa[1];
			addr_pa_reg[2]		<= addr_pa[2];
			addr_pa_reg[3]		<= addr_pa[3];

			// snoop request
			// snoop 1
			snp_flag_reg_1[0]	<= snp_flag_1[0];
			snp_flag_reg_1[1]	<= snp_flag_1[1];
			snp_flag_reg_1[2]	<= snp_flag_1[2];
			snp_flag_reg_1[3]	<= snp_flag_1[3];
			snp_addr_reg_1[0]	<= snp_addr_1[0];
			snp_addr_reg_1[1]	<= snp_addr_1[1];
			snp_addr_reg_1[2]	<= snp_addr_1[2];
			snp_addr_reg_1[3]	<= snp_addr_1[3];
			// snoop 2
			snp_flag_reg_2[0]	<= snp_flag_2[0];
			snp_flag_reg_2[1]	<= snp_flag_2[1];
			snp_flag_reg_2[2]	<= snp_flag_2[2];
			snp_flag_reg_2[3]	<= snp_flag_2[3];
			snp_addr_reg_2[0]	<= snp_addr_2[0];
			snp_addr_reg_2[1]	<= snp_addr_2[1];
			snp_addr_reg_2[2]	<= snp_addr_2[2];
			snp_addr_reg_2[3]	<= snp_addr_2[3];

			entry_data_sel_reg 	<= data_sel_table;

		end
	end
endmodule
