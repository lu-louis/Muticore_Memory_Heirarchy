/**





*/
`ifndef	DEFFILE
	`include "define.v"
`endif


module	tag_table_L2(
	// input
	index, we_flag, we_tag, new_flag, new_tag,
	// output
	req_flag, req_tag
	);
	/********** paramter **********/	
	parameter	FLAG_WIDTH		= 1;
	parameter	INDEX_WIDTH		= 10;
	parameter	TAG_WIDTH		= 18;
	parameter	NUM_OF_ENTRY	= `_1K;
	/********** interface signal **********/
	input	[INDEX_WIDTH 	- 1 : 0]	index;
	input	we_flag;
	input	we_tag;
	input	new_flag;
	input	[TAG_WIDTH		- 1 : 0]	new_tag;

	output	reg							req_flag;
	output	reg	[TAG_WIDTH	- 1 : 0]	req_tag;

	/********** internal signal **********/
	reg		[TAG_WIDTH	 - 1 : 0]	tag_table	[NUM_OF_ENTRY - 1 : 0];
	reg		[FLAG_WIDTH	 - 1 : 0]	flag_table	[NUM_OF_ENTRY - 1 : 0];

	/********** logic **********/
	always @ (*) begin
		// write operation
		if(we_tag)	tag_table[index] = new_tag;
		if(we_flag)	tag_table[index] = new_tag;
		
		// read operatoin
		req_tag		= tag_table[index];
		req_flag	= flag_table[index];
	end



endmodule
