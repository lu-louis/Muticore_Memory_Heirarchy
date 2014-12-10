

`ifndef DEFFILE
	`include	"define.v"
`endif

`tscale

module tb_dram_pwb;

	/********** Parameter *********/
	parameter	BUS_WIDTH	= 38;
	parameter	ADDR_WIDTH	= 32;
	parameter	DATA_WIDTH	= 128;
	parameter	BUS_DATA_WIDTH	= 32;
	parameter	INDEX_WIDTH	= 28;

	/********** input *********/
	// global
	reg		plusclk;
	reg		minusclk;
	reg		rst;

	// bus	
	wire	[BUS_WIDTH		- 1 : 0]	bus;
	reg		[BUS_WIDTH		- 1 : 0]	bus_reg;
	// arbiter
	reg		bus_active;
	reg		bus_grant;
	

	/********** output *********/
	wire	bus_request;
	wire	bus_request_type;
	wire	[5:0]	bus_request_clc;
	/********** model *********/
	dram	u_dram(
				// input
				.plusclk	( plusclk	), 
				.minusclk	( minusclk	), 
				.rst		( rst	), 
				.bus		( bus	), 
				.bus_active	( bus_active	), 
				.bus_grant	( bus_grant ), 
				// output
				.bus_req		( bus_request		), 
				.bus_req_type	( bus_request_type	), 
				.bus_req_clc	( bus_request_clc	)
			);
	/********** simulation *********/
	initial begin
	plusclk  = 1;
	minusclk = 0;
	rst 	 = 1;
	bus_active	= 0;
	bus_grant	= 0;
	bus_reg		= 38'h00;

	$readmemh("dram.init",u_dram.data_block.data);

	#(`CYCLE)	rst = 0;
	#(`CYCLE)	bus_active	= 1;			// bus active
				bus_reg 	= 38'h18_0000_0000;	// physical address: proc ID:1, PID:2, op: 0(read)
	#(`CYCLE)	bus_active  = 1;
				bus_reg		= 38'h2E_0000_0001;	// physical address: proc ID:2, PID:b11, op:b10
	#(`CYCLE)	bus_reg		= 38'h2D_1122_3344;	// physical address
	#(`CYCLE)	bus_reg		= 38'h2D_5566_7788;	// physical address
	#(`CYCLE)	bus_reg		= 38'h2D_9900_AABB;	// physical address
	#(`CYCLE)	bus_reg		= 38'h2D_CCDD_EEFF;	// physical address
	#(`CYCLE)	bus_active	= 0;
	#(`CYCLE*4)	bus_active 	= 1;
				bus_grant	= 1;
				bus_reg		= 38'h00_0000_0000;
	#(`CYCLE*6)	bus_grant	= 0;
				bus_active	= 0;
				bus_reg		= 38'hFF_FFFF_FFFF;
	#(`CYCLE*14)	$stop;
	end

	always	plusclk = #(`CYCLE/2)	~plusclk;
	always	minusclk = #(`CYCLE/2)	~minusclk;
	assign	bus	= bus_grant	? 38'hz: bus_reg ;

endmodule

