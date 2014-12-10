

`ifndef DEFFILE
	`include "define.v"
`endif


module dram(
		// input
		plusclk, minusclk, rst,		// global
		bus,						// bus
		bus_grant, bus_active,		// arbiter
		// output	
		bus_req, bus_req_type, bus_hold	// arbiter
	);

	/********* parameter *********/
	parameter	BUS_WIDTH		= 38;
	parameter	ADDR_WIDTH		= 32;
	parameter	BUS_DATA_WIDTH	= 32;
	parameter	DATA_WIDTH		= 128;
	parameter	INDEX_WIDTH		= 10;
	parameter	QUEUE_BIT_SIZE	= 4;

	// CACHE BLOCK SIZE = 1K (10 bits)
	parameter	BOUNDARY_UP		= 32'h0000_2000;
	parameter	BOUNDARY_LOW	= 32'h0000_0000;
	/********* interface signal *********/
	// global
	input	plusclk;
	input	minusclk;
	input	rst;

	// bus	
	inout	[BUS_WIDTH		- 1 : 0]	bus;

	// arbiter
	input	bus_active;
	input	bus_grant;

	output	bus_req;
	output	bus_req_type;		// [0] write [1] PWB
	output	bus_hold;

	/********* internal signal *********/
	reg		[BUS_WIDTH		- 1 : 0]	transmitter;
	reg		[BUS_WIDTH		- 1 : 0]	receiver;
	reg		[BUS_DATA_WIDTH	- 1 : 0]	trans_data_reg;
	reg		[BUS_WIDTH		- 1 : 0]	processing_reg;
	reg		[BUS_WIDTH		- 1 : 0]	pending_reg;
	reg		[DATA_WIDTH		- 1 : 0]	data_collect_reg;
	// processing unit
	wire	[1:0]	processing_op;
	// logic
	wire	gather_data;
	wire	data_output_sel;
	wire	[1:0]	data_portion_sel;

	// data block
	wire	dblock_write_enable;
	wire	[DATA_WIDTH 	- 1 : 0]	request_data;
	// queue
	wire	queue_search_enable;
	wire	queue_read_enable;
	wire	queue_write_enable;
	wire	queue_fetch_enable;
	wire	queue_empty;
	wire	pwb_match;
	wire	pwb_receiving;
	wire	[QUEUE_BIT_SIZE	- 1 : 0]	pwb_index;
	wire	[QUEUE_BIT_SIZE	- 1 : 0]	queue_fetch_index;
	wire	[BUS_WIDTH 		- 1 : 0]	new_request;
	wire	[BUS_WIDTH 		- 1 : 0]	next_request;
	wire	[DATA_WIDTH		- 1 : 0]	next_data;
	wire	valid_output;
	wire	search_match;
//	wire	[DATA_WIDTH 	- 1 : 0]	search_data;
	wire	[DATA_WIDTH		- 1 : 0]	queue_data_fetch;


	// contoller <=> interface controller
	wire	bus_request_in;
	wire	bus_request_type_in;
	wire	[5:0]	bus_request_clc_in;
	wire	bus_active;
	wire	bus_get;
	wire	bus_direction;

	// queue	<=> processing unit

	// processing unit
	wire	[ADDR_WIDTH 	- 1 : 0]	processing_addr;
	wire	[INDEX_WIDTH	- 1 : 0]	processing_index;
	wire	[DATA_WIDTH		- 1 : 0]	data_out_all;
	wire	[BUS_DATA_WIDTH	- 1 : 0]	data_out_portion;
	
	assign	bus					= bus_direction	? transmitter : 38'hzzzzzzzzzz;
	assign	queue_write_enable	= ( bus_active && ~bus_grant );
	assign	new_request			= receiver;
	assign	processing_addr		= next_request[31:0];
	assign	processing_index	= next_request[13:4];
	assign	processing_op		= next_request[33:32];
	assign	queue_fetch_index	= pwb_index;


	/********* internal component *********/
	mem_control_unit	
				controller(
					// input
					.clk			( plusclk  ), 
					.rst			( rst		),
					.queue_empty	( queue_empty	), 
					.pwb_match		( pwb_match		),
					.pwb_receiving	( pwb_receiving	),
					.processing_op	( processing_op	), 
					.bus_get		( bus_grant		),
					// output
					.write_enable		( dblock_write_enable	),	// data block 
					.pop_queue			( queue_read_enable		),	// queue	
					.search_enable		( queue_search_enable	),
					.fetch_enable		( queue_fetch_enable	),
					.gather_data		( gather_data			),	// processing unit 
					.data_output_sel	( data_output_sel		),	 
					.data_portion_sel	( data_portion_sel		),
					.bus_request		( bus_req		),	// arbiter interface handler 
					.bus_request_type	( bus_req_type	), 
					.bus_hold			( bus_hold	),
					.bus_direction		( bus_direction )
				);
	mem_queue	#(.BOUNDARY_UP	( BOUNDARY_UP ),	
				  .BOUNDARY_LOW	( BOUNDARY_LOW ) )
				task_queue(
					// input
					.clk			( minusclk	), 
					.rst			( rst	), 
					.op				( receiver[33:32] ),
					.pop_en			( queue_read_enable		), 	// interface handler
					.push_en		( queue_write_enable	), 	// controller
					.search_en		( queue_search_enable	),	// controller
					.fetch_en		( queue_fetch_enable	),
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
	
	cache_block	#( .DATA_WIDTH	(DATA_WIDTH))
				data_block(
					// input
					.index	(processing_index), 
					.we		(dblock_write_enable), 
					.din	(data_collect_reg),
					// output
					.dout	(request_data)
				);

	/********* parameter *********/
	// plusclk
	// receiver
	always @ ( plusclk ) begin
		if( plusclk ) begin	
			/*
			trasmitter[37:32]	<= processing[37:32];
			trasmitter[31:0]	<= data_out_portion;
			*/
			receiver	<= bus;
		end
	end

	// processing unit
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if( rst ) begin
				processing_reg		<= 38'h0;
				data_collect_reg	<= 32'h0;
			end
			else if( valid_output && ~gather_data ) begin
				processing_reg		<= next_request;
				data_collect_reg	<= next_data;
				
			end
			else if( gather_data ) begin
				data_collect_reg	<= queue_data_fetch;
			end
		end
	end
	// transmitter
	always @ ( plusclk ) begin
		if( plusclk ) begin
			if( rst ) begin
				transmitter	<= 38'h0;
			end
			else begin
				// instruction portion
				transmitter[37:32]			<= processing_reg[37:32];
				// data portion
				case(data_output_sel)
				// no pwb
				0:	begin 
					case(data_portion_sel)
					3:	transmitter[31:0]	<= request_data[127:96];		// MSB first
					2:	transmitter[31:0]	<= request_data[95:64];
					1:	transmitter[31:0]	<= request_data[63:32];
					0:	transmitter[31:0]	<= request_data[31:0];
					endcase
				end
				// pwb 
				1: begin
					case(data_portion_sel)		// sending data
					3:	transmitter[31:0]	<= data_collect_reg[127:96];
					2:	transmitter[31:0]	<= data_collect_reg[95:64];
					1:	transmitter[31:0]	<= data_collect_reg[63:32];
					0:	transmitter[31:0]	<= data_collect_reg[31:0];
					endcase
				end
				endcase

			end
		end
	end
	

endmodule
