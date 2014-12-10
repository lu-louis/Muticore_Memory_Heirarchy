/*
Need to retest


Interface:
Operates at PLUS clock
-- input --
@index		:	GPU MEM request index
@index_snp_1:	snooping index from bus L1-L2
@index_snp_2:	snooping index from bus L2-MEM
@we_flag	:	status update enable signal
@new_flag	:	new flag of entry
@we_addr	:	address update enable signal
@new_addr_tag:	new address tag of entry
@new_addr_p	:	new physical address of entry
-- output --
@valid		:	valid signal of CPU/MEM request. as far as read is concern, all other states except for invalid means the same
@flag		:	status of the CPU/MEM request: Invalidate, Shared clean, Owned clean, Own dirty. 
@addr_tag	:	address tag of CPU/MEM request 

@flag_snp_1	:	status of the snooping request 1
@addr_snp_1	:	physical of snooping request 1
@flag_snp_2	:	status of the snooping request 2
@addr_snp_2	:	physical of snooping request 2

*/



`ifndef DEFFILE
	`include "define.v"
`endif

`tscale

module tb_cache_tag_table_rd;

	/********** Parameter *********/
	parameter	NUM_OF_ENTRY	= `_1K;
	parameter	ENTRY_WIDTH		= 10;
	parameter	FLAG_WIDTH		= 2;
	parameter	ADDR_TAG_WIDTH	= 18;		// 28 - 10 
	parameter	ADDR_P_WIDTH	= `_4B;
	parameter	OFFSET_WIDTH	= 2;

	// Data valid flag status
	localparam	INVALID			= 0;
	localparam	SHARED_CLEAN	= 1;
	localparam	OWNED_CLEAN		= 2;
	localparam	OWNED_DIRTY		= 3;

	// Status update signal
	localparam	INVALIDATE_SIGNAL = 1;
	localparam	PREEMPT			  = 2;
	localparam	WRITE_OP		  = 3;

	/********** simulation cycle *********/
	initial begin 
	#(`CYCLE*3)		$stop;	
	end
	/********** input signal *********/	
	reg		[ENTRY_WIDTH - 1 : 0]	index 		= 32'h0;

	reg		[ADDR_P_WIDTH	 - 1 : 0]	snp_addr_1;
	reg		[ADDR_P_WIDTH	 - 1 : 0]	snp_addr_2;
	initial begin 
	end

	reg		we_flag = 0;
	reg 	we_addr = 0;
	initial begin
	#(`CYCLE)	we_flag = 1;	we_addr = 1;
	#(`CYCLE)	we_flag = 0;	we_addr = 0;
	end

	reg 	[1 : 0]			new_flag  = OWNED_DIRTY;
	reg 	[ADDR_TAG_WIDTH - 1 : 0]	new_addr_tag = 18'h2CC;
	reg 	[ADDR_P_WIDTH	- 1 : 0]	new_addr_p	 = 32'hDDD;

	/********** output signal *********/	
	wire	valid;
	wire	[1 : 0]			flag;
	wire	[18 - 1 : 0]	addr_tag;

	wire	snp_match_1;
	wire	snp_match_2;
	wire	[FLAG_WIDTH		- 1 : 0]	snp_flag_1;
	wire	[FLAG_WIDTH		- 1 : 0]	snp_flag_2;
	wire	[ENTRY_WIDTH	- 1 : 0]	snp_index_1;
	wire	[ENTRY_WIDTH	- 1 : 0]	snp_index_2;

	/********** modeling *********/	
	
	cache_tag_table		u_cache_tag_table(
							.index			( index 		),
							.snp_addr_1		( snp_addr_1	),
							.snp_addr_2		( snp_addr_1	),
							.we_flag		( we_flag		),
							.we_addr		( we_addr		),
							.new_flag		( new_flag		),
							.new_addr_tag	( new_addr_tag	),
							.new_addr_p		( new_addr_p	),

							.valid			( valid			),
							.flag			( flag			),
							.addr_tag		( addr_tag		),
							.snp_match_1	( snp_match_1	),
							.snp_match_2	( snp_match_2	),
							.snp_flag_1		( snp_flag_1	),
							.snp_flag_2		( snp_flag_2	),
							.snp_index_1	( snp_index_1	),
							.snp_index_2	( snp_index_2	)
						);

endmodule
