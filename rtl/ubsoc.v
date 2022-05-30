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

module ubsoc (
	input clk_i,

	// system uart i/o
	output suart_tx_o,
	input suart_rx_i,

	// gpio i/o
	output [7:0] gpio_led_o,
	input [7:0] gpio_switch_i,
	input [7:0] gpio_button_i,

	// i2c i/o
	inout i2c_scl_io,
	inout i2c_sda_io,

	// spi i/o
	output spi_sck,
	output [7:0] spi_ss,
	output spi_mosi,
	input  spi_miso,

	// spi debug
	output spi_cpol_debug,
	output spi_cpha_debug
);

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk_i) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	wire [31:0] iomem_rdata;

	///////////////////////////////////
	// GPIO variables
	///////////////////////////////////
	
	reg [7:0] leds;
	assign gpio_led_o = leds;

	///////////////////////////////////
	// I2C variables
	///////////////////////////////////

	// Register enables parameters
	parameter I2C_PRER_LO = 5'b0_0001;
	parameter I2C_PRER_HI = 5'b0_0010;
	parameter I2C_CTR 	  = 5'b0_0100;
	parameter I2C_TXR 	  = 5'b0_1000;
	parameter I2C_CR 	  = 5'b1_0000;

	// Tristate pullup lines
	wire scl_padoen_o, sda_padoen_o;
	wire scl_pad_o, sda_pad_o;
	wire scl_pad_i, sda_pad_i;

	assign i2c_scl_io = scl_padoen_o ? 1'b1 : scl_pad_o; // I2C module only in master mode
	assign scl_pad_i  = i2c_scl_io;

	assign i2c_sda_io = sda_padoen_o ? 1'bz : sda_pad_o;
	assign sda_pad_i  = i2c_sda_io;

	// Variables
	wire [7:0] i2c_rx_byte;
	wire [7:0] i2c_status;
	reg  [7:0] i2c_data_i;
	reg  [4:0] i2c_reg_enable;

	wire [7:0] i2c_data_rx;
	//reg  [7:0] i2c_data_rx_reg = 0;
	wire [7:0] i2c_data_rx_rst;
	wire [7:0] i2c_data_st;

	assign i2c_data_rx_rst = !resetn ? 8'h00 : i2c_data_rx;
	assign i2c_data_rx  = !i2c_data_st[1] ? i2c_rx_byte : i2c_data_rx_rst;
	assign i2c_data_st  = i2c_status;

	///////////////////////////////////
	// SPI variables
	///////////////////////////////////

	// Register address parameters
	parameter SPI_CTRL = 8'h00;   // W
	parameter SPI_STAT = 8'h01;   // R
	parameter SPI_BUFF = 8'h02;   // WR
	parameter SPI_SS   = 8'h03;   // W
	parameter SPI_PRE  = 8'h04;   // W

	// Variables
	reg spi_wr = 0;
	reg spi_rd = 0;
	reg [7:0] spi_addr = 0;
	reg [7:0] spi_data_i = 0;
	wire [7:0] spi_data_o;
	//reg [7:0] spi_data_o_delay = 0;

	///////////////////////////////////
	// BODY MODULE
	///////////////////////////////////

	always @(posedge clk_i) begin
		if (!resetn) begin
			leds <= 0;
			i2c_reg_enable <= 0;
			i2c_data_i <= 0;
			spi_wr <= 0;
			spi_rd <= 0;
		end else begin
			iomem_ready <= 0;
			spi_wr <= 0;
			spi_rd <= 0;

			// GPIO BUS PERIPHERAL
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
				iomem_ready <= 1;
				
				if (iomem_wstrb[0]) leds[7:0] <= iomem_wdata[ 7: 0];

			end // end gpio bus

			// SPI BUS PERIPHERAL
			else if ((iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 05)) begin
				iomem_ready <= 1;
				if (iomem_addr[23:16] == 8'h00) begin
					spi_wr <= 1;

					if 		(iomem_addr[15:8] == 8'h00) spi_addr <= SPI_CTRL;
					else if (iomem_addr[15:8] == 8'h03) spi_addr <= SPI_SS;
					else if (iomem_addr[15:8] == 8'h04) spi_addr <= SPI_PRE;
					else if (iomem_addr[15:8] == 8'h02) spi_addr <= SPI_BUFF;

					if (iomem_wstrb[0]) spi_data_i[ 7: 0] <= iomem_wdata[ 7: 0];

				end else if (iomem_addr[23:16] == 8'h01) begin
					spi_rd <= 1;
					if 		(iomem_addr[15:8] == 8'h00) spi_addr <= SPI_BUFF;
					else if (iomem_addr[15:8] == 8'h01) spi_addr <= SPI_STAT;
				end
			end

			// I2C BUS PERIPHERAL
			else if ((iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h06)) begin
				iomem_ready <= 1;
				if (iomem_addr[23:16] == 8'h00) begin

					if 		(iomem_addr[15: 8] == 8'h00) i2c_reg_enable <= I2C_PRER_LO;
					else if (iomem_addr[15: 8] == 8'h01) i2c_reg_enable <= I2C_PRER_HI;
					else if (iomem_addr[15: 8] == 8'h02) i2c_reg_enable <= I2C_CTR;
					else if (iomem_addr[15: 8] == 8'h03) i2c_reg_enable <= I2C_TXR;
					else if (iomem_addr[15: 8] == 8'h04) i2c_reg_enable <= I2C_CR;

					if (iomem_wstrb[0]) i2c_data_i [ 7: 0] <= iomem_wdata[ 7: 0];

				end
			end 

			else begin
				i2c_reg_enable <= 0;
			end

		end // end bus
	end // end always

	assign iomem_rdata = 				
				iomem_addr == 32'h03000100 ? {gpio_button_i, gpio_switch_i} : 
				iomem_addr == 32'h06010000 ? i2c_data_rx : 
				iomem_addr == 32'h06010100 ? i2c_data_st : 
				iomem_addr[31:16] == 16'h0501 ? spi_data_o : 32'h00000000;


	///////////////////////////////////
	// INSTANCES
	///////////////////////////////////

	picosoc_noflash soc (
		.clk          (clk_i	   ),
		.resetn       (resetn      ),

		.ser_tx       (suart_tx_o  ),
		.ser_rx       (suart_rx_i  ),

		.irq_5        (1'b0        ),
		.irq_6        (1'b0        ),
		.irq_7        (1'b0        ),

		.iomem_valid  (iomem_valid ),
		.iomem_ready  (iomem_ready ),
		.iomem_wstrb  (iomem_wstrb ),
		.iomem_addr   (iomem_addr  ),
		.iomem_wdata  (iomem_wdata ),
		.iomem_rdata  (iomem_rdata )
	);

	spi_master_top spi_top (
		.Clk 	 (clk_i		 ),
		.Rst_n 	 (resetn 	 ),

		.Wr 	 (spi_wr 	 ),
		.Rd 	 (spi_rd 	 ),

		.Addr 	 (spi_addr 	 ),
		.DataIn  (spi_data_i ),
		.DataOut (spi_data_o ),

		.SCLK 	 (spi_sck 	 ),
		.MOSI	 (spi_mosi 	 ),
		.MISO	 (spi_miso 	 ),
		.SS 	 (spi_ss 	 ),

		.Int 	 ( 			 ),
		.spi_cpol_debug (spi_cpol_debug),
		.spi_cpha_debug (spi_cpha_debug)
	);

	i2c_master_top i2c_module (
		.clk_i			(clk_i     		   ),
		.arst_i			(resetn    		   ),
	
		// input, output and enable registers
		.reg_i			(i2c_data_i		   ),    // general register input 8bits
		.en_prer_lo_i	(i2c_reg_enable[0] ),    // clock prescale register low byte enable
		.en_prer_hi_i	(i2c_reg_enable[1] ),    // clock prescale register high byte enable
		.en_ctr_i		(i2c_reg_enable[2] ),    // control register enable
		.en_txr_i		(i2c_reg_enable[3] ),    // transmit register enable
		.en_cr_i 		(i2c_reg_enable[4] ),    // command register enable

		.rxr_o 			(i2c_rx_byte	   ),    // receive register 8bits
		.sr_o 			(i2c_status		   ),    // status register 8bits
	
		// I2C signals
		// i2c clock line
		.scl_pad_i 		(scl_pad_i		   ),    // SCL-line input
		.scl_pad_o 		(scl_pad_o 		   ),    // SCL-line output (always 1'b0)
		.scl_padoen_o 	(scl_padoen_o	   ),    // SCL-line output enable (active low)

		// i2c data line
		.sda_pad_i 		(sda_pad_i 		   ),    // SDA-line input
		.sda_pad_o 		(sda_pad_o 		   ),    // SDA-line output (always 1'b0)
		.sda_padoen_o 	(sda_padoen_o 	   )     // SDA-line output enable (active low)
	);


endmodule
