//
// TFGSoC - PicoSoC (Claire Wolf) implementation for Altera devices
//
// Copyright (C) 2022 Omar Romera Aller
//
// Permission to use, copy, modify, and/or distribute this software for any 
// purpose with or without fee is hereby granted, provided that the above 
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR 
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES 
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN 
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF 
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
/////////////////////////////////////////////////////////////////////
////                                                             ////
////  WISHBONE revB.2 compliant I2C Master controller Top-level  ////
////                                                             ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/projects/i2c/    ////
////                                                             ////
////  Modified by Omar Romera                                    ////
////                                                             ////
////  Modification:                                              ////
////				 2020/07/06                                  ////
////			     Wishbone interface removed.                 ////
////				 Custom interface for PicoSoC added.         ////
////                                                             ////                                                      ////
/////////////////////////////////////////////////////////////////////


// synopsys translate_off
`timescale 1ns / 10ps
// synopsys translate_on

module i2c_master_top (
	input clk_i,
	input arst_i,
	
	// register enables
	input  en_prer_lo_i,    	// clock prescale register low byte enable
	input  en_prer_hi_i,    	// clock prescale register high byte enable
	input  en_ctr_i,       		// control register enable
	input  en_txr_i,        	// transmit register enable
	input  en_cr_i,         	// command register enable

	// input and output data
	input  [7:0] reg_i,     	// general register input
	output reg [7:0] rxr_o,     // receive register
	output reg [7:0] sr_o,      // status register
	
	// I2C signals
	// i2c clock line
	input  scl_pad_i,       	// SCL-line input
	output scl_pad_o,       // SCL-line output (always 1'b0)
	output scl_padoen_o,    // SCL-line output enable (active low)

	// i2c data line
	input  sda_pad_i,       	// SDA-line input
	output sda_pad_o,       // SDA-line output (always 1'b0)
	output sda_padoen_o     // SDA-line output enable (active low)
	);

	//
	// variable declarations
	//

	// registers
	reg  [15:0] prer; 	// clock prescale register
	reg  [ 7:0] ctr;  	// control register
	reg  [ 7:0] txr;  	// transmit register
	wire [ 7:0] rxr;  	// receive wire
	reg  [ 7:0] cr;   	// command register
	wire [ 7:0] sr;  	// status wire

	// done signal: command completed, clear command register
	wire done;

	// core enable signal
	wire core_en;
	wire ien;

	// status register signals
	wire irxack;
	reg  rxack;       // received aknowledge from slave
	reg  tip;         // transfer in progress
	reg  irq_flag;    // interrupt pending flag
	wire i2c_busy;    // bus busy (start signal detected)
	wire i2c_al;      // i2c bus arbitration lost
	reg  al;          // status register arbitration lost bit

	// input registers assignments
	always @(posedge clk_i or negedge arst_i) begin
		if (!arst_i) begin
			prer <= 16'hFFFF;
			ctr <= 8'h00;
			txr <= 8'h00;
			cr <= 8'h00;
		end
		else if (done | i2c_al) begin
			prer <= prer;
			ctr <= ctr;
			txr <= txr;
			cr <= 8'h00;			
		end
		else begin
			if (en_prer_lo_i) begin
				prer [7:0] <= reg_i;
				prer [15:8] <= prer [15:8];
				ctr <= ctr;
				txr <= txr;
				cr <= cr;
			end
			else if (en_prer_hi_i) begin
				prer [7:0] <= prer [7:0];
				prer [15:8] <= reg_i;
				ctr <= ctr;
				txr <= txr;
				cr <= cr;
			end
			else if (en_ctr_i) begin
				prer [7:0] <= prer [7:0];
				prer [15:8] <= prer [15:8];
				ctr <= reg_i;
				txr <= txr;
				cr <= cr;
			end
			else if (en_txr_i) begin
				prer [7:0] <= prer [7:0];
				prer [15:8] <= prer [15:8];
				ctr <= ctr;
				txr <= reg_i;
				cr <= cr;
			end
			else if (en_cr_i) begin
				prer [7:0] <= prer [7:0];
				prer [15:8] <= prer [15:8];
				ctr <= ctr;
				txr <= txr;
				cr <= reg_i;
			end
			else begin
				prer <= prer;
				ctr <= ctr;
				txr <= txr;
				cr <= cr;
			end
		end
	end

	// output registers assignments
	always @(clk_i) begin
		sr_o = sr;
		rxr_o = rxr;
	end


	//
	// module body
	//

	// decode command register
	wire sta  = cr[7];
	wire sto  = cr[6];
	wire rd   = cr[5];
	wire wr   = cr[4];
	wire ack  = cr[3];
	wire iack = cr[0];

	// decode control register
	assign core_en = ctr[7];
	assign ien = ctr[6];

	// hookup byte controller block
	i2c_master_byte_ctrl byte_controller (
		.clk      ( clk_i     	 ),
		.rst      ( 1'b0         ),
		.nReset   ( arst_i       ),
		.ena      ( core_en      ),
		.clk_cnt  ( prer         ),
		.start    ( sta          ),
		.stop     ( sto          ),
		.read     ( rd           ),
		.write    ( wr           ),
		.ack_in   ( ack          ),
		.din      ( txr          ),
		.cmd_ack  ( done         ),
		.ack_out  ( irxack       ),
		.dout     ( rxr          ),
		.i2c_busy ( i2c_busy     ),
		.i2c_al   ( i2c_al       ),
		.scl_i    ( scl_pad_i    ),
		.scl_o    ( scl_pad_o    ),
		.scl_oen  ( scl_padoen_o ),
		.sda_i    ( sda_pad_i    ),
		.sda_o    ( sda_pad_o    ),
		.sda_oen  ( sda_padoen_o )
	);

	// status register block + interrupt request signal
	always @(posedge clk_i or negedge arst_i)
	  	if (!arst_i) begin
	        al       <= 1'b0;
	        rxack    <= 1'b0;
	        tip      <= 1'b0;
	        irq_flag <= 1'b0;
	    end
	    else begin
	        al       <= i2c_al | (al & ~sta);
	        rxack    <= irxack;
	        tip      <= (rd | wr);
	        irq_flag <= (done | i2c_al | irq_flag) & ~iack; // interrupt request flag is always generated
	    end

	// assign status register bits
	assign sr[7]   = rxack;
	assign sr[6]   = i2c_busy;
	assign sr[5]   = al;
	assign sr[4:2] = 3'h0; // reserved
	assign sr[1]   = tip;
	assign sr[0]   = irq_flag;

endmodule
