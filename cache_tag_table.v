/*


Description:
Pure data table. No logic invovled. 
If snoop data change, the logic is compared at the upper level, it is superior to any other operation. 
It feeds in the snooping address to index and update the status

Interface:
Operates at PLUS clock
-- input --
@index		:	GPU MEM request index
@we_flag	:	status update enable signal
@new_flag	:	new flag of entry
@we_addr	:	address update enable signal
@new_addr_tag:	new address tag of entry
@new_addr_p	:	new physical address of entry
-- output --
@valid		:	valid signal of CPU/MEM request. as far as read is concern, all other states except for invalid means the same
@flag		:	status of the CPU/MEM request: Invalidate, Shared clean, Owned clean, Own dirty. 
@addr_tag	:	address tag of CPU/MEM request 
@addr_pa	:	phyiscal address of CPU/MEM request

@snp_flag_1	:	status of the snooping request 1
@snp_index_1:	physical of snooping request 1
@snp_flag_2	:	status of the snooping request 2
@snp_index_2:	physical of snooping request 2

Note:
- Scenario	: The entry which is going to be filled in with new data, has a match physical address for snooping index.
> Problem	: Output of snooping address is old and trigger action but the entry has already being replaced.
> Solution	: Entry value is updated before output stable. 
> Status	: [Solved]

*/

`ifndef	DEFFILE
	`include "define.v"
`endif

module	cache_tag_table(
	// input
	// clk, rst, 
	index, 
	snp_addr_1, snp_addr_2,
	we_flag, new_flag, 
	we_addr, new_addr_tag, new_addr_p,

	// output
	valid, flag, addr_tag, addr_pa,
	snp_match_1, snp_match_2,
	snp_flag_1, snp_flag_2,
	snp_index_1, snp_index_2
	);
	
	/********** Parameter *********/
	parameter	NUM_OF_ENTRY	= `_1K;
	parameter	ENTRY_WIDTH		= 10;
	parameter	ADDR_TAG_WIDTH	= 16;		// 28 - 10 -2
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

	/********** Interface Signaln *********/
	// general 
	//input	clk;
	//input	rst;

	// CPU/MEM request
	// read
	input	[ENTRY_WIDTH 	- 1	: 0]	index;	// read or write request
	output	reg	valid;
	output	reg	[1:0]	flag;
	output	reg	[ADDR_TAG_WIDTH	- 1 : 0]	addr_tag;
	output	reg	[ADDR_P_WIDTH 	- 1 : 0]	addr_pa;
	// write / update
	input	we_flag;
	input	[1:0]	new_flag;
	input	we_addr;
	input	[ADDR_TAG_WIDTH - 1 : 0]	new_addr_tag;
	input	[ADDR_P_WIDTH 	- 1 : 0]	new_addr_p;

	// snooping request
	input	[ADDR_P_WIDTH	- 1	: 0]	snp_addr_1;
	input	[ADDR_P_WIDTH	- 1	: 0]	snp_addr_2;
	output	reg							snp_match_1;
	output	reg							snp_match_2;
	output	reg	[ENTRY_WIDTH - 1 : 0]	snp_index_1;
	output	reg	[ENTRY_WIDTH - 1 : 0]	snp_index_2;
	output	reg	[1:0]					snp_flag_1;
	output	reg	[1:0]					snp_flag_2;



	/********** internal Signal *********/
	reg		[1:0]						flag_table		[NUM_OF_ENTRY-1:0];
	//reg									LRU_table		[NUM_OF_ENTRY-1:0];
	reg		[ADDR_TAG_WIDTH - 1	: 0]	addr_tag_table	[NUM_OF_ENTRY-1:0];
	reg		[ADDR_P_WIDTH 	- 1	: 0]	addr_p_table 	[NUM_OF_ENTRY-1:0];
	
	integer i,j;

	/********** initialization *********/
	/*
	initial begin 
		$readmemb("cacheL1_tag_table_flag.init"		, flag_table);
		//$readmemb("cacheL1_tag_table_LRU.init"		, LRU_table);
		$readmemh("cacheL1_tag_table_addr_tag.init"	, addr_tag_table);
		$readmemh("cacheL1_tag_table_addr_p.init"	, addr_p_table);
	end
	*/
	/********** Logic *********/
	// write new data flag
	always @ ( * ) begin
		if( we_flag ) begin
			flag_table[index] 		<= new_flag;
		end
		if( we_addr ) begin
			addr_tag_table[index]	<= new_addr_tag;
			addr_p_table[index]		<= new_addr_p;
		end
	end

	// read addr_tag 
	always @ ( * ) begin
		// CPU/MEM request
		if(flag_table[index]!=0)
			valid	<= 1'b1;
		else
			valid	<= 1'b0;
		flag		<= flag_table[index];
		addr_tag	<= addr_tag_table[index];
		addr_pa		<= addr_p_table[index];
	end

	// snooping 1
	always @ ( snp_addr_1 ) begin
		for( i=0 ; i<NUM_OF_ENTRY ; i = i+1) begin
			if( addr_p_table[j] == snp_addr_1 ) begin	// snoop hit
			 	snp_match_1 <= 1'b1;
				snp_flag_1	<= flag_table[i];
				snp_index_1	<= i;
			end
		end
	end
	
	// snooping 2
	always @ ( snp_addr_2 ) begin
		for( j=0 ; j<NUM_OF_ENTRY ; j = j+1 ) begin
			if( addr_p_table[j] == snp_addr_1 ) begin	// snoop hit
			 	snp_match_2 <= 1'b1;
				snp_flag_2	<= flag_table[j];
				snp_index_2	<= i;
			end
		end
	end
endmodule
