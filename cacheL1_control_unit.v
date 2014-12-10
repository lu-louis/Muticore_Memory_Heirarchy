/*

Note:
[Future improvement] Request shall be handled in queue. Put pending request into stack and then pop it.
*/

`ifndef DEFFILE
	`include "define.v"
`endif


module cacheL1_control_unit(
	// input
	clk, rst, 					// global
	op,							// processor
	hit,						// internal logic
	bus_get, 					// arbiter
	get_reply,					// bus interface
	sel_block_in, flag,			// cache table
	snp_1, snp_2,				// snoop

	// output
	bus_req, bus_req_type, 		// arbiter
	bus_hold, bus_direction,	
	halt, 						// processor
	transmitter_input_sel,		// bus_interface
	transmitter_addr_sel,	

	we_flag_vector,				// cache table
	we_addr_vector,
	we_data_vector,
	new_flag_vector,					
	data_index_sel,
	data_din_sel,

	// debug
	snp_error, wb_active,pwb_active,
	st, sub_st, re_st, re_sub_st
	);

	/************ Parameter ***********/
	parameter	CYCLE_NUM_RATIO	= 2;
	// Data valid flag status
	localparam	INVALID			= 0;
	localparam	SHARED_CLEAN	= 1;
	localparam	OWNED_CLEAN		= 2;
	localparam	OWNED_DIRTY		= 3;
	
	// arbiter 
	localparam	CYCLE_NUM_ADDR	= 1 * CYCLE_NUM_RATIO;	// number of cycle required to transmit address ( read miss request )
	localparam	CYCLE_NUM_DATA	= 1 * CYCLE_NUM_RATIO;	// number of cycle required to transmit data 	( (priority) write back )
	localparam	CYCLE_NUM_SETFLAG = 2;
	localparam	CYCLE_NUM_UPDATE  = 1;

	localparam	RD				= 0;
	localparam	WR				= 1;

	// control unit state machine
	// superstate
	localparam	IDLE			= 0;
	localparam	READ_HIT		= 1;
	localparam	READ_MISS		= 2;
	localparam	WRITE_HIT		= 3;	
	localparam	WRITE_BACK		= 4;	// SC + write / preempt
	localparam	PRIO_WRITE_BACK	= 5;	// OD + snoop read 
	localparam	FLAG_UPDATE		= 6;	// snoop write / invalidate data
	// substate

	localparam	BUS_REQUEST	= 0;
	localparam	SEND_ADDR	= 1;
	localparam	SEND_DATA	= 2;
	localparam	WAIT_REPLY	= 3;
	localparam	STORE_DATA	= 4;
	localparam	SET_FLAG	= 5;
	localparam	UPDATE_FLAG	= 6;
	//localparam	READ_HIT	= 7;
	//localparam	WRITE_HIT	= 8;
	localparam	PROCESSING	= 9;
	localparam	DECODING	= 10;
	/************ Interface signal ***********/
	// global
	input	clk;
	input	rst;
	
	// processor end
	input	[ 1 : 0 ]	op;		// [0] read		[1] write
	output	reg		halt;
	
	// internal logic
	input	hit;

	// arbiter
	input			bus_get;				// [0] halt		[1] get
	output	reg		bus_req;				// [0] no req 	[1] new req
	output	reg		bus_req_type;			// [0] WB 		[1] PWB
//	output	reg		[ 5 : 0 ]	bus_req_clc;
	output	reg		bus_hold;
	output	reg		bus_direction;

	// bus 0 end
	input	get_reply;			// [0] no reply [1] reply	. if the new data on bus from memory is the request one 	
	output	reg				transmitter_input_sel;	// [0] address	[1] data
	output	reg		[1:0]	transmitter_addr_sel;	// [0] mmu	[1] WB/preempt	[2]	snoop 1	[3]	snoop 2
//	output	reg		[1:0]	tran_addr_sel;		// [0] mmu		[1] preempt		[2] snoop 1	[3]	snoop 2
		
	// snoop
	input	[14-1:0 ]	snp_1;	// vector - hit (1) / operation (1) / block hit (4) / flag vectore (8)
	input	[14-1:0 ]	snp_2;
	
	// cache table
	input	[ 1 : 0 ]	sel_block_in;		// block selection upon hit. 
	input	[ 7 : 0 ]	flag;				// flag of the all entry
	// also process snooping update, four entry can be update in once
	output	reg		[ 3 : 0 ]	we_flag_vector;		// flag write enable. 
													// four outputs in case snoop write invalid two or more entry
	output	reg		[ 3 : 0 ]	we_addr_vector;		// addr write enable
	output	reg		[ 3 : 0 ]	we_data_vector;		// data write enable
	output	reg		[ 7 : 0 ]	new_flag_vector;
	output	reg		[ 1 : 0 ]	data_index_sel;		// [0] instruction	[1]	snoop 1	[2] snoop 2 
	output	reg					data_din_sel;		// [0] din_proc		[1] receiver
/*
	input	[3:0]	lru;				// Least Recent Use tag
	output	[3:0]	new_lru;
*/
	
	// debug
	output	reg	snp_error;
	output	reg	wb_active;
	output	reg	pwb_active;
	output	[3:0]	st;
	output	[3:0]	sub_st;
	output	[3:0]	re_st;
	output	[3:0]	re_sub_st;

	
	/************ Intrnal signal ***********/
	// register
	reg		hit_loader;
	reg		bus_get_loader;
	reg		mem_ready_loader;
	reg		get_reply_loader;
	reg		[ 7 : 0 ]	flag_loader;
	reg		[ 1 : 0 ]	flag_selected_reg;
	reg		[ 7 : 0 ]	new_flag_portion;
	reg		[ 7 : 0 ]	new_flag_mask;

	reg		rst_delay;

	// repalcement scheme
	reg		[ 1 : 0 ]	alloc_cache_id;
	//reg		[ 1 : 0 ]	lru_replace_block;
	//reg		[ 7 : 0 ]	lru_vector;
	reg		[ 3 : 0 ]	clc_counter;
	reg		preempt;
	reg		finish;
	reg 	[14-1 : 0]	snp_vector_1;	// 1 match + 1 op + 4 block hit + 8 entry flag 14
	reg 	[14-1 : 0]	snp_vector_2;	
	// debug
	reg		[10-1 : 0]	testing_counter;

	wire	[ 7 : 0]	flag_mask	[3 : 0];

	wire				snp_hit_1;		// [0] no match [1] match
	wire				snp_hit_2;	
	wire				snp_op_1;		// [0] read [1] write
	wire				snp_op_2;
	wire	[ 3 : 0 ]	snp_block_hit_1;// snoop hit block number;
	wire	[ 3 : 0 ]	snp_block_hit_2;	
	wire	[ 7 : 0 ]	snp_flag_1;		// snoop hit entry data status. 			
	wire	[ 7 : 0 ]	snp_flag_2;		// read: OC => SC, OD => SC + PWB. write: SC => INVAL
	wire	[ 1 : 0 ]	allo_cache_id_wire;
	wire	[ 3 : 0 ]	allo_cache_we_mask;

	wire	[ 3 : 0 ]	sel_cache_block;

	// FSM
	reg		[ 3 : 0 ]	state;
	reg		[ 3 : 0 ]	sub_state;
	reg		[ 3 : 0 ]	return_state;
	reg		[ 3 : 0 ]	return_sub_state;
	reg		miss_type;
	// component
	mux_2to1	#( .DATA_WIDTH(2) )
				write_enable_port_sel_mux(
					.sel	(),
					.din1	(),
					.din2	(),
					.dout	()	
				);
	decoder_2to4	sel_signal_hit(
						.in		( sel_block_in ),
						.out	( sel_cache_block )
					);
	decoder_2to4	sel_signal_allocate(
						.in		( allo_cache_id_wire ),
						.out	( allo_cache_we_mask )
					);
	/*********** internal connection **********/

	assign	allo_cache_id_wire = alloc_cache_id;

	assign 	snp_hit_1 		= snp_vector_1[13];
	assign	snp_op_1		= snp_vector_1[12];
	assign 	snp_block_hit_1	= snp_vector_1[11:8];
	assign	snp_flag_1		= snp_vector_1[7:0];

	assign 	snp_hit_2 		= snp_vector_2[13];
	assign	snp_op_2		= snp_vector_2[12];
	assign 	snp_block_hit_2	= snp_vector_2[11:8];
	assign	snp_flag_2		= snp_vector_2[7:0];

	assign  flag_mask[0]	= 8'b00000011;
	assign  flag_mask[1]	= 8'b00001100;
	assign  flag_mask[2]	= 8'b00110000;
	assign  flag_mask[3]	= 8'b11000000;

	assign	st 			= state;
	assign	sub_st 		= sub_state;
	assign	re_st		= return_state;
	assign	re_sub_st	= return_sub_state;

	/************ Logic ***********/
	/******* plus clock ******/
	// reset
	always @ ( clk ) begin
		if( clk ) begin
			if( rst ) begin
				// state machine
				state 				<= IDLE;
				sub_state 			<= DECODING;
				return_state		<= IDLE;
				return_sub_state	<= DECODING; 
				// bus end
				transmitter_input_sel	<= 1'b0;
				transmitter_addr_sel	<= 1'b0;
				// processor
				halt			<= 1'b0;
				// arbiter [Guard]
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
				data_din_sel	<= 1'b0;
				// debug
				snp_error		<= 1'b0;
				wb_active		<= 1'b0;
				rst_delay		<= 1'b1;
			end
			else if( rst_delay ) begin
				rst_delay		<= 1'b0;
			end
			else begin
				hit_loader			<= hit;
				bus_get_loader		<= bus_get;
				//mem_ready_loader	<= mem_ready;
				get_reply_loader	<= get_reply;
				flag_loader			<= flag;
				flag_selected_reg	<= flag >> (sel_block_in*2);		// selected 
				snp_vector_1		<= snp_1;
				snp_vector_2		<= snp_2;

				testing_counter		<= testing_counter + 1;

			end
		end
	end

	// clc_counter decrement
	always @ ( clk ) begin
		if( clk ) begin
			if( clc_counter != 0 )
				clc_counter <= clc_counter - 1;
			else
				clc_counter <= 0;
		end
	end

	// block replacement scheme
	always @ ( clk ) begin
		if( clk ) begin
			if(rst) begin
				alloc_cache_id	<= 2'b0;	
			end
			// random replacement scheme
			else if( ~hit ) begin	// read miss + write back
				// entry already selected by the instruction 
				// since the instruction will not change when miss ( halt signal high )
				// only need to select the enable entry
				if( ( ( flag_loader & flag_mask[allo_cache_id_wire] ) >> (allo_cache_id_wire*2) != INVALID ) && 
					( ( flag_loader & flag_mask[allo_cache_id_wire] ) >> (allo_cache_id_wire*2) != SHARED_CLEAN ) ) begin	// preempt entry need write back
					preempt  <= 1'b1;
				end
				else begin
					// just preempt
					preempt	<= 1'b0;
				end
			end
			else begin
				alloc_cache_id <= alloc_cache_id + 1;
			end
		end
	end


	/****** Finite State Machine ******/
	/*
	Superstate determines the pending request information
	Substate determines the signal assignment

	Event can only be triggered by signal change which only happens at clock cycle event (plus or minus)
	Transition logic does not need to specify clock cycle
	*/

	always @ ( clk ) begin
		if( clk ) begin
		// superstate transition
		// snoop write = inavlidate signal
		if( rst || rst_delay ) begin
		end
		// snoop write ( high priority, take over other process )
		else if( ( ( snp_hit_1 && snp_op_1 == WR ) || ( snp_hit_2 && snp_op_2 == WR ) ) &&
				 ( state != FLAG_UPDATE ) ) begin
			$display("[%d]Snoop Write - Invalidate",testing_counter);
			// state transition
			state			<= FLAG_UPDATE;
			sub_state		<= SET_FLAG;
			return_state	<= state;
			return_sub_state<= sub_state;
			// action
			clc_counter		<= CYCLE_NUM_SETFLAG - 1;
		end
		// snoop read + OD -> PWB
		else if( ( ( snp_hit_1 && snp_op_1 == RD && snp_flag_1 == OWNED_DIRTY ) ||
				   ( snp_hit_2 && snp_op_2 == RD && snp_flag_2 == OWNED_DIRTY ) ) &&
				 ( state != PRIO_WRITE_BACK ) ) begin
			$display("[%d]Snoop read + OD - PWB ",testing_counter);
			// state transission
			state			<= PRIO_WRITE_BACK;
			sub_state		<= BUS_REQUEST;		
			return_state	<= state;
			return_sub_state<= sub_state;
			// action
			pwb_active		<= 1'b1;
			// arbiter
			bus_req			<= 1'b1;
			bus_req_type	<= 1'b1;
			//bus_req_clc		<= CYCLE_NUM_ADDR + CYCLE_NUM_DATA - 1;
			// processor
			halt			<= 1'b1;
		end
		// snoop read + OC -> change flag
		else if( ( ( snp_hit_1 && snp_op_1 == RD && snp_flag_1 == OWNED_CLEAN ) ||
				   ( snp_hit_2 && snp_op_1 == RD && snp_flag_1 == OWNED_CLEAN ) ) &&
				 ( state != FLAG_UPDATE )  ) begin
			$display("[%d]Snoop read + OC - change flag ",testing_counter);
			// state transission
			state				<= FLAG_UPDATE;
			sub_state			<= SET_FLAG;		
			return_state		<= state;
			return_sub_state	<= sub_state;
			// action
			// processor
			halt			<= 1'b1;
		end
		// miss + preempt
		else if( ~hit && preempt && state == IDLE ) begin	// WRITE_BACK => READ_MISS
			$display("[%d]Miss + preempt - WB + READMISS ",testing_counter);
			// state transission
			state				<= WRITE_BACK;
			sub_state			<= BUS_REQUEST;
			return_state		<= READ_MISS;
			return_sub_state	<= BUS_REQUEST;
			// action
			miss_type			<= op;			// record miss type
			wb_active			<= 1'b1;
			// arbiter	
			bus_req				<= 1'b1;
			bus_req_type		<= 1'b0;
			//bus_req_clc			<= CYCLE_NUM_ADDR + CYCLE_NUM_DATA - 1;	
			// processor
			halt			<= 1'b1;
		end
		// miss
		else if( ~hit && ~preempt && state == IDLE ) begin	
			$display("[%d]READ MISS ",testing_counter);
			// state transission
			state				<= READ_MISS;
			sub_state			<= BUS_REQUEST;
			return_state		<= READ_HIT;
			return_sub_state	<= PROCESSING;
			// action
			// arbiter
			bus_req				<= 1'b1;
			bus_req_type		<= 1'b0;
			//bus_req_clc			<= CYCLE_NUM_ADDR - 1;
			// processor
			halt			<= 1'b1;
		end
		// write hit + SC/OC = STORE DATA + CHANGE FLAG
		else if( hit && op== WR && state == IDLE) begin
			$display("[%d]write hit = store data + change flag",testing_counter);
			state				<= WRITE_HIT;
			sub_state			<= STORE_DATA;
			return_state		<= IDLE;
			return_sub_state	<= DECODING;
			// action
			//wb_active 		<= 1'b0;
			clc_counter			<= 1;
			//$display("[%d]write hit - WB : %d - %d",testing_counter,state, sub_state);
			// processor
			halt			<= 1'b1;
		end
		// read hit 
		else if( hit && op== RD && state == IDLE ) begin
			$display("[%d]write hit = store data + change flag",testing_counter);
			state				<= READ_HIT;
			sub_state			<= PROCESSING;
			return_state		<= IDLE;
			return_sub_state	<= DECODING;
			// action
			//wb_active 		<= 1'b0;
			//$display("[%d]write hit - WB : %d - %d",testing_counter,state, sub_state);
			// processor
			halt				<= 1'b0;
		end
		/**********************************************************************/
		else begin
			case(sub_state)
			BUS_REQUEST: begin
				//$display("BUS_REQUEST");
				if( bus_get ) begin
					//$display("BUS_REQUEST => SEND_ADDR");
				// state transition. 
					sub_state		<= SEND_ADDR;
				// action
					// timer to transmit
					clc_counter 	<= CYCLE_NUM_ADDR - 1;
					// bus 0 transmitter data selection
					transmitter_input_sel	= 1'b0;	// select addrss : transmitter_input_sel	= 1'b0;
					case(state)
					READ_MISS:			transmitter_addr_sel	<= 2'b00;
					WRITE_BACK:			transmitter_addr_sel	<= 2'b01;
					PRIO_WRITE_BACK: 	transmitter_addr_sel	<= 2'b10;	// both snoop 1 and 2 addr are from recv
					endcase
					bus_hold		<= 1'b1;
					bus_direction	<= 1'b1;
				end
			end
			SEND_ADDR: begin	// READ_MISS / WRITE_BACK / PWB
				// first cycle send data
				if( clc_counter == 0 ) begin
					case(state)
					READ_MISS: begin
					// sub_state transition
						sub_state		<= WAIT_REPLY;
					// action
						// arbiter

						bus_req			<= 1'b0;
						bus_req_type	<= 1'b0;
						bus_hold		<= 1'b0;
						bus_direction	<= 1'b0;

					end
					WRITE_BACK: begin
					// state transition
						sub_state		<= SEND_DATA;
					// action
						clc_counter		<= CYCLE_NUM_DATA - 1;
						data_index_sel	<= 2'b01;
					end
					PRIO_WRITE_BACK: begin
					// state transition
						sub_state		<= SEND_DATA;
					// action
						clc_counter 	<= CYCLE_NUM_DATA-1;
						if( snp_hit_1 )	data_index_sel	<= 2'b10;
						if( snp_hit_2 )	data_index_sel	<= 2'b11;	
					end
					endcase
					// action
					transmitter_input_sel	<= 1'b1;	// select data
				end
			end
			SEND_DATA: begin	// Ending state ! WRITE_BACK + PWB
				if( clc_counter == 1) begin
					if( state == PRIO_WRITE_BACK )
						halt		<= 1'b0;
				end
				else if( clc_counter == 0) begin		
				// state transition
					if( state == WRITE_BACK ) begin		// must be followed by READ_MISS
					// state transition
						state		<= READ_MISS;		// If pwb take over during WRITE_BACK, return state is lost						
						sub_state	<= BUS_REQUEST;		// return state is specified.
					// action
						// arbiter
						bus_req			<= 1'b1;	
						bus_req_type	<= 1'b0;
//						bus_req_clc		<= CYCLE_NUM_ADDR;
						bus_hold		<= 1'b0;
						bus_direction	<= 1'b0;
					end	
					else if ( state == PRIO_WRITE_BACK ) begin
					// state transition
						state		<= return_state;
						sub_state	<= return_sub_state;
					// action
						// arbiter
						bus_req			<= 1'b0;
						bus_req_type	<= 1'b0;
						bus_hold		<= 1'b0;
						bus_direction	<= 1'b0;
					end
					else begin
						$display("cannot find next state when finish SEND_DATA");
						// arbiter
						bus_req			<= 1'b0;
						bus_req_type	<= 1'b0;
						bus_hold		<= 1'b0;
						bus_direction	<= 1'b0;
					end
				// action
					data_index_sel	<= 2'b00;			// set back to instruction request index.
					//we_flag_vector	<= 8'b0;
					//we_addr_vector	<= 8'b0;			// ending state;
				end
			end
			WAIT_REPLY: begin	// READ MISS
				// arbiter [Guard]
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
				data_din_sel	<= 1'b1;
				if( get_reply_loader ) begin
				// state transition
					sub_state	<= STORE_DATA;
				// action
					clc_counter	<= 1;
				end
			end
			STORE_DATA: begin	// READ_MISS / WRITE_HIT
				// arbiter [Guard]
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
				// first cycle store data.
				if( clc_counter == 1 ) begin
					if( state == WRITE_HIT ) begin
						// if write hit, update flag of the hit block / don't touch the address input
						we_flag_vector	<= sel_cache_block;		
						we_addr_vector	<= 4'b0;
						we_data_vector	<= sel_cache_block;
					end
					else if ( state == READ_MISS ) begin
						// if read miss, replace the allocate block
						we_flag_vector	<= allo_cache_we_mask;
						we_addr_vector	<= allo_cache_we_mask;			// address from mmu
						we_data_vector	<= allo_cache_we_mask;
					end
				// action
				halt		<= 1'b0;
				end
				// second cycle store data.
				else if( clc_counter == 0 ) begin
					// state transition
					state		<=	return_state;		// ending state required superstate change
					sub_state	<= 	return_sub_state;	// READ_MISS only returns to HIT. sub_state does not matter
					// action
					we_flag_vector		<= 4'b0;
					we_addr_vector		<= 4'b0;
					we_data_vector		<= 8'b0;
					data_din_sel	<= 1'b0;
				end
				else begin
					$display("counter setting wrong at STORE_DATA");
				end
			end
			SET_FLAG: begin
				// arbiter [Guard]
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
				if( clc_counter == 0) begin
					// state transition
					sub_state	<= UPDATE_FLAG;	// READ_MISS only returns to HIT. sub_state does not matter
					// action
					clc_counter <= CYCLE_NUM_UPDATE - 1;
				end
				halt		<= 1'b0;
			end
			UPDATE_FLAG: begin	// ENDING STATE
				// arbiter [Guard]
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
				if( clc_counter == 0 ) begin
					// state change
					state		<= return_state;
					sub_state	<= return_sub_state;
					// action
					we_flag_vector	<= 8'b0;
					we_addr_vector	<= 8'b0;
					we_data_vector	<= 8'b0;
				end
			end	
			PROCESSING: begin		// ending state
				// state transition
				state		<= IDLE;
				sub_state	<= DECODING;
				// action
				halt		<= 1'b0;
				// arbiter
				bus_req			<= 1'b0;
				bus_req_type	<= 1'b0;
				bus_hold		<= 1'b0;
				bus_direction	<= 1'b0;
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
			// IDLE STATE
			IDLE: begin	
				// arbiter
				//bus_req	<= 1'b1;
				// bus_request_type		not important
				// bus_request_clc		not important
			
				// processor
				//halt	<= 1'b0;
				// cache table
				we_flag_vector	<= 8'h0;
				we_addr_vector	<= 8'h0;
				we_data_vector	<= 8'h0;
				data_index_sel	<= 2'b0;
				data_din_sel	<= 1'b0;
			end

			// READ HIT STATE 
			READ_HIT: begin
				// processor
				//halt			<= 1'b0;
				case (sub_state)
				PROCESSING:	begin
				end
				endcase
			end

			// WRITE HIT STATE
			WRITE_HIT: begin
				//halt <= 1'b1;
				case (sub_state) 
				STORE_DATA: begin
					// store data 
					data_din_sel	<= 1'b0;
					// change flag
					case( flag_selected_reg )
					// INVALID	: illegal condition
					SHARED_CLEAN: begin	
						//$display("SC=>OC");
						new_flag_portion = OWNED_CLEAN;
					end
					OWNED_CLEAN: begin
						//$display("OC=>OD");
						new_flag_portion = OWNED_DIRTY;
					end
					OWNED_DIRTY: begin
						//$display("OD=>OD");
						new_flag_portion = OWNED_DIRTY;
					end
					default begin
						$display("Error flag state in write hit");
						new_flag_portion[1:0] = 2'b0;
					end
					endcase
					new_flag_vector = ( new_flag_portion << (sel_block_in*2) | ( ~flag_mask[sel_block_in] & flag_loader ));
				end
				endcase
			end
			READ_MISS: begin
				//halt <= 1'b1;
				case(sub_state)
				BUS_REQUEST: begin
				end
				
				SEND_ADDR: begin
				end
	
				WAIT_REPLY: begin
				end
	
				STORE_DATA: begin
					new_flag_portion	= SHARED_CLEAN;
					new_flag_vector 	= ( new_flag_portion << (allo_cache_id_wire*2) | 
										  ( ~flag_mask[allo_cache_id_wire] & flag_loader ) ) ;
				end
				endcase
			end
			// WRITE_BACK STATE
			WRITE_BACK: begin
				//halt	<= 1'b1;
				case(sub_state)
				BUS_REQUEST: begin
				end
	
				SEND_ADDR: begin
				end
	
				SEND_DATA: begin
				end	
				endcase
			end
			// PRIORITY WRITE BACK STATE
			PRIO_WRITE_BACK: begin	// only happens when snoop read
				case(sub_state)
				BUS_REQUEST: begin
				end
	
				SEND_ADDR: begin
					// snoop read + OD: PWB
					// Entry hit need to change flag to SC
					// L1-L2 bus snoop hit, higher level bus has faster speed => value lost faster => higher priority 
					if(snp_hit_1) begin							
						$display("set new flag value");
						// if block hit 1, need to be change, mask 00 to filter the original value
						// if block does not hit 0, no change, mask 11 to maintain the result
						new_flag_vector 	<= snp_flag_1[7:0];
						
						new_flag_mask		<= ( ( ( snp_block_hit_1[0] ? 8'h00 : 8'hFF ) & flag_mask[0] ) |	
												 ( ( snp_block_hit_1[1] ? 8'h00 : 8'hFF ) & flag_mask[1] ) |
												 ( ( snp_block_hit_1[2] ? 8'h00 : 8'hFF ) & flag_mask[2] ) |
												 ( ( snp_block_hit_1[3] ? 8'h00 : 8'hFF ) & flag_mask[3] ) );
						new_flag_portion	<= ( 8'h55 ) ;	// to SHARED_CLEAN
					end
					else if(snp_hit_2) begin
						new_flag_vector 	<= snp_flag_2[7:0];
						new_flag_mask		<= ( ( ( snp_block_hit_2[0] ? 8'h00 : 8'hFF ) & flag_mask[0] ) |
												 ( ( snp_block_hit_2[1] ? 8'h00 : 8'hFF ) & flag_mask[1] ) |
												 ( ( snp_block_hit_2[2] ? 8'h00 : 8'hFF ) & flag_mask[2] ) |
												 ( ( snp_block_hit_2[3] ? 8'h00 : 8'hFF ) & flag_mask[3] ) );
						new_flag_portion	<= ( 8'h55 ) ;	// to SHARED_CLEAN
					end
					else begin
						$display("[ERROR] In PWB but no snp hit");
						snp_error <= 1'b1;
					end
				end
	
				SEND_DATA: begin
					if( clc_counter != 0 ) begin
						if( snp_hit_1 ) begin
							$display("assign new flag snoop 1");
							we_flag_vector		<= 	snp_block_hit_1;
							new_flag_vector		<= ( new_flag_vector & new_flag_mask ) | ( new_flag_portion & ~new_flag_mask ) ;
						end
						else if( snp_hit_2) begin
							$display("assign new flag snoop 2");
							we_flag_vector		<= 	snp_block_hit_2;
							new_flag_vector		<= ( new_flag_vector & new_flag_mask ) | ( new_flag_portion & ~new_flag_mask ) ;
						end
						else begin
							$display("[ERROR] In PWB but no snp hit");
							snp_error <= 1'b1;
						end
					end
				end	
	
				endcase		
			end
			FLAG_UPDATE: begin
				//halt 	<= 1'b1;
				case(sub_state)
				SET_FLAG: begin
					if( snp_hit_1 ) begin	// L1-L2 bus snoop hit, higher level bus has faster speed => value lost faster => higher priority 
						$display("set flag to invalidate");
	
						new_flag_vector 	<= snp_flag_1[7:0];
						new_flag_mask		<= ( ( ( snp_block_hit_1[0] ? 8'h00 : 8'hFF ) & flag_mask[0] ) |	// if block hit 1, need to be change, mask 00 to filter the original value
												 ( ( snp_block_hit_1[1] ? 8'h00 : 8'hFF ) & flag_mask[1] ) |	// if block does not hit 0, no change, mask 11 to maintain the result
												 ( ( snp_block_hit_1[2] ? 8'h00 : 8'hFF ) & flag_mask[2] ) |
												 ( ( snp_block_hit_1[3] ? 8'h00 : 8'hFF ) & flag_mask[3] ) );
						if( snp_op_1 == WR )		new_flag_portion		<= 8'h00;		// INVALID
						else if( snp_op_1 == RD)	new_flag_portion		<= 8'h55;		// SHARED_CLEAN
					end
					else if( snp_hit_2 ) begin
						new_flag_vector 	<= snp_flag_2[7:0];
						new_flag_mask		<= ( ( ( snp_block_hit_2[0] ? 8'h00 : 8'hFF ) & flag_mask[0] ) |	// if block hit 1, need to be change, mask 00 to filter the original value
												 ( ( snp_block_hit_2[1] ? 8'h00 : 8'hFF ) & flag_mask[1] ) |	// if block does not hit 0, no change, mask 11 to maintain the result
												 ( ( snp_block_hit_2[2] ? 8'h00 : 8'hFF ) & flag_mask[2] ) |
												 ( ( snp_block_hit_2[3] ? 8'h00 : 8'hFF ) & flag_mask[3] ) );
						if( snp_op_2 == WR )		new_flag_portion		<= 8'h00;		// INVALID
						else if( snp_op_2 == RD)	new_flag_portion		<= 8'h55;		// SHARED_CLEAN
					end
					else begin
						$display("[ERROR] In PWB but no snp hit");
						snp_error <= 1'b1;
					end
				end

				UPDATE_FLAG: begin
					//if( clc_counter != 0 ) begin
						if( snp_hit_1 ) begin
							$display("assign new flag");
							we_flag_vector		<= 	snp_block_hit_1;
							new_flag_vector		<= ( new_flag_vector & new_flag_mask ) | ( new_flag_portion & ~new_flag_mask ) ;
						end
						else if( snp_hit_2 ) begin
							we_flag_vector		<= 	snp_block_hit_2;
							new_flag_vector		<= ( new_flag_vector & new_flag_mask ) | ( new_flag_portion & ~new_flag_mask ) ;
						end
						else begin
							$display("[ERROR] In PWB but no snp hit");
							snp_error <= 1'b1;
						end
					//end
				end
				endcase
			end
			endcase
		end
	end
endmodule
