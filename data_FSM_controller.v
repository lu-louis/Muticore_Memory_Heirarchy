/*
UNUSED

Operates at MINUS clock

@clk		:	Clock
@rst		:	Reset
@new_op		:	Current Operatoin
@read_from	:	Register read from [0] data bus [1] din register

*/

module	data_FSM_controller(
	// input
	clk, rst, new_op, 
	// output
	read_from, state
	);
	/*********** Signal Declairation **********/
	/****** Parameter *****/
	// FSM State
	localparam 	RAR  	= 3'b00;
	localparam 	RAW 	= 3'b01;
	localparam 	WAR  	= 3'b10;
	localparam 	WAW		= 3'b11;
	localparam	INIT 	= 3'b100;
	localparam	UNDEF	= 3'b111;
	// Read_from port
	localparam	CACHE 	= 0; 
	localparam	DIN		= 1;
	// Operatoin type
	localparam	RD	 	= 2'b0;
	localparam	WR	 	= 2'b1;
	localparam	NOOP	= 2'b11;

	/****** Interface Signal ******/
	// input
	input 	clk;
	input 	rst;
	input	[1:0]	new_op;
//	input	bus_status;

	// output
	output 	read_from;
	output	[2:0]	state;
	reg		[2:0]	state;	// [00] RAR [01] RAW [10] WAR [11] WAW
							// [100] Initial state [101-111] Undefined
	/****** Internal  ******/
	// register 
	reg		[1:0]	op;		// [0] Read [1]  Write
	reg		read_direction;	// [0] din	[1]	 data bus
	// wire
	// Assign
	assign read_from = read_direction;

	/*********** Implementation ***********/
	/****** Fetch operation ******/
	always @ ( clk ) begin
		if(clk) begin
			if(rst) begin
				op 		<= NOOP;
				state	<= INIT;
			end
			else begin
				op <= new_op;
			end
		end
	end
	/******	 ******/
	always @ ( clk ) begin
		if(clk) begin
			if(rst) begin
				op 		<= INIT;
				state	<= INIT;
			end
			else begin
				op <= new_op;
			end
		end
	end

	/****** FSM *******/
	// ~op = read / op = write
	always @ ( op ) begin
		if( state == INIT ) begin
			if( ~op )	state <= RAR;
			else		state <= WAW;
		end
		else if( state == RAR ) begin
			if( ~op )	state <= RAR;
			else		state <= WAR;
		end
		else if( state == WAR ) begin
			if( ~op )	state <= RAW;
			else		state <= WAW;
		end
		else if( state== RAW ) begin
			if( ~op )	state <= RAR;
			else		state <= WAR;			
		end
		else if( state== WAW ) begin
			if( ~op )	state <= RAW;
			else		state <= WAW;			
		end
		else
			state <= UNDEF;
	end

	/*  */
	always @ ( * ) begin
		case( state ) 
		RAR:	read_direction <= CACHE;
		WAR:	read_direction <= CACHE;	// [I] Give the priority to cache. Postpone the write instructino. Can have different implementation 
		RAW:	read_direction <= CACHE;	// data available after two cycle but makes no different to the processor as availability is indicate by hit.
		WAW:	read_direction <= DIN;
		default:read_direction <= CACHE;
		endcase
	end

endmodule

