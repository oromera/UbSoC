/////////////////////////////////////////////////////////////////////
////                                                             ////
////  SPI Slave Model                                            ////
////                                                             ////
////  Authors: Richard Herveille (richard@asics.ws) www.asics.ws ////
////                                                             ////
////  http://www.opencores.org/projects/simple_spi/              ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2004 Richard Herveille                        ////
////                         richard@asics.ws                    ////
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
//  $Id: spi_slave_model.v,v 1.1 2004-02-28 16:01:47 rherveille Exp $
//
//  $Date: 2004-02-28 16:01:47 $
//  $Revision: 1.1 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//
//
//


// Requires: Verilog2001

// synopsys translate_off
`timescale 1 ns / 10 ps
// synopsys translate_on

module spi_slave_model_2 (
	input  wire clock,
	input  wire csn,
	input  wire sck,
	input  wire di,
	output wire do,
	input  wire cpol_i,
	input  wire cpha_i
);

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clock) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	//
	// Variable declaration
	//

	//wire cpol = 1'b0;
	//wire cpha  = 1'b0;

	reg [7:0] mem [7:0]; // initiate memory
	reg [2:0] mem_adr = 0;   // memory address

	reg [7:0] sri = 0;
	reg [7:0] sro = 0;  // 8bit shift register

	reg [2:0] bit_cnt = 3'b111;
	reg       ld = 0;

	wire clk;

	reg [16:0] mem_cnt = 0;

	//
	// module body
	//

	assign clk = cpol_i ^ cpha_i ^ sck;

	// generate shift registers
	always @(posedge clk)
	  		sri <= {sri[6:0],di}; //#1



	always @(negedge clk)
		if (&bit_cnt)
			sro <=  mem[mem_adr]; //#1 
		else
			sro <=  {sro[6:0],1'b0}; //#1 

	assign do = sro[7];

	//generate bit-counter
	always @(posedge clk, posedge csn)
		if(csn)
	    	bit_cnt <=  3'b111; //#1
	  	else
	    	bit_cnt <=  bit_cnt - 3'h1; //#1

	//generate access done signal
    always @(posedge clk)
		ld <= ~(|bit_cnt);

	always @(negedge clock) begin
		if (ld && clk && mem_cnt == 1) begin
			mem[mem_adr] <=  sri; //#1
	    	mem_adr      <= mem_adr + 1'b1; //#1 
	    end else begin
	    	mem[mem_adr] <=  mem[mem_adr]; //#1
	    	mem_adr      <=  mem_adr; //#1
	    end
	end

	always @(posedge clock) begin
		if(ld && clk) begin
			mem_cnt <= mem_cnt + 1;
		end
		else mem_cnt <= 0;
	end

/*	initial
	begin
		bit_cnt = 3'b111;
		ld = 0;
		mem_adr = 0;
		sri = 0;
		sro = mem[mem_adr];
		mem_cnt = 0;
	end*/
endmodule


