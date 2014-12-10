

/*	
	priority check is check during read request
*/


`ifndef DEFFILE
	`include "define.v"
`endif

module mem_control_unit(
	// input
	clk, rst,
	queue_empty, 							// queue
	pwb_match, pwb_receiving,	
	processing_op, 							// processing unit
	bus_get,								// arbiter handler
	// output
	write_enable, search_enable, fetch_enable,	// queue
	pop_queue,
	gather_data, 							// processing unit
	data_output_sel, data_portion_sel,		// transmitter
	bus_request, bus_request_type, 			// arbiter
	bus_hold, 
	bus_direction							// bus interface
	);

	/********* parameter *********/
	parameter	CYCLE_RATIO		= 4;
	parameter	CYCLE_NUM_DATA	= 4;
	parameter	CYCLE_NUM_DATA_REQ	= CYCLE_RATIO * CYCLE_NUM_DATA;
	parameter	CYCLE_GATHER_DATA	= 4;
	parameter	CYCLE_WAIT_DATA		= 4;
	// FSM
	// superstate
	localparam	IDLE		= 0;
	localparam	RUNNING		= 1;
	localparam	READ		= 2;
	localparam	WRITE		= 3;
	// substate
	localparam	CHECK_QUEUE	= 0;
	localparam	PROCESSING	= 1;
	localparam	BUS_REQUEST	= 2;
	localparam	SEND_DATA	= 3;
	localparam	STORE_DATA	= 4;
	localparam	CHECK_PWB	= 5;
	localparam	GATHER_DATA = 6;
	localparam	WAIT_DATA	= 7;

	/********* interface signal *********/
	// global
	input	clk;
	input	rst;

	// data table
	output	reg		write_enable;
	output 	reg		search_enable;

	// queue
	input	queue_empty;
	input	pwb_match;
	input	pwb_receiving;
	output	reg		fetch_enable;
	output	reg		pop_queue;

	// logic
	input	[1:0]	processing_op;
	output	reg		gather_data;		// [0] new_data is ready to be written to mem	[1]	gathering data 
	output	reg		data_output_sel;
	output	reg	 	[1:0]	data_portion_sel;

	// bus interface
	// arbiter interface handler
	input			bus_get;
	output	reg		bus_request;
	output	reg		bus_request_type;
	output	reg		bus_hold;
	output	reg		bus_direction;
	/********* internal signal *********/
	reg		rst_delay;
	reg		[8:0]	clc_counter;
	/********* internal component *********/
	reg		[2:0]	state;
	reg		[2:0]	sub_state;
	reg		[2:0]	return_state;
	reg		[2:0]	return_sub_state;

	/********* logic *********/
	always @ ( clk ) begin
		if( clk ) begin
			if( rst ) begin
				clc_counter	<= 0;
			end
			else if(clc_counter != 0) begin
				clc_counter <= clc_counter - 1;
			end
		end
	end
	

	/**** FSM transition ****/
	always @ ( clk ) begin
		if( clk ) begin
			// superstate transision
			if( rst || rst_delay ) begin
				// queue
				search_enable	<= 1'b0;
				fetch_enable	<= 1'b0;
				write_enable	<= 1'b0;
				pop_queue		<= 1'b0;	// read enable
				// logic
				gather_data		<= 1'b0;
				data_output_sel	<= 1'b0;
				data_portion_sel<= 2'b11;
				// arbiter
				bus_request		<= 1'b0;
				bus_request_type<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction 	<= 1'b0;
			end
			// read request
			else if( processing_op == `RD && state == RUNNING ) begin
				$display("decode ! read request");
				// state transition
				state 			<= READ;
				sub_state		<= CHECK_PWB;
				return_state	<= IDLE;
				return_sub_state<= CHECK_QUEUE;
				// action
				search_enable	<= 1'b1;
				pop_queue		<= 1'b0;
			end
			//write request
			else if( ( processing_op == `WR || processing_op== `PWB ) && state == RUNNING ) begin
				$display("decode ! write request");
				state			<= WRITE;
				sub_state		<= STORE_DATA;
				return_state	<= IDLE;
				return_sub_state<= CHECK_QUEUE;
				// action
				clc_counter		<= 1;
				write_enable	<= 1'b1;
			end
			// sub state transition 
			else begin
				case(sub_state)
				CHECK_QUEUE: begin
					$display("CHECK_QUEUE");
					// IDLE state
					// If any task in the queue, pop it
					if( ~queue_empty ) begin
						$display("-- NOT EMPTY --");
						// state transition
						state 		<= RUNNING;
						sub_state	<= PROCESSING;
