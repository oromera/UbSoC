/////////////////////////////////////////////////////////////////////
////                                                             ////
////  simple_spi  testbench                                      ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2004 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: tst_bench_top.v,v 1.1 2004-02-28 16:01:47 rherveille Exp $
//
//  $Date: 2004-02-28 16:01:47 $
//  $Revision: 1.1 $
//  $Original Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
//  Modified by Omar Romera Aller 2020-08-10
// 	Change History:
//               Adapted for a new SPI master and SPI slave
//
//

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

// Definicio de registres
`define SPICTRL  8'h00   // WR
`define SPISTAT  8'h01   // R
`define SPIBUFF  8'h02   // WR
`define SPISS    8'h03   // WR
`define SPIPRE   8'h04   // WR

module tb_spi();

	//
	// wires && regs
	//
	reg  clk;
	reg  rstn;

	reg [1:0] cpol, cpha;
	reg [2:0] e = 0;

	wire sck, mosi, miso;
	wire [7:0] ss;
	reg [7:0] q;

	wire test_spi_cpol;
	wire test_spi_cpha;

	// Parameters
	parameter HALF_CLOCK_PERIOD_50M 	= 10;
	parameter HALF_CLOCK_PERIOD_10M 	= 50;
	parameter HALF_CLOCK_PERIOD_1M 		= 500;
	parameter HALF_CLOCK_PERIOD_100K 	= 5000;
	parameter PERIOD = 100;

	event read, write, compare, acknow, check, change_cpol, change_cpha;

	//
	// Module body
	//
	integer n;

	reg wr_en = 0;
	reg rd_en = 0;
	reg [7:0] addr = 0;
	reg [7:0] data_i = 0;
	wire [7:0] data_o;

	reg en_slv = 0;

	wire int;

	integer div;

	parameter PRESCALE_DIV = 15;

	//clock 10M
	always begin		
    		clk   = 1;
    		# HALF_CLOCK_PERIOD_50M;
    		clk   = 0;
    		# HALF_CLOCK_PERIOD_50M;
	end

	//tasks
	task WaitClock;
		begin
			@(posedge clk);
			#PERIOD;
			#PERIOD;
		end
	endtask

	task DivCalc;
		begin
			case (e[1:0])
	      		2'b00: div <= 4;   	// 4
	      		2'b01: div <= 8;   	// 8
	      		2'b10: div <= 16;   // 16
	      		2'b11: div <= 2*(PRESCALE_DIV+1); // CPre
	    	endcase
	    end
	endtask

	task write_reg; 
		input [7:0] sel_addr;
		input [7:0] data_w;
		begin
			@(posedge clk);
			addr   = sel_addr;
			data_i = data_w;
			wr_en  = 1'b1;
			//WaitClock;
			-> write;
			@(posedge clk);
			wr_en  = 1'b0;
			if(sel_addr == `SPIBUFF) begin
				while (~int) @(posedge clk);
			end
			data_i = {8{1'bz}};
			addr   = {8{1'bz}};
			wr_en  = 1'b0;
		end		
	endtask	

	task read_reg; 
		input  [7:0] sel_addr;
		begin
			@(posedge clk);
			addr   = sel_addr;
			rd_en  = 1'b1;
			-> read;
			@(negedge clk);
			$display("Read data: %h",data_o);
			@(posedge clk);
			addr   = {8{1'bz}};
			rd_en  = 1'b0;
		end		
	endtask	

	task comp_reg;
		input [7:0] sel_addr; 
		input [7:0] d_exp;		
		begin
			@(posedge clk);
			addr   = sel_addr;
			rd_en  = 1'b1;
			-> compare;
			@(negedge clk);
			@(posedge clk);
			addr   = {8{1'bz}};
			rd_en  = 1'b0;

			-> acknow;
			if(d_exp != data_o) $display("Data compare error. Received %h, expected %h with clock divider: %d", data_o, d_exp, div);
			else $display("Data compare correct. Received %h, expected %h with clock divider: %d", data_o, d_exp, div);
			
		end
	endtask

	// hookup spi core
	spi_master_top spi_top (
		.Clk 	 (clk),
		.Rst_n 	 (rstn),

		.Wr 	 (wr_en),
		.Rd 	 (rd_en),

		.Addr 	 (addr),
		.DataIn  (data_i),
		.DataOut (data_o),

		.SCLK 	 (sck),
		.MOSI	 (mosi),
		.MISO	 (miso),
		.SS 	 (ss),

		.Int 	 (int)
	);

	spi_slave_model_2 spi_slave (
		.clock  (clk),
		.csn 	(ss[0]),
		.sck 	(sck),
		.di 	(mosi),
		.do 	(miso),

		.cpol_i (test_spi_cpol  ),
		.cpha_i (test_spi_cpha  )
	);

	assign test_spi_cpol = spi_top.MSTR_CTRL.CPol;
	assign test_spi_cpha = spi_top.MSTR_CTRL.CPha;

	initial
	  begin
	      $display("\nStatus: Testbench started\n");

	      // initially values
	      clk = 0;
	      // reset system
	      rstn = 1'b1; // negate reset
	      #5;
	      rstn = 1'b0; // assert reset
	      repeat(1) @(posedge clk);
	      rstn = 1'b1; // negate reset

	      $display("Reset Done");

	      @(posedge clk);

	      cpol = 0;
	      cpha = 0;

	      //
	      // testbench core
	      //
	      //for (cpol=0; cpol<=1; cpol=cpol+1) begin
		for (cpha=0; cpha<=1; cpha=cpha+1) begin
	      	//write_reg(`SPISS, 8'h01);
	      	->change_cpha;
			#20;
	      //for (cpha=0; cpha<=1; cpha=cpha+1) begin
		for (cpol=0; cpol<=1; cpol=cpol+1) begin
	      	->change_cpol;
		//write_reg(`SPISS, 8'h01);	      	
		#20;
		
		$display("\n/////////////////////");
		$display("CPOL = %b   CPHA = %b", cpol[0], cpha[0]);
	      for (e=0; e<=3; e=e+1)
	      begin

	      	  DivCalc;

	          // program internal registers
	          // load control register
	          write_reg(`SPICTRL, {4'b1101,cpol[0],cpha[0],e[1:0]});

	          // load extended control register
	          write_reg(`SPIPRE, PRESCALE_DIV);

	          // load select slave register
	          write_reg(`SPISS, 8'h00);


	          for(n=0;n<8;n=n+1) begin
		          //////////////////////////////
		          // send write command
		          write_reg(`SPIBUFF, {cpol[0],cpha[0],e[1:0],n[3:0]});

		          -> check;
				  $display("Write data: %h",{cpol[0],cpha[0],e[1:0],n[3:0]});
				  
				  $displayh("MEM data: %p",spi_slave.mem);

		      end

		      for(n=0;n<8;n=n+1) begin
		          //////////////////////////////
		          // send read command
		          write_reg(`SPIBUFF, ~n);

		          comp_reg(`SPIBUFF,{cpol[0],cpha[0],e[1:0],n[3:0]});
	          end
	      end
		end
		end
	      #250000; // wait 250us
	      $display("\n\nStatus: Testbench done\n\n");
 	      $stop;
	  end

endmodule


