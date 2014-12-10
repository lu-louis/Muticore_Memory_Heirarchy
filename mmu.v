
`ifndef DEFFILE
	`include "define.v"
`endif


module mmu(
	// input
	va,
	// output
	found, pa
	);
	/********* parameter ********/
	parameter	ADDR_V_WIDTH	= 26;
	parameter	ADDR_P_WIDTH	= 30;	// - 2 bit offset
	parameter	DEPTH			= `_1K;
	/********** interface signal **********/
	input	[ADDR_V_WIDTH - 1 : 0]	va;

	output	reg							found;
	output	reg	[ADDR_P_WIDTH - 1 : 0]	pa;


	/********** internal signal **********/
	reg		[ADDR_V_WIDTH - 1 : 0]	va_table	[DEPTH - 1 : 0];
	reg		[ADDR_P_WIDTH - 1 : 0]	pa_table	[DEPTH - 1 : 0];
	
	integer i;
	wire	en = 1'b1;
	/********** initialization signal **********/
	// testing purpose
	/*
	initial begin 
		$readmemh("mmu_va.init", va_table);
		$readmemh("mmu_pa.init", pa_table);
	end
	*/
	/********** logic **********/
	always @ ( va ) begin
		if( en ) begin
			found = 1'b0;
			for ( i = 0 ; i < DEPTH ; i = i + 1 ) begin
				if( va_table[i] == va ) begin
					pa		= pa_table[i];
					found 	= 1'b1;
				end
			end
		end
	end


endmodule
