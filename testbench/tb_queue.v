/*
Interface:
@clk
@rst
@rd_en
@wr_en
@buf_in

@buf_out
@emptry
@full
*/

`ifndef DEFFILE
	`include "define.v"
`endif

module tb_queue;
	/********** Parameter *********/
	parameter	ADDR_WIDTH	 	= `_4B;
	parameter	DATA_WIDTH		= 32;
	parameter	QUEUE_SIZE		= 8;	// number of entry
	parameter	QUEUE_SIZE_BIT	= 3;
	parameter	COUNTER_WIDTH	= 10;	

	/********** input *********/
	reg	clk = 1;
	always clk = #(`CYCLE/2) ~clk;

	reg rst;
	

	
	reg 	rd_en;
	reg 	wr_en;
	reg		[DATA_WIDTH - 1 : 0]	tmp_data;
	reg		[DATA_WIDTH	- 1 : 0]	buf_in = 32'h00A0;
	wire	[DATA_WIDTH	- 1 : 0]	buf_out;
	wire	empty;
	wire	full;

	queue	#(.DATA_WIDTH (32))
			u_queue(
				.clk	( clk 	),
				.rst	( rst	),
				.rd_en	( rd_en	),
				.wr_en	( wr_en	), 
				.buf_in	( buf_in ),
				// output
				.buf_out	( buf_out	),
				.empty	( empty ), 
				.full	( full	)
				
			);


	initial begin
		clk 	= 1;
		rst 	= 1;
		rd_en	= 0;
		wr_en	= 0;
		buf_in	= 0;
		tmp_data = 0;
	#(`CYCLE)
		rst = 0;
		

        fork
           push(10);
           pop(tmp_data);
        join              //push and pop together   
		fork
			push(20);
			pop(tmp_data);
		join
        push(30);
        push(40);
        push(50);
        push(60);
        push(70);
        push(80);
        push(90);
        push(100);


        pop(tmp_data);
        push(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
   push(140);
        pop(tmp_data);
        push(tmp_data);//
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        pop(tmp_data);
        push(5);
        pop(tmp_data);
	#(`CYCLE*10)
		$stop;
	end

	
task push;
	input[DATA_WIDTH - 1 :0] data;
	if( full )
		$display("---Cannot push: Buffer Full---");
	else begin
		$display("Pushed ",data );
		buf_in = data;
		wr_en = 1;
		@(posedge clk);
		#(`CYCLE) wr_en = 0;
	end
endtask

task pop;
output [DATA_WIDTH:0] data;
   if( empty )
		$display("---Cannot Pop: Buffer Empty---");
	else begin
		rd_en = 1;
		@(posedge clk);
        #(`CYCLE)	rd_en = 0;
		data = buf_out;
		$display("-------------------------------Poped ", data);
	end
endtask


endmodule
