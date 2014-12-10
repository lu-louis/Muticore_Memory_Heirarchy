/*
read / write / read hit
*/

`ifndef DEFFILE
	`include "define.v"
`endif


module	tb_top_hit;

	/* simulation time */
	initial begin 
	#(`CYCLE*10)	$stop;
	end

	/* parameter */
	parameter	ADDR_WIDTH = 32;
	parameter	DATA_WIDTH = 8;
	/* input */
	reg plusclk = 1;
	always	plusclk = #(`CYCLE/2) ~plusclk;
	
	reg	minusclk = 0;
	always	minusclk = #(`CYCLE/2) ~minusclk;
	
	reg	rst = 1;
	initial #(`CYCLE) rst = 0;
	
	
	
	// address partition: 2 processor id, 2 operation id, 2 process id, 
	reg		[ADDR_WIDTH - 1 : 0]	addr_proc_0;	// 
	reg		[ADDR_WIDTH - 1 : 0]	addr_proc_1;
	reg		[ADDR_WIDTH - 1 : 0]	addr_proc_2;
	reg		[ADDR_WIDTH - 1 : 0]	addr_proc_3;
	reg		[DATA_WIDTH - 1 : 0]	din_proc_0;
	reg		[DATA_WIDTH - 1 : 0]	din_proc_1;
	reg		[DATA_WIDTH - 1 : 0]	din_proc_2;
	reg		[DATA_WIDTH - 1 : 0]	din_proc_3;
	/* output*/
	wire	[DATA_WIDTH - 1 : 0]	dout_proc_0;
	wire	[DATA_WIDTH - 1 : 0]	dout_proc_1;
	wire	[DATA_WIDTH - 1 : 0]	dout_proc_2;
	wire	[DATA_WIDTH - 1 : 0]	dout_proc_3;

	/* Initialization */
	initial begin
		// L1a data block
		$readmemh("L1a_data_way0.init",u_top.cache_L1_0.data_block_0.data);
		$readmemh("L1a_data_way1.init",u_top.cache_L1_0.data_block_1.data);
		$readmemh("L1a_data_way2.init",u_top.cache_L1_0.data_block_2.data);
		$readmemh("L1a_data_way3.init",u_top.cache_L1_0.data_block_3.data);
		// L1a tag block
		// flag
		$readmemb("L1a_flag.init"	,u_top.cache_L1_0.tag_table_0.flag_table);	
		$readmemb("L1a_flag.init"	,u_top.cache_L1_0.tag_table_1.flag_table);
		$readmemb("L1a_flag.init"	,u_top.cache_L1_0.tag_table_2.flag_table);
		$readmemb("L1a_flag.init"	,u_top.cache_L1_0.tag_table_3.flag_table);
		// tag
		$readmemh("L1a_tag_way0.init",u_top.cache_L1_0.tag_table_0.addr_tag_table);				
		$readmemh("L1a_tag_way1.init",u_top.cache_L1_0.tag_table_1.addr_tag_table);				
		$readmemh("L1a_tag_way2.init",u_top.cache_L1_0.tag_table_2.addr_tag_table);				
		$readmemh("L1a_tag_way3.init",u_top.cache_L1_0.tag_table_3.addr_tag_table);					
		// PA
		$readmemh("L1a_pa.init",u_top.cache_L1_0.tag_table_0.addr_p_table);				
		$readmemh("L1a_pa.init",u_top.cache_L1_0.tag_table_1.addr_p_table);				
		$readmemh("L1a_pa.init",u_top.cache_L1_0.tag_table_2.addr_p_table);				
		$readmemh("L1a_pa.init",u_top.cache_L1_0.tag_table_3.addr_p_table);				
	end
	
	initial begin
	addr_proc_0	= 32'h04B0_0002;
	din_proc_0	= 8'h0F;
	#(`CYCLE*2)		addr_proc_0 = 32'h14B0_0002;	// write op / except for MSB(1), the rest is useless since rst = 0;	
	#(`CYCLE*2)		addr_proc_0	= 32'h04B0_0002;	// read  op / except for MSB(1), the rest is useless since rst = 0;	
	end

	/* modeling */
	top	u_top(
			.plusclk		( plusclk	),
			.plusclk2		( plusclk2	),
			.plusclk8		( plusclk8	),
			.minusclk		( minusclk	), 
			.minusclk2		( minusclk2	),
			.minusclk8		( minusclk8	),
			.rst			( rst		),
			.addr_proc_0	( addr_proc_0	), 
			.addr_proc_1	( addr_proc_1	),
			.addr_proc_2	( addr_proc_2	),
			.addr_proc_3	( addr_proc_3	),	
			.din_proc_0		( din_proc_0	),
			.din_proc_1		( din_proc_1	),
			.din_proc_2		( din_proc_2	),
			.din_proc_3		( din_proc_3	),
			.dout_proc_0	( dout_proc_0	),
			.dout_proc_1	( dout_proc_1	),
			.dout_proc_2	( dout_proc_2	),
			.dout_proc_3	( dout_proc_3	)
		);




endmodule
