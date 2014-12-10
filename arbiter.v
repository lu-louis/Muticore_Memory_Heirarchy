/*



*/


module arbiter(
    // input
    plusclk, minusclk, rst,
    req_1, 	req_2, 	req_3, req_4,
	type_1, type_2, type_3, type_4,
	hold_1, hold_2, hold_3, hold_4,
    // output
    grant_1, grant_2, grant_3, grant_4,
	bus_active

    );
    
    /*********** parameter ***********/
	localparam		NUM_UNIT = 	4;
	parameter		CYCLE_RATIO	 = 2;
    /*********** interface signal ***********/
    // global signal
    input    plusclk;    // Clock
    input    minusclk;
    input    rst;        // Reset
    
    input	req_1;
    input	req_2;
    input	req_3;
	input	req_4;
	input	type_1;	// [0] write (RD/WR/WB)	[1]	priority write (PWB)
	input	type_2;
	input	type_3;
	input	type_4;
	input	hold_1;
	input	hold_2;
	input	hold_3;
	input	hold_4;

	output	grant_1;
	output	grant_2;
	output	grant_3;
	output	grant_4;
	output	reg		bus_active;
    /*********** internal signal ***********/
//	reg		[8-1:0]		request_array;
	reg		[NUM_UNIT	- 1 : 0]		request_array;
	reg		[NUM_UNIT	- 1 : 0]		type_array;
	reg		[NUM_UNIT	- 1 : 0]		hold_array;
    reg		[NUM_UNIT	- 1 : 0]		grant_array;
	reg		[1 : 0]		i;
	reg		[1 : 0]		prio;

	reg		[3 : 0]		delay_counter;    

    assign	grant_1 = grant_array[0];
    assign	grant_2 = grant_array[1];
    assign	grant_3 = grant_array[2];
	assign	grant_4	= grant_array[3];

	/*********** internal component ***********/
	/*********** logic ***********/
    /****** plus clock ******/
    // Load the new request 
    always @ ( plusclk ) begin
        if ( plusclk ) begin
			if(rst)				prio <= 0;
			else if(prio == 2)	prio <= 0;
			else 				prio <= prio + 1;
			if( rst ) begin
				request_array	<= 3'b0;
				type_array		<= 3'b0;
				hold_array		<= 3'b0;
			end
			else begin
//            request_array <= { req_1 ,  type_1, req_2, type_2, req_3, type_3, 2'b00 };
				request_array 	<= { req_4, req_3, req_2, req_1 };
				type_array		<= { type_4, type_3, type_2, type_1 };
				hold_array		<= { hold_4, hold_3, hold_2, hold_1 };
			end
        end
    end
    
    always @ ( * ) begin
        
    end
    
    // Load grant decision
    always @ ( plusclk ) begin
        if ( plusclk ) begin
			if( rst ) begin
				delay_counter 	<= 0;
				bus_active		<= 1'b0;
			end
			else begin
				if( grant_array ) begin
					bus_active <= 1;
					if( ( grant_array[2] == 1 || grant_array[3] == 1 ) && delay_counter ==0)
						delay_counter <= CYCLE_RATIO - 1;
					else
						delay_counter = delay_counter -1;
				end
				else begin
					bus_active <= 0;
				end
			end
        end
    end
    
    /****** minus clock ******/    
    // decoode
    always @ ( minusclk ) begin
        if( minusclk ) begin
			if( rst ) begin
				grant_array	<= 4'b0;
			end
//			else if( ~hold_array[0] && ~hold_array[1] && ~hold_array[2] ) begin	// if no device is holding the bus
			else if( ~hold_1 && ~hold_2 && ~hold_3 && ~hold_4 && delay_counter ==0 ) begin	// if no device is holding the bus
	            // first detect priority write back
	            // if detected, one and only one device will be sent. 
	            // only higher level cache will trigger PWB => 2 device
				if	   ( type_array[0] && request_array[0] ) 	grant_array <= 4'b0001;		// higher level memory unit PWB
				else if( type_array[1] && request_array[1] )	grant_array <= 4'b0010;		// higher level memory unit PWB
				else if( type_array[2] && request_array[2] )	grant_array <= 4'b0100;		//
				else if( type_array[3] && request_array[3] )	grant_array <= 4'b1000;		//
				else if( request_array[0] || request_array[1] || request_array[2] || request_array[3]) begin		// new request arrive
					if( prio == 0 && request_array[0] )			grant_array <= 4'b0001;
					else if (prio == 1 && request_array[1] )	grant_array <= 4'b0010;
					else if (prio == 2 && request_array[2] )	grant_array <= 4'b0100;
					else if (prio == 3 && request_array[3] )	grant_array <= 4'b1000;
					else if ( request_array[0] )				grant_array <= 4'b0001;
					else if ( request_array[1] )				grant_array <= 4'b0010;
					else if ( request_array[3] )				grant_array <= 4'b0100;
					else if ( request_array[2] )				grant_array <= 4'b1000;
					else 										grant_array <= 4'b0000;
				end
				else
					grant_array	<= 4'b0000;
			end
        end
    end
    
    
    
endmodule



