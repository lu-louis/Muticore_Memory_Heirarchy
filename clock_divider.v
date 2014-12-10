
module clock_divider(
	// input
	clk,
	ratio_0, ratio_1,
	//
	clk_d_0,clk_d_1

	);

	// 
	input	clk;
	input	ratio_0;
	input	ratio_1;

	output	reg		clk_d_0;
	output	reg		clk_d_1;
	reg		[9:0]	counter;

	initial begin 
	counter = 0;
	clk_d_0 = clk;
	
	end

	
	always @ ( clk ) begin
		if( clk ) begin
			
			if( counter == ratio_0 )
				if( clk_d_0 )
			counter = counter + 1;
		end
	end

