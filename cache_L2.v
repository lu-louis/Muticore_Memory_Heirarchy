
/*




*/

`ifndef	DEFFILE
	`include "define.v"
`endif


module cache_L2 (
		// input
		plusclk, minusclk, rst,		// global
		bus_grant_0, bus_active_0,	// bus 0
		bus_grant_1, bus_active_1,	// bus 1
		// output
		bus_hold_0, bus_req_0,	// bus 0
		bus_req_type_0,
		bus_hold_1, bus_req_1,	// bus 1
		bus_req_type_1,
		// inout
		bus_0, bus_1
	);

	/********** paramter **********/
	parameter	BUS_WIDTH		= 38;
	parameter	ADDR_WIDTH		= 32;
	parameter	DATA_WIDTH		= 128;
	parameter	DATA_WIDTH_L1	= 32;
	parameter	TAG_WIDTH		= 18;		// 31:14
	parameter	INDEX_WIDTH		= 10;		// 13:4
	parameter	OFFSET_WIDTH	= 2;		//  3:2
	// queue
	parameter	QUEUE_SIZE		= 8;
	parameter	QUEUE_SIZE_BIT	= 3;
	// operation
	localparam	RD				= 2'b00;
	localparam	WR				= 2'b01;
	localparam	PWB				= 2'b10;	
	/********** interface signal **********/
	// global
	input	plusclk;
	input	minusclk;
	input	rst;
	// bus
	inout	[BUS_WIDTH 	- 1 : 0 ]	bus_0;
	inout	[BUS_WIDTH 	- 1 : 0 ]	bus_1;
	// arbiter 
	input			bus_grant_0;
	input			bus_active_0;
	output			bus_hold_0;
	output			bus_req_0;
	output			bus_req_type_0;
//	output	reg		[5:0]	bus_req_clc_0;

	input			bus_grant_1;
	input			bus_active_1;
	output			bus_hold_1;
	output			bus_req_1;
	output			bus_req_type_1;
//	output	reg		[5:0]	bus_req_clc_1;

	/********** internal signal **********/
	/**** bus interface ****/
	reg		[BUS_WIDTH	- 1 : 0]	transmitter_0;
	reg		[BUS_WIDTH	- 1 : 0]	transmitter_1;
	reg		[BUS_WIDTH	- 1 : 0]	receiver_0;
	reg		[BUS_WIDTH	- 1 : 0]	receiver_1;

	reg		[BUS_WIDTH	- 1 : 0]	ready_reg		[1 : 0];	// - .  transmitter
	reg		[DATA_WIDTH	- 1 : 0]	recv_data_buf_1;					// - .	receiver
	reg		[5:0]					recv_counter;
	reg		get_reply;

	wire	[ 1 : 0 ]				data_portion_sel;  
	wire	[ 1 : 0 ]				bus_direction;
	assign	bus_0	= bus_direction[0] ? transmitter_0	: 38'hz;
	assign	bus_1	= bus_direction[1] ? transmitter_1	: 38'hz;

	/**** register between main logic and bus interface ****/
	
	/**** Request processing ****/
	reg		[BUS_WIDTH			- 1	: 0]	processing_info_reg;	// 2 Proc ID + 2 PID + 2 OP + 32 address
	reg		[DATA_WIDTH_L1		- 1 : 0]	processing_data_reg;
	reg		[DATA_WIDTH			- 1 : 0]	new_data;

	// input information
	wire								pop_value_valid;
	wire	[ 1 : 0 ]					processing_proc;
	wire	[ 1 : 0 ]					processing_pid;
	wire	[ 1 : 0 ]					processing_op;
	wire	[ADDR_WIDTH 	- 1 : 0]	processing_addr;
	wire	[TAG_WIDTH  	- 1 : 0]	processing_tag;
	wire	[INDEX_WIDTH	- 1 : 0]	processing_index;
	wire	[ 1 : 0 ]					processing_offset;
	wire	[DATA_WIDTH 	- 1 : 0]	processing_data;

	wire								req_valid_flag;
	wire	[DATA_WIDTH - 1 : 0]		request_data;
	wire	[TAG_WIDTH	- 1 : 0]		req_addr_tag;
	wire	tag_cmp_result;
	wire	valid;

	wire	[ADDR_WIDTH		- 1 : 0]	data_mask	[3:0];

	// queue
	reg		pop_queue;
	reg		push_queue;
	reg		queue_write_enable_reg;

	wire 	queue_read_enable;
	wire	queue_writE_enable;
	wire	queue_search_enable;
	wire	queue_fetch_enable;
	wire	[2:0]						queue_fetch_index;
	wire	[BUS_WIDTH 		- 1 : 0]	new_request;
	wire	[BUS_WIDTH 		- 1 : 0]	next_request;
	wire	[DATA_WIDTH_L1	- 1 : 0]	next_data;
	wire	valid_output;
	wire	pwb_match;
	wire	pwb_receiving;
	wire	[QUEUE_SIZE_BIT	- 1 : 0]	pwb_index;
	wire	[DATA_WIDTH_L1	- 1 : 0]	queue_data_fetch;
	wire	queue_empty;
	wire	queue_full;

	// wire assigning for processing register

	assign	processing_proc = 	processing_info_reg[37:36];
	assign	processing_pid	= 	processing_info_reg[35:34];
	assign	processing_op	= 	processing_info_reg[33:32];
	assign	processing_addr = 	processing_info_reg[31:0];
	assign	processing_tag  = 	processing_info_reg[31:14];		// 16 bits
	assign	processing_index = 	processing_info_reg[13:4];		// 10 bits
	assign	processing_offset= 	processing_info_reg[3:2];		
	assign	processing_data	=  	processing_data_reg;

	assign	snp_addr		=	processing_info_reg[31:0];		// == processing_addr
	
	assign	queue_write_enable	= ( bus_active_0 & ~bus_grant_0);
	assign	queue_fetch_index	= pwb_index;
	assign	new_request			= receiver_0;
	
	assign	data_mask[0]	= 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_00000000;
	assign	data_mask[1]	= 128'hFFFFFFFF_FFFFFFFF_00000000_FFFFFFFF;
	assign	data_mask[2]	= 128'hFFFFFFFF_00000000_FFFFFFFF_FFFFFFFF;
	assign	data_mask[3]	= 128'h00000000_FFFFFFFF_FFFFFFFF_FFFFFFFF;

	/********** internal component **********/
	cacheL2_control_unit 	
				controller(
					// input
					.clk			( plusclk		),
					.rst			( rst			),
					.bus_get_0		( bus_grant_0	),		// arbiter 
					.bus_get_1		( bus_grant_1	),
					.get_reply		( get_reply		),		// logic
					.queue_empty	( queue_empty	),
					.queue_full		( queue_full	),		// queue
					.pwb_addr_match	( pwb_match		),
					.pwb_data_recv	( ~pwb_receiving ),
					.hit			( hit			), 
					.processing_op	( processing_op	),		// logic
					// output
					.bus_req_0			( bus_req_0		), 
					.bus_req_1			( bus_req_1		),		// arbiter
					.bus_req_type_0		( bus_req_type_0 ), 
					.bus_req_type_1 	( bus_req_type_1 ),
					.bus_hold_0			( bus_hold_0	), 
					.bus_hold_1			( bus_hold_1	),
					.bus_direction_0	( bus_direction[0]	), 					// bus interface
					.bus_direction_1	( bus_direction[1]	),	
					.transmitter_input_sel	( transmitter_input_sel	), 		
					.data_portion_sel	( data_portion_sel	),
					.data_output_sel	( data_output_sel	),					// cache_table
					.data_input_sel		( data_input_sel	),	
					.write_enable		( write_enable		),	
					.write_enable_tag	( write_enable_tag	),
					.new_flag			( new_flag			),
					.pop_queue			( queue_read_enable	),							// queue
					.queue_search_enable	( queue_search_enable	),
					.queue_fetch_enable		( queue_fetch_enable	)
				);
	// queue
	L2_queue	#(.QUEUE_SIZE	(QUEUE_SIZE),
				  .QUEUE_SIZE_BIT	(QUEUE_SIZE_BIT))
				task_queue(
					// input
					.clk			( minusclk	), 
					.rst			( rst	), 
					.op				( receiver_0[33:32] ),
					.pop_en			( queue_read_enable		), 	// interface handler
					.push_en		( queue_write_enable	), 	// controller
					.search_en		( queue_search_enable	),	// controller
					.fetch_en		( queue_fetch_enable	),	// controller
					.fetch_index	( queue_fetch_index		),	// connect to pwb_index
					.buf_in			( new_request		), 		// receiver
					.search_addr	( processing_addr	),		// processing unit
					// output
					.buf_out		( next_request	), 			// processing uni
					.dout			( next_data 	),
					.valid_output	( valid_output	), 			// 
					.search_match	( pwb_match	),
					.search_match_receiving	( pwb_receiving ),
					.search_match_index	( pwb_index	),
					.fetch_data		( queue_data_fetch	), 
					.empty			( queue_empty	), 
					.full			( queue_full	)
				);

	// cache table
	cache_block		#(.DATA_WIDTH	(DATA_WIDTH))
					data_block(
						// input
						.index	( processing_index	),		// processing unit 
						.we		( write_enable		), 
						.din	( new_data			),
						// output
						.dout	( request_data		)
					);
	
	tag_table_L2	tag_block(
						// input	
						.index		( processing_index	),
						.we_flag	( write_enable 		),
						.we_tag		( write_enable_tag	),
						.new_flag	( new_flag			),	// entry status
						.new_tag	( processing_tag  	),	// upper physical address 
						// output
						.req_flag	( req_valid_flag 	),
						.req_tag	( req_addr_tag 		)
					);

	// data match generation
	comparator	#( .DATA_WIDTH (TAG_WIDTH) )
				tag_match_comparator(
					.din1	( processing_tag ),
					.din2	( req_addr_tag 	 ),
					.equal	( tag_cmp_result )
				);
	comparator	#( .DATA_WIDTH (2) )
				read_op_comparator(
					.din1	( processing_op ),
					.din2	( 2'b00 ),
					.equal	( read_op )
				);
	and			hit_checker	(
					hit,
					req_valid_flag, 
					tag_cmp_result
				);

	/********* Logic *********/
	/**** plusclk ****/
	/**** init ****/
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if(rst) begin
				recv_counter <= 0;
			end
		end
	end

	/**** bus interface ****/
	// bus 0 signal
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if( rst ) begin
				transmitter_0 	<= 38'h0;
				receiver_0 		<= 38'h0;
				transmitter_1	<= 38'h0;
				receiver_1		<= 38'h0;
			end
			else begin
				transmitter_0	<= 	ready_reg[0];
				if( ~bus_grant_0 && ~bus_direction[0] )		receiver_0	<=	bus_0;
				else 										receiver_0	<= 38'hz;
				transmitter_1	<=	ready_reg[1];
				receiver_1		<=	bus_1;
			end			
		end
	end
	// queue
	always @ ( plusclk ) begin
		if( plusclk ) begin
			queue_write_enable_reg	<= (bus_active_0 && ~bus_grant_0);
		end
	end

	// processing unit
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if( rst ) begin
				processing_info_reg		<= 38'h0;
				processing_data_reg		<= 32'h0;
			end
			else if( valid_output ) begin
				processing_info_reg		<= next_request;
				if(~data_output_sel)	
					processing_data_reg	<= next_data;
				else
					processing_data_reg	<= queue_data_fetch;
			end
		end
	end
	
	/*********** minusclk ***********/
	/**** receiving end ****/
	always @ ( minusclk ) begin
		if( minusclk ) begin
			if( receiver_1[37:36] == processing_proc 	&& 	// match processer ID
				receiver_1[35:34] == processing_pid 	&&			// match process ID
				receiver_1[33:32] == processing_op  	&&			// match operation
				bus_active_1 && ~bus_grant_1 &&
				recv_counter == 0	)			
				recv_counter <= 4;
			else if( recv_counter ) begin
				recv_counter <= recv_counter - 1;
				if(recv_counter == 1)		// next cycle is ending
					get_reply	<= 1'b1;
				case( recv_counter )
				4:	recv_data_buf_1[127:96]	= receiver_1[31:0];
				3:	recv_data_buf_1[95:64]	= receiver_1[31:0];
				2:	recv_data_buf_1[63:32]	= receiver_1[31:0];
				1:	recv_data_buf_1[31:0]	= receiver_1[31:0];	
				endcase
			end
			else begin
				get_reply	<= 1'b0;
			end
		end
	end
	
	/**** transmitting end ****/
	// ready reg 1 loading
	always @ ( minusclk ) begin
		if( minusclk ) begin
			// bus 0
			case( processing_offset )
			0: 	ready_reg[0]	<=  { processing_proc, processing_pid, processing_op, request_data[31:0] };
			1:	ready_reg[0]	<=  { processing_proc, processing_pid, processing_op, request_data[63:32] };
			2:	ready_reg[0]	<=  { processing_proc, processing_pid, processing_op, request_data[95:64] };
			3:	ready_reg[0]	<=  { processing_proc, processing_pid, processing_op, request_data[127:96] };
			endcase
			// bus 1


			// if send address
			if( ~data_output_sel )
				ready_reg[1]	<= { processing_proc, processing_pid, processing_op , processing_data_reg};
			// if send data
			else
				ready_reg[1]	<= { processing_proc, processing_pid, processing_op ,
									( data_mask[processing_offset] & request_data ) | ( processing_data_reg << (processing_offset*32) ) >> (data_portion_sel*32) };
		
		end
	end
	
	/**** cache table ****/
	// load update data
	always @ ( minusclk ) begin
		if( minusclk ) begin
			// if write operatoin
			if( ~data_input_sel ) begin
				if( processing_op == WR || processing_op == PWB )
					new_data	= ( data_mask[processing_offset] & request_data ) | ( processing_data_reg << (processing_offset*32) );
				else if ( processing_op == RD )
					new_data	= new_data;
			end
			else begin
				new_data <= recv_data_buf_1;
			end
		end
	end

endmodule
