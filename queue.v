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


module	queue(
	// input
	clk, rst, 
	rd_en, wr_en, buf_in,
	// output
	buf_out, valid_output, empty, full
	);
	/********** Parameter *********/
	parameter	DATA_WIDTH		= 32;
	parameter	QUEUE_SIZE		= 8;	// number of entry
	parameter	QUEUE_SIZE_BIT	= 3;
	parameter	COUNTER_WIDTH	= 10;	

	/********** Interface Signal *********/
	input 	clk;
	input 	rst;
	input	rd_en;
	input	wr_en;
	input			[DATA_WIDTH - 1 : 0]	buf_in;

	output	reg		[DATA_WIDTH - 1 : 0]	buf_out;
	output	reg		empty;
	output	reg		full;
	output	reg		valid_output;

	/********** Internal signal *********/
	reg		[DATA_WIDTH - 1 :0]			queue_table	[QUEUE_SIZE - 1 : 0];
	reg		[QUEUE_SIZE_BIT 	: 0]	counter;
	reg		[QUEUE_SIZE_BIT - 1 : 0]	rd_index;
	reg		[QUEUE_SIZE_BIT - 1 : 0]	wr_index;

	/********** Logic *********/
	// standard block
	always @ ( clk ) begin
		if ( clk ) begin
			
		end
	end

	// queue full / empty 
	always @ ( counter ) begin
		full 	= ( counter == QUEUE_SIZE );
		empty 	= ( counter == 0) ;
/*		if( counter == QUEUE_SIZE )			
		// no read out and queue is full
			full 	<= 1;
		else if( counter == 0 )
		// no write in and queue is emptry
			empty 	<= 1;
		end
		else begin
			ful	<=
		end
*/
	end

	// counter
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst )
				counter <= 0;
			else if( ( rd_en && ~empty ) && ( wr_en && ~full) )			
				counter <= counter;
			else if( rd_en && ~empty )
				counter <= counter - 1;
			else if( wr_en && ~full )
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
				// queue not empty + read request
				if( rd_en && ~empty ) begin
					buf_out 	<= queue_table[rd_index];
					rd_index 	<= rd_index + 1;
					valid_output<= 1'b1;
				end
				else
					valid_output<= 1'b0;
			end
		end
	end

	// write in 
	always @ ( clk ) begin
		if ( clk ) begin
			if( rst ) 	
				wr_index <= 0;
			else begin
				if( wr_en && ~full ) begin
					queue_table[wr_index] <= buf_in;
					wr_index	<= wr_index + 1;
				end
			end
		end
	end

	
endmodule
