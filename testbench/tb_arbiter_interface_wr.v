/*  
File	: tb_arbiter_interface_wr.v
Title	: testbench for arbiter_interface_handler
Project	: ECE 254A Project 2
Author	: Chieh Lu
Description :

Reference	:

Operates at MINUS clock

-- input --
@clk			:	Clock
@rst			:	Reset
@dev_req		: 	bus request [0] inactive [1] active
@dev_req_type	:	Request type: Write / Priority Write
@tran_cycle		:	number of cycle required to finish transfer.
@grant	 		:	Bus granted by arbiter
@active			: 	If the bus is active. 
-- output --
@get			:	Inform the device the bus is granted
@bus_active		:	bus active. Treet decode information importantly
@request		:	Bus request send to arbiter.
@request_type	:	Type of bus request: Write back, Prioirty write back
@hold			:	Hold the bus for transfer until finish
					Signal high informs arbiter not to grant permission to other device
@bus_directoin	:	bus interface direction selection [0] read [1] write

*/

`ifndef	DEFFILE
	`include "define.v"
`endif

`tscale

module tb_arbiter_interface_wr;
	
	localparam 	RD 	 = 0;
	localparam	WR 	 = 1;
	localparam	PWB  = 2;
	localparam	IDEL = 2'b11;
	
	// run time control
	initial begin 
		#(`CYCLE*12)	$stop;
	end
	/*********** Input ***********/
	// global signal
	// minus clock
	reg clk = 0;
	always clk = #(`CYCLE/2)	~clk;
	// reset signal
	reg rst = 1;
	initial begin
	#`CYCLE		rst	= 0;
	end
	
	// device
	reg dev_req	= 1;
	initial begin 
	#(`CYCLE*4)	dev_req = 0;
	end
	reg	dev_req_type = WR;
	reg	[`_1B - 1:0]	tran_cycle = 2;

	// arbiter
	reg grant = 0;
	initial begin 
	#(`CYCLE*4)	grant = 1;
	#(`CYCLE*4)	grant = 0;
	end

	// active
	reg	active = 0;	

	/*********** Output ***********/
	wire	get;
	wire	bus_active;
	wire	request;
	wire	reques_type;
	wire	hold;
	wire	bus_direction;

	/*********** Modeling ***********/

	arbiter_interface_handler	u_arbiter_interface_handler(
									// input
									.clk	( clk 	),
									.rst	( rst 	),
									.dev_req		( dev_req 		),
									.dev_req_type	( dev_req_type 	),
									.tran_cycle		( tran_cycle 	),
									.grant	( grant ),
									.active ( active),
									// output
									.get	( get	),
									.bus_active		( bus_active 	),
									.request		( request 		),
									.request_type	( request_type	),
									.hold	( hold	),
									.bus_direction	( bus_direction )
								);


endmodule
