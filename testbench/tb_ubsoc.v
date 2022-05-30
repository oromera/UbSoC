//
// UbSoC - PicoSoC (Claire Wolf) implementation for Altera devices
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


`timescale 1 ns / 1 ns

module tb_picosoc;
	reg clk;

	wire [7:0] test_led;
	reg  [7:0] test_button = 0;
	reg  [7:0] test_switch = 0;

	wire ser_tx;
	reg  ser_rx = 1'b1;

	localparam ser_half_period = 217;
	event ser_sample;

	reg [7:0] buffer = {(8){1'bz}};
	reg [7:0] rx_buffer = {(8){1'bz}};

	tri1 test_scl, test_sda;
	reg i2c_slave_rst;

	wire test_spi_miso;
	wire [7:0] test_spi_ss;
	wire test_spi_mosi;
	wire test_spi_sck;
	wire test_spi_cpol;
	wire test_spi_cpha;

	// clock parameters
	parameter HALF_CLOCK_PERIOD_50M 	= 10;
	parameter HALF_CLOCK_PERIOD_32M		= 15625;
	parameter HALF_CLOCK_PERIOD_10M 	= 50000;
	parameter HALF_CLOCK_PERIOD_1M 		= 500000;
	parameter HALF_CLOCK_PERIOD_100K 	= 5000000;
	parameter HALF_CLOCK_PERIOD_4608 	= 108506944;

	// clock generation
	always begin
		clk = 1;
    	#HALF_CLOCK_PERIOD_50M;
    	clk = 0;
    	#HALF_CLOCK_PERIOD_50M;
	end

	task PRESS_KEY;
		input [7:0]	KEY;	
		begin
			buffer = 0;
			ser_rx = 1'b0;
			rx_buffer = KEY;

			repeat (ser_half_period) @(posedge clk);
			-> ser_sample; // start bit

			repeat (8) begin
				repeat (ser_half_period) @(posedge clk);
				repeat (ser_half_period) @(posedge clk);
				ser_rx = rx_buffer[0];
				buffer = {ser_rx, buffer[7:1]};
				rx_buffer = {1'b0, rx_buffer[6:1]};
				-> ser_sample; // data bit
			end

			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			-> ser_sample; // stop bit
			
			ser_rx = 1'b1;
		end
	endtask

	task PRESS_ENTER;
		parameter KEY_ENTER = 8'h0D; // 8'b 0000_1101
		
		begin
			PRESS_KEY(KEY_ENTER);

			if (buffer == KEY_ENTER)
				$display("ENTER PRESSED");
			else
				$display("INCORRECT KEY");			
		end
	endtask	

	initial begin
		#10;
		i2c_slave_rst = 1;
		#100;
		i2c_slave_rst = 0;
		repeat(50)  #100000;		
		PRESS_ENTER;
		repeat(30)  #100000; //265 regular 30 nodebug
		PRESS_KEY(8'h34); //PRESS "2"		
		repeat(150) #100000; //290 regular 60 nodebug

		#10;
		i2c_slave_rst = 1;
		#100;
		i2c_slave_rst = 0;

		PRESS_KEY(8'h31); //PRESS "3"
		repeat(150) #100000; //290 regular 60 nodebug

		#10;
		i2c_slave_rst = 1;
		#100;
		i2c_slave_rst = 0;

		PRESS_KEY(8'h34); //PRESS "4"
		//$finish;
	end

	ubsoc_debug uut (
		.clk_i    	  (clk      	 ),

		.suart_tx_o       (ser_tx   	 ),
		.suart_rx_i       (ser_rx   	 ),
 
		.gpio_led_o 	  (test_led      ),
		.gpio_switch_i    (test_switch   ),
		.gpio_button_i    (test_button   ),

		.i2c_scl_mst_o    (test_scl      ),
		.i2c_sda_mst_io   (test_sda      ),

		.i2c_scl_slv_i    (test_scl      ),
		.i2c_sda_slv_io   (test_sda      )
/*
		.spi_sck  	  (test_spi_sck  ),
		.spi_ss	    	  (test_spi_ss   ),
		.spi_mosi 	  (test_spi_mosi ),
	    	.spi_miso 	  (test_spi_miso )*/

	);

/*
	i2c_slave_model #(7'b001_0000) i2c_slave (
		.scl 	(test_scl 	),
		.sda 	(test_sda 	)
	);*/
/*
	spi_slave_model_2 spi_slave (
		.clock  (clk	        ),
		.csn 	(test_spi_ss[0] ),
		.sck 	(test_spi_sck   ),
		.di 	(test_spi_mosi  ),
		.do 	(test_spi_miso  ),

		.cpol_i (test_spi_cpol  ),
		.cpha_i (test_spi_cpha  )
	);*/

	/*i2cSlaveTop i2c_slave_full (
		.clk(clk),
  		.rst(i2c_slave_rst),
  		.sda(test_sda),
  		.scl(test_scl),
  		.myReg0()
	);*/


	//assign test_spi_cpol = uut.spi_top.MSTR_CTRL.CPol;
	//assign test_spi_cpha = uut.spi_top.MSTR_CTRL.CPha;

	always begin
		@(negedge ser_tx);

		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge clk);
			repeat (ser_half_period) @(posedge clk);
			buffer = {ser_tx, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge clk);
		repeat (ser_half_period) @(posedge clk);
		-> ser_sample; // stop bit

		if (buffer < 32 || buffer >= 127) begin
			if (buffer == 13) $display("");
			else if (buffer == 10) ;
			else $write("%d", buffer);
		end
		else
			$write("%c", buffer);
	end

endmodule

