/*
File	:
Title	:
Project	: ECE 254A Project 2
Author	: Chieh Lu
Description	:



Interface:
Operates on MINUS clock

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



`include "define.v"


module arbiter_interface_handler(
	// input
	clk, rst, 
	dev_req, dev_req_type, 	// device
	tran_cycle,		
	grant, active,			// arbiter
	// output
	get, bus_active,		// device
	request, request_type, 	// arbiter
	hold, 	
	bus_direction			// bus_interface
	);
	/*********** Parameter ***********/
	parameter	RD_PRIO	 = 0;
	parameter	WR_PRIO	 = 0;
	parameter	PWB_PRIO = 1;
	
	localparam	RD	 = 2'b00;
	localparam	WR	 = 2'b01;
	localparam	PWB	 = 2'b10;
	localparam	IDLE = 2'b11;
	/*********** Interface Signal ***********/
	// global signal
	input	clk;
	input	rst;	
	
	// arbiter interface
	input	grant;
	input	active;
	output	reg		hold;
	output	reg		request;
	output	reg		request_type;

	// device interface
	input	dev_req;
	input	dev_req_type;
	input	[5:0]	tran_cycle;	// request cycle number
	output	reg		get;
	output	reg		bus_active;

	// bus interface
	output	reg		bus_direction;
	
	/*********** Internal Signal ***********/		
	reg		[`_1B - 1 :0]	cycle_counter;
	reg		grant_flag;					// [0] not yet recongnized	[1] processing


	/*********** Logic ***********/		
	always @ ( clk ) begin
		if( clk ) begin
			if(rst) begin
				cycle_counter	<= 0;
				grant_flag	 	<= 1'b0;
				get				<= 1'b0;
				bus_active		<= 1'b0;
				request			<= 1'b0;
				request_type	<= 1'b0;
				hold	 	 	<= 1'b0;
				bus_direction	<= 1'b0;
			end
			// Start of transfer
			else if( grant && ~grant_flag ) begin		
				cycle_counter <= tran_cycle - 1;
				hold	  	  <= 1'b1;
				get			  <= 1'b1;
				bus_direction <= 1'b1;
				grant_flag	  <= 1'b1;
			end
			// End of transfer
			else if( grant && cycle_counter == 0 ) begin			
				cycle_counter <= 0;
				request		  <= 1'b0;
				hold	  	  <= 1'b0;
				get			  <= 1'b0;
				bus_direction <= 1'b0;
				grant_flag	  <= 1'b0;
			end
			// During transfering period
			else if( grant && grant_flag ) begin							
				cycle_counter <= cycle_counter - 1;
			end
			// New request arrive
			else if ( dev_req == 1'b1 ) begin
				request			<= 1'b1;
				request_type	<= dev_req_type;
			end
		end
	end

	always @ ( clk ) begin
		if( clk ) begin
			if( active ) 
				bus_active <= 1'b1;
			else
				bus_active <= 1'b0;
		end
	end


endmodule
