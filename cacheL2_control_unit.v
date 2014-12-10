
/***/

`ifndef DEFFILE
	`include "define.v"
`endif

module cacheL2_control_unit (
	// input
	clk, rst,
	bus_get_0, bus_get_1,		// arbiter
	get_reply,					// logic
//	data_ready,					
	queue_empty, queue_full,	// queue
	pwb_addr_match,	
	pwb_data_recv,
	hit, processing_op,			// logic
	// output
	bus_req_0, bus_req_1,				// arbiter
	bus_req_type_0, bus_req_type_1,
	bus_hold_0, bus_hold_1,
	bus_direction_0, bus_direction_1,	// bus interface
	transmitter_input_sel, 		
	data_portion_sel,
	data_output_sel,
	data_input_sel,						// cache_table
	write_enable,	
	write_enable_tag,
	new_flag,
	pop_queue,							// queue
	queue_search_enable,
	queue_fetch_enable
	);

	/********* parameter *********/
	
	parameter	CYCLE_NUM_DATA_0  = 1;	// this is the lower level of bus 0
	parameter	CYCLE_NUM_ADDR_0  = 1;	// does not care about cycle ratio

	parameter	CYCLE_NUM_RATIO_1 = 4;
	parameter	CYCLE_NUM_ADDR_1  = 1 * CYCLE_NUM_RATIO_1;
	parameter	CYCLE_NUM_DATA_1  = 4 * CYCLE_NUM_RATIO_1;	

	localparam	RD				= 2'b00;
	localparam	WR				= 2'b01;
	localparam	PWB				= 2'b10;
	// STATE MACHINE
	localparam	IDLE			= 0;
	localparam	LOAD_REQUEST	= 1;
	localparam	READ_HIT		= 2;
	localparam	READ_MISS		= 3;
	localparam	WRITE_HIT		= 4;
//	localparam	WRITE_MISS		= 6;	// READ MISS+ WRITE_HIT
//	localparam	PWB_BUS_0		= 6;
//	localparam	PWB_BUS_1		= 7;

	localparam	CHECK_QUEUE		= 0;	// IDLE
	localparam	DECODING		= 1;	// RUNNING
	localparam	CHECK_PWB		= 2;
	localparam	BUS_REQUEST		= 3;	// READ MISS / READ HIT
	localparam	SEND_ADDR		= 4;	// READ MISS / PWB_BUS_1
	localparam	SEND_DATA		= 5;	// READ HIT	 / PWB_BUS_1
	localparam	WAIT_REPLY		= 6;	// READ MISS
	localparam	STORE_DATA		= 7;	// READ MISS


	/********* interface signal *********/
	// global
	input	clk;
	input	rst;

	// bus
	input	bus_get_0;
	input	bus_get_1;
//	input	bus_active_0;
//	input	bus_active_1;
	input	get_reply;		// only occurs at bus 1
//	input 	data_ready;
	output	reg		bus_req_0;
	output	reg		bus_req_1;
	output	reg		bus_req_type_0;
	output	reg		bus_req_type_1;
	output	reg		bus_hold_0;
	output	reg		bus_hold_1;
	output	reg		bus_direction_0;
	output	reg		bus_direction_1;
	//output	reg		[1:0]	bus_request_clc		[1:0];

	// transmitter
	output	reg		transmitter_input_sel;	// [0] address		 [1] data. 		only happens at bus 1
	output	reg		data_output_sel;		// [0] origianl data [1] pwb data. 	only happens at bus 0
	output	reg		[1:0]	data_portion_sel;		// 4 packet in total 

	//	cache table
	output	reg		data_input_sel;			// [0] from processing unit / from dram
	output	reg		write_enable;
	output	reg		write_enable_tag;
	output	reg		new_flag;
	
	//	queue
	input			queue_empty;
	input			queue_full;
	input			pwb_addr_match;
	input			pwb_data_recv;			// [0] not yet [1] finish
	output	reg		pop_queue;
	output	reg		queue_search_enable;
	output	reg		queue_fetch_enable;

	// logic unit
	input	hit;
	input	[1:0]	processing_op;

	
	/********* internal signal *********/
	// FSM 
	reg		[2:0]	state;
	reg		[2:0]	sub_state;
	reg		[2:0]	return_state;
	reg		[2:0]	return_sub_state;
	reg		[8:0]	clc_counter;
	
	reg		[1:0]	rst_delay;
	
		
	/********* logic *********/
	/********* parameter *********/

	always @ ( clk ) begin
		if( clk ) begin
			if( rst ) begin
				// FSM
/*
				state 			<= IDLE;
				sub_state 		<= CHECK_QUEUE;

				return_state	<= IDLE;
				return_sub_state<= CHECK_QUEUE; 
*/
				// bus interface

				bus_req_0		<= 1'b0;
				bus_req_1		<= 1'b0;
				bus_req_type_0	<= 1'b0;		
				bus_req_type_1	<= 1'b0;
				bus_hold_0		<= 1'b0;
				bus_hold_1		<= 1'b0;		
//				bus_request_clc[0]	<= 2'b00;		// not important
//				bus_request_clc[1]	<= 2'b00;		// not important
				bus_direction_0	<= 1'b0;
				bus_direction_1	<= 1'b0;
				transmitter_input_sel	<= 1'b0;	// not important

				// cache
				write_enable		<= 1'b0;
				write_enable_tag	<= 1'b0;
				new_flag			<= 1'b1;
				data_input_sel		<= 1'b0;
				data_output_sel		<= 1'b0;
//				read_enable			<= 1'b0;
				queue_search_enable	<= 1'b0;
				queue_fetch_enable	<= 1'b0;
				pop_queue			<= 1'b0;

				// reset delay
				rst_delay			<= 1'b1;
			end
			else if( rst_delay ) begin
				rst_delay		<= 1'b0;
			end
			else begin
				if( clc_counter != 0)
					clc_counter	<= clc_counter - 1;
				// load in  condition
				/*
				hit_loader			<= hit;
				bus_get_loader[0]	<= bus_get_0;
				bus_get_loader[1]	<= bus_get_1;
				get_reply_loader	<= get_reply;		// only from bus 1
				*/
			end
		end
	end

	/**********************************************************************/
	/****** Finite State Machine ******/
	always @ ( clk ) begin
		if( clk ) begin
		// superstate transition
		if( rst ) begin
			state			<= IDLE;
			sub_state		<= CHECK_QUEUE;
			return_state	<= IDLE;
			return_sub_state<= CHECK_QUEUE; 
		end
		// read hit
		else if( processing_op == RD && state == LOAD_REQUEST && hit ) begin
			// state transission
			state			<= READ_HIT;
			sub_state		<= CHECK_PWB;		
			return_state	<= IDLE;
			return_sub_state<= CHECK_QUEUE;
			// action
			// arbiter request after check pwb
		end
		// read miss
		else if( processing_op == RD && state == LOAD_REQUEST && ~hit ) begin	// WRITE_BACK => READ_MISS
			// state transission 
			state				<= READ_MISS;
			sub_state			<= BUS_REQUEST;
			return_state		<= READ_HIT;
			return_sub_state	<= CHECK_PWB;
			// action
			// arbiter 1
			bus_req_1			<= 1'b1;
			bus_req_type_1		<= 1'b0;

		end
		// write hit
		else if( ( processing_op == WR || processing_op == PWB ) && state == LOAD_REQUEST ) begin
			// state transition
			state				<= WRITE_HIT;
			sub_state			<= BUS_REQUEST;
			return_state		<= IDLE;
			return_sub_state	<= CHECK_QUEUE;
			// action
			// arbiter 1
			bus_req_1			<= 1'b1;
			if( processing_op == WR)		bus_req_type_1		<= 1'b0;
			else if( processing_op == PWB)	bus_req_type_1		<= 1'b1;	
		end
		// write miss
		else if( ( processing_op == WR || processing_op == PWB ) && state == LOAD_REQUEST ) begin
			// state		
			state				<= READ_MISS;
			sub_state			<= BUS_REQUEST;
			return_state		<= WRITE_HIT;
			return_sub_state	<= BUS_REQUEST;
		end
		/**********************************************************************/
		else begin
			case(sub_state)
			CHECK_QUEUE: begin
				if( ~queue_empty ) begin
					pop_queue	<= 1'b1;
					state		<= LOAD_REQUEST;
					sub_state	<= DECODING;
				end
				else begin
					// queue
					pop_queue	<= 1'b0;
					queue_fetch_enable	<= 1'b0;
					queue_search_enable	<= 1'b0;
					// arbiter
					bus_req_0	<= 1'b0;
					bus_req_1	<= 1'b0;
					bus_req_type_0	<= 1'b0;
					bus_req_type_1	<= 1'b0;
					bus_hold_0	<= 1'b0;
					bus_hold_1	<= 1'b0;
				end
			end
			DECODING: begin
				// The queue is pop regardless of the empty of queue
				// the valid output of queue will set to low
				// pop_queue		<= 1'b1
				queue_search_enable	<= 1'b1;
			end
			CHECK_PWB: begin
				// no pwb match or pwb match + data is ready 
				if( ( ~pwb_addr_match ) || (pwb_addr_match && pwb_data_recv) ) begin
					data_input_sel	<= pwb_addr_match;		// [0] no match, original data as output	[1]
					sub_state		<= BUS_REQUEST;
					// arbiter
					// bus 0
					if( pwb_addr_match )	data_output_sel	<= 1'b1;
					else					data_output_sel	<= 1'b0;

					bus_req_0		<= 1'b1;
					bus_req_type_0	<= 1'b0;
				end
				else if( pwb_addr_match && ~pwb_data_recv ) begin
					// wait until the data is valid
				end
				// no other case
			end
			BUS_REQUEST: begin
				// have minimum one clock cycle 
				if( state == WRITE_HIT ) begin
					write_enable	<= 1'b1;
					new_flag		<= 1'b1;
				end
				if( bus_get_0 ) begin
					case(state)
					READ_HIT  : begin	
						// sub_state transition. 
						sub_state		<= SEND_DATA;
						clc_counter		<= CYCLE_NUM_DATA_0-1;
						// action
						// arbiter
						bus_hold_0		<= 1'b1;
						bus_direction_0	<= 1'b1;
					end
					endcase
				end
				else if ( bus_get_1 ) begin
					case( state )
					READ_MISS : begin	// get bus 1
						// sub_state transition. 
						sub_state		<= SEND_ADDR;
						clc_counter 	<= CYCLE_NUM_ADDR_1-1;
						// action
						bus_hold_1		<= 1'b1;
						bus_direction_1	<= 1'b1;
						transmitter_input_sel	<= 1'b0;	// select addrss
					end
					WRITE_HIT: begin	// get bus 1
						// sub_state transition. 
						sub_state		<= SEND_ADDR;
						clc_counter		<= CYCLE_NUM_ADDR_1-1;
						// action
						transmitter_input_sel	<= 1'b0;	// select addrss
					end
					endcase
				end
			end
			SEND_ADDR: begin
				if( clc_counter == 0 ) begin
					case(state)
					READ_MISS: begin	// at bus 1
						// sub_state transition
						sub_state		<= WAIT_REPLY;
						// action			
						// arbiter
						// release bus 1
						bus_req_1		<= 1'b0;
						bus_req_type_1	<= 1'b0;	
						bus_hold_1		<= 1'b0;
						bus_direction_1	<= 1'b0;
					end
					WRITE_HIT: begin
						// state transition
						sub_state		<= SEND_DATA;
						// action
						clc_counter 	<= CYCLE_NUM_DATA_1-1;
						transmitter_input_sel	<= 1'b1;	// select data
						data_portion_sel		<= 2'b11;
					end
					endcase
				end
			end
			SEND_DATA: begin			// ENDING STATE
				if( clc_counter == 0 ) begin
					// state transition
					if( state == WRITE_HIT ) begin	// deal with READ_MISS + WRITE HIT
						state	<= IDLE;
						state	<= CHECK_QUEUE;
					end
					else begin
						state		<= return_state;		// ending state required superstate change
						sub_state	<= return_sub_state;	
					end
					// action
					// arbiter
					// release all bus
					bus_req_0		<= 1'b0;
					bus_req_type_0	<= 1'b0;
					bus_hold_0		<= 1'b0;
					bus_direction_0	<= 1'b0;
					
					bus_req_1		<= 1'b0;
					bus_req_type_1	<= 1'b0;
					bus_hold_1		<= 1'b0;
					bus_direction_1 <= 1'b0;
					// cache table
					write_enable 	= 1'b0;
				end
				else
					data_portion_sel <= data_portion_sel - 1;		
			end
			WAIT_REPLY: begin
				if( get_reply ) begin
					// state transition
					sub_state	<= STORE_DATA;
					// action
					clc_counter	<= 1;
					write_enable	<= 1'b1;
				end
			end
			STORE_DATA: begin
				// first cycle store data
				if( clc_counter == 1 ) begin
					new_flag		<= 1'b1;
					case(state)
					READ_MISS:  begin
						write_enable_tag	<= 1'b1;
						data_input_sel	<= 1'b1;
					end
					WRITE_HIT: begin
						data_input_sel	<= 1'b0;
					end
					endcase
				end
				// second cycle finish data
				else if( clc_counter == 0) begin
					// state transition
					state		<=	return_state;		// ending state required superstate change
					sub_state	<= 	return_sub_state;	// READ_MISS only returns to HIT. sub_state does not matter
					// action
					// arbiter
					bus_req_1		<= 1'b0;
					write_enable	<= 1'b0;
					write_enable_tag	<= 1'b0;
				end
			end

			DECODING: begin
				// transition
				// no transition until the instruction is decoded and decide a hit or not.
				// action
				pop_queue		<= 1'b0;
			end
			endcase
		end	// end of if else

		end	// end of if(clk)
	end // end of always block

	/**********************************************************************/
	/* FSM state */
	// FSM state signal assignment
	always @ ( clk ) begin
		if( clk ) begin
			case( state )
			IDLE: begin	
				// ONLY ONE SUBSTATE - CHECK QUEUE
			// arbiter interface handler
				bus_req_0	<= 1'b0;
				bus_req_1	<= 1'b0;
				// bus_request_type		not important
				// bus_request_clc		not important
			// queue
//				pop_queue <= 1'b1;
			end
	
			LOAD_REQUEST: begin
			// arbiter interface handler
			end
	
			READ_HIT: begin
				case(sub_state)
				CHECK_PWB: begin
				end
				BUS_REQUEST: begin
				end
				SEND_DATA: begin
				end	
				endcase
			end
	
			READ_MISS: begin
				case(sub_state)
				BUS_REQUEST: begin
				end
				SEND_ADDR: begin
				end
				WAIT_REPLY: begin
				end
				STORE_DATA: begin
				end
				endcase
			end
	
			WRITE_HIT: begin
				case(sub_state)
				BUS_REQUEST: begin		// + STORE DATA
				end
				SEND_ADDR: begin
				end
				SEND_DATA: begin
				end
				endcase		
			end
			endcase
		end	// end of if block
	end		// end of always block

endmodule
