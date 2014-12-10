/*

Description:
Elements included: data

Interface:
-- input --
@index	: request entry index 
@we		: write enable
@din	: input data
-- output --
@dout	: data value of request entry


*/

`ifndef	DEFFILE
	`include "define.v"
`endif

module cache_block(
	// input
	index, we, din,
	// output
	dout
	);
	/********** Parameter *********/
	parameter	NUM_OF_ENTRY	= `_1K;
	parameter	ENTRY_WIDTH		= 10;
	parameter	DATA_WIDTH		= `_4B;
	
	/********** Interface Signaln *********/
	// read port	
	input	[ENTRY_WIDTH 	- 1	: 0]	index;
	input	we;
	input	[DATA_WIDTH 	- 1	: 0]	din;

	output	[DATA_WIDTH 	- 1	: 0]	dout;
	reg		[DATA_WIDTH 	- 1	: 0]	dout;
	
	/********** Internal Signaln *********/
	reg		[DATA_WIDTH 	- 1	: 0]	data	[NUM_OF_ENTRY - 1 : 0];
		
	/********** Initialization *********/
/*
	initial begin
		$readmemh("cacheL1_data_table.init", data);
	end
*/
	/********** Logic control *********/
	// read  
	always @ (*) begin
		dout 	<= data[index];
	end

	// write 
	always @ ( * ) begin
		if( we ) begin
			data[index] <= din;
		end		
	end



endmodule
