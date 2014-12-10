

`ifndef DEFFILE
	`include	"define.v"
`endif

`tscale

module tb_mem_queue;

	/********** Parameter *********/
	parameter	REQUEST_SIZE	= 38;
	parameter	ADDR_WIDTH		= 32;
	parameter	DATA_WIDTH		= 128;
	parameter	QUEUE_SIZE		= 16;	// number of entry
	parameter	QUEUE_SIZE_BIT	= 4;
	parameter	COUNTER_WIDTH	= 10;	
	parameter	CYCLE_NUM_DATA	= 4;

	/********** input *********/
	reg 	clk;
	reg 	rst;
	reg		[1:0]	op;
	reg		pop_en;
	reg		push_en;
	reg		search_en;
	reg		fetch_en;
	reg		[QUEUE_SIZE_BIT	- 1 : 0]	fetch_index;
	reg		[REQUEST_SIZE	- 1 : 0]	buf_in;
	reg		[ADDR_WIDTH		- 1: 0]		search_addr;
	/********** output *********/
	wire	[REQUEST_SIZE 	- 1 : 0]	buf_out;
	wire	[QUEUE_SIZE_BIT	- 1 : 0]	search_match_index;
	wire	[DATA_WIDTH		- 1 : 0]	fetch_data;
	wire	empty;
	wire	full;
	wire	valid_output;
	wire	search_match;
	wire	search_match_receiving;
	/********** model *********/
	mem_queue	u_mem_queue(
					// input
					.clk	( clk	), 
					.rst	( rst	), 
					.op		( op	), 
					.pop_en	( pop_en	), 
					.push_en( push_en	), 
					.search_en	( search_en ), 
					.fetch_en	( fetch_en	),
					.buf_in		( buf_in	), 
					.search_addr( search_addr	), 
					.fetch_index( fetch_index	),
					// output
					.buf_out	( buf_out	), 
					.valid_output	( valid_output	), 
					.search_match	( search_match	), 
					.search_match_index	( search_match_index 	), 
					.search_match_receiving( search_macth_receiving ),
					.fetch_data	( fetch_data	),
					.empty		( empty		), 
					.full
				);
	/********** simulation *********/
	initial begin
	clk = 1;
	rst = 1;
	op 	= 2'b0;
	pop_en	= 0;
	push_en	= 0;
	search_en	= 0;
	fetch_en	= 0;
	fetch_index	= 0;
	
	$readmemh("dram.init",u_mem_queue.data_table);

	#(`CYCLE)	rst = 0;
	#(`CYCLE)	push_en	= 1;			// bus active
				op 		= 0;			// read
				buf_in 	= 38'h2222_0000;	// physical address
	#(`CYCLE)	op  	= 1;			// write
				buf_in	= 38'h0000_0001;	// physical address
	#(`CYCLE)	op 		= 1;
				buf_in	= 38'h1122_3344;	// physical address
	#(`CYCLE)	op 		= 1;
				buf_in	= 38'h5566_7788;	// physical address
	#(`CYCLE)	op 		= 1;
				buf_in	= 38'h9900_AABB;	// physical address
	#(`CYCLE)	op 		= 1;
				buf_in	= 38'hCCDD_EEFF;	// physical address
	#(`CYCLE)	push_en = 0;
				pop_en	= 1;
	#(`CYCLE)	push_en	= 1;
				op		= 0;
				buf_in	= 38'h0000_00044;

	#(`CYCLE)	push_en = 0;

	#(`CYCLE*4)	$stop;
	end
	always	clk = #(`CYCLE/2)	~clk;
	

endmodule

