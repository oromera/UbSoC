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

module ubsoc_debug (
	input clk_i,

	// system uart i/o
	output suart_tx_o,
	input  suart_rx_i,

	// gpio i/o
	output [7:0] gpio_led_o,
	input  [7:0] gpio_switch_i,
	input  [7:0] gpio_button_i,

	// i2c i/o master
	output  i2c_scl_mst_o,
	inout  i2c_sda_mst_io,

	// i2c i/o slave
	input  i2c_scl_slv_i,
	inout  i2c_sda_slv_io

	// spi i/o master
	//output spi_sck_mst_o,
	//output [7:0] spi_ss_mst_o,
	//output spi_mosi_mst_o,
	//input  spi_miso_mst_i,

	// spi i/o slave
	//input spi_sck_slv_i,
	//input [7:0] spi_ss_slv_i,
	//input spi_mosi_slv_i,
	//output  spi_miso_slv_i
);

	//wire i2c_sda_master, i2c_sda_slave;
	//wire i2c_scl_master, i2c_scl_slave;

	wire spi_cpol_debug, spi_cpha_debug;
	wire spi_miso, spi_mosi, spi_sck;
	wire [7:0] spi_ss;

	ubsoc soc (
		.clk_i    	      (clk_i      	  ),

		.suart_tx_o       (suart_tx_o  	  ),
		.suart_rx_i       (suart_rx_i  	  ),
 
		.gpio_led_o 	  (gpio_led_o     ),
		.gpio_switch_i    (gpio_switch_i  ),
		.gpio_button_i    (gpio_button_i  ),

		.i2c_scl_io       (i2c_scl_mst_o  ),
		.i2c_sda_io       (i2c_sda_mst_io ),

		.spi_sck  		  (spi_sck		  ),
		.spi_ss	    	  (spi_ss[0]   	  ),
		.spi_mosi 		  (spi_mosi 	  ),
	    .spi_miso 		  (spi_miso 	  ),

	    .spi_cpol_debug   (spi_cpol_debug ),
	    .spi_cpha_debug   (spi_cpha_debug )
	);

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk_i) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	spi_slave_model_2 spi_slave (
		.clock  (clk_i	   		),
		.csn 	(spi_ss[0]		),
		.sck 	(spi_sck 		),
		.di 	(spi_mosi		),
		.do 	(spi_miso		),

		.cpol_i (spi_cpol_debug ),
		.cpha_i (spi_cpha_debug )
	);

	i2cSlaveTop i2c_slave_full (
		.clk    (clk_i 			),
  		.rst    (!resetn 		),
  		.sda    (i2c_sda_slv_io	),
  		.scl    (i2c_scl_slv_i  ),
  		.myReg0 ()
	);


endmodule
