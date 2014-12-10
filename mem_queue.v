/*
Description:
DRAM

Interface:
@clk
@rst
@rd_en
@wr_en
@buf_en

@buf_out
@emptry
@full

*/

`ifndef DEFFILE
	`include "define.v"
`endif


module	mem_queue(
	// input
	clk, rst, 
	op, pop_en, push_en, search_en, fetch_en,
	buf_in, search_addr, fetch_index,
	// output
	buf_out, dout, valid_output, 
	search_match, search_match_index, search_match_receiving,
	fetch_data,
	empty, full
	);
	/********** Parameter *********/
	parameter	REQUEST_SIZE	= 38;
	parameter	ADDR_WIDTH		= 32;
	parameter	DATA_WIDTH		= 128;
	parameter	QUEUE_SIZE		= 16;	// number of entry
	parameter	QUEUE_SIZE_BIT	= 4;
	parameter	COUNTER_WIDTH	= 10;	
	parameter	CYCLE_NUM_DATA	= 4;

	parameter	BOUNDARY_UP		= 32'h0000_2000 - 1;
	parameter	BOUNDARY_LOW	= 32'h0000_0000; 

	localparam	RD				= 2'b00;
	localparam	WR				= 2'b01;
	localparam	PWB				= 2'b10;
	localparam	REQUEST_ONLY	= 1;
	localparam	RECEIVE_DATA	= 2;
	/********** Interface Signal *********/
	input 	clk;
	input 	rst;
	input	[1:0]	op;
	input	pop_en;
	input	push_en;
	input	search_en;
	input	fetch_en;
	input	[QUEUE_SIZE_BIT	- 1 : 0]	fetch_index;
	input	[REQUEST_SIZE	- 1 : 0]	buf_in;
	input	[ADDR_WIDTH		- 1: 0]		search_addr;


	output	reg		[REQUEST_SIZE 	- 1 : 0]	buf_out;
	output	reg		[DATA_WIDTH		- 1 : 0]	dout;
	output	reg		valid_output;
	output	reg		search_match;
	output	reg		search_match_receiving;
	output	reg		[QUEUE_SIZE_BIT	- 1 : 0]	search_match_index;
	output	reg		[DATA_WIDTH		- 1 : 0]	fetch_data;
	output	reg		empty;
	output	reg		full;



	/********** Internal signal *********/
	reg		[REQUEST_SIZE 	- 1 : 0]	queue_table	[QUEUE_SIZE - 1 : 0];
	reg		[DATA_WIDTH		- 1 : 0]	data_table	[QUEUE_SIZE - 1 : 0];
	reg		[QUEUE_SIZE		- 1 : 0]	valid_table;
	reg		[QUEUE_SIZE		- 1 : 0]	processing_table;
	reg		[QUEUE_SIZE_BIT 	: 0]	counter;
	reg		[QUEUE_SIZE_BIT - 1 : 0]	rd_index;
	reg		[QUEUE_SIZE_BIT - 1 : 0]	wr_index;
	reg		[REQUEST_SIZE	- 1 : 0]	search_entry;
//	reg		[REQUEST_SIZE	- 1 : 0]	entry_next;

	reg		[DATA_WIDTH		- 1 : 0]	data_entry;
	reg		[2:0]	state;
	reg		[3:0]	clc_counter;
	integer	i;
	/********** Logic *********/
	// standard block
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst )	begin
				empty			<= 1'b1;
				full 			<= 1'b0;
				rd_index		<= 0;
				wr_index		<= 0;
				search_entry	<= 0;
				data_entry		<= 0;
				for( i=0 ; i< QUEUE_SIZE ; i=i+1) begin
					valid_table[i]		= 0;
					data_table[i]		= 128'h0;
					processing_table[i]	= 0;
				end

			end	
		end
	end

	// queue full / empty 
	always @ ( counter ) begin
		if( ~rst ) begin
			full 	= ( counter == QUEUE_SIZE );
			empty 	= ( counter == 0) ;
		end
	end
	// state machine
	always @ ( clk ) begin
		if( clk ) begin
			if( rst ) begin
				state 		<= REQUEST_ONLY;
				clc_counter <= 0;
			end
			if( ( op == WR || op== PWB ) && state == REQUEST_ONLY ) begin
				state 		<= RECEIVE_DATA;
				clc_counter <= CYCLE_NUM_DATA ;
			end
			else if(clc_counter == 0) begin
				state		<= REQUEST_ONLY;
				processing_table[wr_index]	= 1'b0;
			end
			else begin
				clc_counter <= clc_counter - 1;
			end
		end
	end 
	
	// counter
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst )
				counter <= 0;
			else if( ( pop_en && ~empty ) && ( push_en && ~full && state == RECEIVE_DATA && clc_counter == 1) )			
				counter <= counter;
			else if( pop_en && ~empty )
				counter <= counter - 1;
			else if( push_en && ~full && 
					( ( op==WR && state == RECEIVE_DATA && clc_counter == 1 ) || 
					  ( op==RD && state == REQUEST_ONLY ) ) )
				counter <= counter + 1;
			else
				counter <= counter;
		end
	end
	

	// read out
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst ) begin
				buf_out  <= 0;
				rd_index <= 0;
				valid_output	<= 1'b0;
			end
			else begin
				// pop + queue not empty + read request
				if( pop_en && ~empty && ~processing_table[rd_index] ) begin
					
					valid_table[rd_index]	<= 1'b0;
					buf_out 				<= queue_table[rd_index];
					dout					<= data_table[rd_index];
					rd_index 				<= rd_index + 1;
					valid_output			<= 1'b1;
				end
				// pop + queue not empty + processing
				else if( pop_en && ~empty && processing_table[rd_index] ) begin
					$display("still receiving data at %d",$time);
				end
				else
					valid_output<= 1'b0;
			end
		end
	end

	// write in 
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst ) begin
				wr_index <= 0;
			end
			else begin
				//$display("in bound");
				if( push_en && ~full && op==RD && state == REQUEST_ONLY &&				// request check
					buf_in[31:0] <= BOUNDARY_UP && buf_in[31:0] >= BOUNDARY_LOW ) begin	// boundary check
					$display("new read request");
					queue_table[wr_index] <= buf_in;
					valid_table[wr_index] <= 1;
					wr_index	<= wr_index + 1;
				end
				else if( push_en && ~full && ( op==WR || op == PWB ) && state == REQUEST_ONLY &&
						 buf_in[31:0] <= BOUNDARY_UP && buf_in[31:0] >= BOUNDARY_LOW ) begin				// boundary check
					$display("new write request");
					queue_table[wr_index] 		<= buf_in;
					valid_table[wr_index] 		<= 1;
					processing_table[wr_index]	<= 1'b1;
				end
				else if ( push_en && ~full && ( op==WR || op == PWB ) && state == RECEIVE_DATA ) begin
					//$display("change_table value");
					data_entry = data_table[wr_index];
					case(clc_counter)
					4:	data_entry[127:96]	= buf_in[31:0];
					3:	data_entry[95:64]	= buf_in[31:0];
					2:	data_entry[63:32]	= buf_in[31:0];
					1:	data_entry[31:0]	= buf_in[31:0];
					endcase
					data_table[wr_index]	= data_entry;
					if( clc_counter == 1) begin
						processing_table[wr_index]	= 1'b0;
						wr_index = wr_index + 1;
					end
					//$display("change_table value finished");
				end
				else if ( buf_in[31:0] > BOUNDARY_UP || buf_in[31:0]< BOUNDARY_LOW ) begin
					//$display("request out of bound");
					//$display("bound: %h - %h.   request: %h ", BOUNDARY_UP, BOUNDARY_LOW, buf_in[31:0]);
				end
				else begin
					//$display("write in not handle");
				end
			end
/*
			else begin
				$display("out of bound");
			end
*/
		end
	end

	// search
	always @ ( clk ) begin
		if ( clk ) begin
			if( search_en ) begin
				$display("Search begin at %d",$time);			
				search_match		= 0;
				search_match_index	= 0;
				search_match_receiving	= 1'b0;
				for( i=0 ; i< QUEUE_SIZE - 1 ; i = i+1 ) begin
					search_entry = queue_table[i];
					// search address match
//					$display("search %d : %h ? %h",i,search_addr[31:4], search_entry[31:4]);					
					if( valid_table[i] && search_addr[31:4] == search_entry[31:4] && search_entry[33:32]== 2'b10 ) begin
						$display("find pwb match %d",$time);						
						search_match 			= 1;
						search_match_index 		= i;
						if( processing_table[i] ) begin				// if still processing
							$display("still processing");
							search_match_receiving	= 1'b1;
						end
					end
				end
			end
		end
	end
	
	// fetch
	always @ ( clk ) begin
		if ( clk ) begin
			if( fetch_en ) begin
				if( processing_table[i] ) begin
					search_match_receiving	= 1'b1;
				end
				else begin
					search_match_receiving	= 1'b1;
					fetch_data	<= data_table[fetch_index];
				end
			end
		end
	end
	
endmodule