//						sub_state	<= CHECK_PWB;
						// action
						search_enable	<= 1'b1;
						pop_queue		<= 1'b1;
					end
					else begin
						// queue
						pop_queue		<= 1'b0;
						search_enable	<= 1'b0;
						// arbiter
						bus_request		<= 1'b0;
						bus_request_type<= 1'b0;
						bus_hold		<= 1'b0;
						bus_direction	<= 1'b0;
					end
				end
				// RUNNING state
				PROCESSING: begin
					$display("PROCESSING");
					pop_queue			<= 1'b0;
				// waiting to determine which state it is
				end
				// READ state
				CHECK_PWB: begin
					$display("CHECK_PWB");
					// no pwb occurs
					if( ~pwb_match ) begin
						// state transition
						sub_state			<= BUS_REQUEST;
						// action
						bus_request			<= 1'b1;
						bus_request_type	<= 1'b0;
						gather_data			<= 1'b0;
					end
					// has pwb but still receiving data
/*
					else if ( pwb_match && pwb_receiving )begin
						$display("waiting for pwb data to arrive");
						// state transition
						sub_state			<= WAIT_DATA;
						// action
						clc_counter			<= CYCLE_WAIT_DATA - 1;
					end
*/
					// has pwb and receive complete
					else if( pwb_match && ~pwb_receiving ) begin
						// state transition
						sub_state			<= BUS_REQUEST;	
						// action
						bus_request			<= 1'b1;
						bus_request_type	<= 1'b0;
						// queue
						gather_data			<= 1'b1;
						fetch_enable		<= 1'b1;
					end
					else begin
						// action
						search_enable	<= 1'b0;
					end
				end
/*
				WAIT_DATA: begin
					$display("WAIT_DATA");
					if( clc_counter == 0 ) begin
						// sub_state transition
						sub_state		<= BUS_REQUEST;
						// action
						// arbiter interface handler
						bus_request			<= 1'b1;
						bus_request_type	<= 1'b0;
						// queue
						fetch_enable 	<= 1'b1;
						gather_data		<= 1'b1;
					end
				end
*/
				BUS_REQUEST: begin
					$display("BUS_REQUEST");
					if( bus_get ) begin
						// state transition
						sub_state	<= SEND_DATA;
						// action
						bus_hold		<= 1'b1;
						bus_direction	<= 1'b1;
						clc_counter		<= CYCLE_NUM_DATA-1;
						data_portion_sel <= 2'b11-1;
						if( ~pwb_match )
							data_output_sel	<=	1'b0;
						else
							data_output_sel <= 1'b1;
					end
					// action
					fetch_enable	<= 1'b0;
				end
				SEND_DATA: begin	// ending state
					$display("SEND_DATA");
					if( clc_counter == 0 ) begin
						state		<= return_state;
						sub_state	<= return_sub_state;
						// action
						bus_request			<= 1'b0;
						bus_request_type	<= 1'b0;
						bus_hold			<= 1'b0;
						bus_direction		<= 1'b0;
					end
					else begin
						data_portion_sel <= data_portion_sel - 1;						
					end
				end

				// WRITE && READ state
				// WRITE state
				STORE_DATA: begin	// ending state
					$display("STORE_DATA");
					if( clc_counter == 0 ) begin
						// state transision
						state		<= return_state;
						sub_state	<= return_sub_state;	
						// action - terminate this session
						write_enable	<= 1'b0;
					end
					else begin
						write_enable	<= 1'b1;
						search_enable	<= 1'b0;
					end
				end

				endcase
			end
		end
	end 

	/**** FSM transition ****/
	always @ ( clk ) begin
		if( clk ) begin
			if( rst ) begin
				state		<= IDLE;
				sub_state	<= CHECK_QUEUE;
			end
			else begin
				case(state)
				IDLE: begin
				end
	
				RUNNING: begin
				end
	
				READ:  begin
					case(sub_state)
					CHECK_PWB: begin
					end
					BUS_REQUEST: begin
	
					end
					SEND_DATA: begin
						
					end
					endcase
					end
				
				WRITE: begin
					case(sub_state)
					GATHER_DATA: begin
					end
					STORE_DATA:  begin
					end
					endcase
				end
	
				endcase
			end	// end of else
		end 	// end of clk 
	end			// end of always block
endmodule
	