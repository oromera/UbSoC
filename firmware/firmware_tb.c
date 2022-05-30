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

#include <stdint.h>
#include <stdbool.h>
#include <time.h>

#if !defined(CLK_FREQ)
#error "Set -DCLK_FREQ=<clock frequency>"
#endif

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

// --------------------------------------------------------
// REGISTERS
// --------------------------------------------------------

///////////////////////////////////////////////////////////////////////
// PicoSoC Registers
#define reg_spictrl 		(*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv 	(*(volatile uint32_t*)0x02000004)
#define reg_uart_data 		(*(volatile uint32_t*)0x02000008)

///////////////////////////////////////////////////////////////////////
// GPIO Registers
#define reg_leds 			(*(volatile uint32_t*)0x03000000)
#define reg_buttons 		(*(volatile uint32_t*)0x03000100)

////////////////////////////////////////////////////////////////////////
// I2C Registers
#define reg_prer_lo_i2c     (*(volatile uint32_t*)0x06000000)
#define reg_prer_hi_i2c     (*(volatile uint32_t*)0x06000100)
#define reg_ctr_i2c 		(*(volatile uint32_t*)0x06000200)
#define reg_txr_i2c 		(*(volatile uint32_t*)0x06000300)
#define reg_cr_i2c 			(*(volatile uint32_t*)0x06000400)
#define reg_rx_i2c 			(*(volatile uint32_t*)0x06010000)
#define reg_st_i2c 			(*(volatile uint32_t*)0x06010100)
// Speed I2C (for 50MHz)
#define I2C_400K_PRER		0x1F
#define I2C_100K_PRER		0x7D
// Command Bits I2C 
#define START_BIT 			0b10000000
#define STOP_BIT			0b01000000
#define READ				0b00100000
#define WRITE				0b00010000
#define NACK				0b00001000
#define IRQ_ACK				0b00000001
#define MASTER_TO_SLAVE		1
#define SLAVE_TO_MASTER		0

///////////////////////////////////////////////////////////////////////
// SPI Registers
#define reg_ctrl_spi 		(*(volatile uint32_t*)0x05000000)
#define reg_ss_spi 			(*(volatile uint32_t*)0x05000300)
#define reg_pre_spi 		(*(volatile uint32_t*)0x05000400)
#define reg_tx_buff_spi     (*(volatile uint32_t*)0x05000200)
#define reg_rx_buff_spi     (*(volatile uint32_t*)0x05010000)
#define reg_stat_spi 		(*(volatile uint32_t*)0x05010100)
// BaudRate SPI (for 50MHz)
#define SPI_BR_115200		0xD8
#define SPI_BR_230400		0x6B
#define SPI_BR_460800		0x35
#define SPI_BR_921600		0x1A

// --------------------------------------------------------

// Variables declarationsa
uint8_t i2c_status;
uint8_t spi_status;
uint8_t cpol, cpha, e, n, l;
uint8_t spi_rx, spi_tx;

// Function declarations
void print_main_menu(void);
void print_led_menu(void);
void print_i2c_menu(void);
void print_spi_menu(void);
void clear_screen(void);
void press_any_key(void);
void press_enter_key(void);

// --------------------------------------------------------

void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789ABCDEF"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		putchar(c);
		digits = i;
	}
}

void print_dec(uint32_t v)
{
	if (v >= 100) {
		print(">=100");
		return;
	}

	if      (v >= 90) { putchar('9'); v -= 90; }
	else if (v >= 80) { putchar('8'); v -= 80; }
	else if (v >= 70) { putchar('7'); v -= 70; }
	else if (v >= 60) { putchar('6'); v -= 60; }
	else if (v >= 50) { putchar('5'); v -= 50; }
	else if (v >= 40) { putchar('4'); v -= 40; }
	else if (v >= 30) { putchar('3'); v -= 30; }
	else if (v >= 20) { putchar('2'); v -= 20; }
	else if (v >= 10) { putchar('1'); v -= 10; }

	if      (v >= 9) { putchar('9'); v -= 9; }
	else if (v >= 8) { putchar('8'); v -= 8; }
	else if (v >= 7) { putchar('7'); v -= 7; }
	else if (v >= 6) { putchar('6'); v -= 6; }
	else if (v >= 5) { putchar('5'); v -= 5; }
	else if (v >= 4) { putchar('4'); v -= 4; }
	else if (v >= 3) { putchar('3'); v -= 3; }
	else if (v >= 2) { putchar('2'); v -= 2; }
	else if (v >= 1) { putchar('1'); v -= 1; }
	else putchar('0');
}

char getchar_prompt(char *prompt)
{
	int32_t c = -1;

	uint32_t cycles_begin, cycles_now, cycles;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	//reg_leds = ~0;

	if (prompt)
		print(prompt);

	while (c == -1) {
		__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
		cycles = cycles_now - cycles_begin;
		if (cycles > 60000000/*12000000*/) {
			if (prompt)
				print(prompt);
			cycles_begin = cycles_now;
			//reg_leds = ~reg_leds;
			//reg_leds = (reg_leds << 1) | !((reg_leds >> 1) & 1);
		}
		c = reg_uart_data;
	}

	//reg_leds = 0;
	return c;
}

char getchar()
{
	return getchar_prompt(0);
}

// --------------------------------------------------------
// DELAY FUNCTIONS
// --------------------------------------------------------

void delay(int milliseconds)
{
	int m_count = 0;
	uint32_t cycles_begin, cycles_now, cycles = 0;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));

	if (m_count < milliseconds) {
		while (cycles < 80000000/*330*/) {
			__asm__ volatile ("rdcycle %0" : "=r"(cycles_now));
			cycles = cycles_now - cycles_begin;
		}
		m_count++;
	}
}

// --------------------------------------------------------
// LED FUNCTIONS
// --------------------------------------------------------

void led_testbench ()
{
	reg_leds = 0b00000000;

	for (int rep = 100; rep > 0; rep--)
		{
			print("Press 1 to 8 for turn on LED or press R to return...");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{
			case '1':
				reg_leds = reg_leds^0b00000001;
				continue;

			case '2':
				reg_leds = reg_leds^0b00000010;
				continue;

			case '3':
				reg_leds = reg_leds^0b00000100;
				continue;

			case '4':
				reg_leds = reg_leds^0b00001000;
				continue;

			case '5':
				reg_leds = reg_leds^0b00010000;
				continue;

			case '6':
				reg_leds = reg_leds^0b00100000;
				continue;

			case '7':
				reg_leds = reg_leds^0b01000000;
				continue;

			case '8':
				reg_leds = reg_leds^0b10000000;
				continue;

			case 'r':
				reg_leds = 0;
				break;

			default:
				continue;
			}
			clear_screen();
			break;
		}
}

void button_testbench ()
{
	print("BUTTON_0 ");
	if ((reg_buttons&0x0100)==0x0100) {print("OFF\n");}
	else {print("ON\n");}
	print("BUTTON_1 ");
	if ((reg_buttons&0x0200)==0x0200) {print("OFF\n\n");}
	else {print("ON\n\n");}

	print("SWITCH_0 ");
	if ((reg_buttons&0x001)==0x0001) {print("OFF\n");}
	else {print("ON\n");}
	print("SWITCH_0 ");
	if ((reg_buttons&0x002)==0x0002) {print("OFF\n");}
	else {print("ON\n");}
	print("SWITCH_0 ");
	if ((reg_buttons&0x004)==0x0004) {print("OFF\n");}
	else {print("ON\n");}
	print("SWITCH_0 ");
	if ((reg_buttons&0x008)==0x0008) {print("OFF\n\n");}
	else {print("ON\n\n");}
}

// --------------------------------------------------------
// I2C FUNCTIONS
// --------------------------------------------------------

void check_i2c_busy ()
{
	i2c_status = reg_st_i2c;
	while(((i2c_status & (1 << 1)) >> 1)) {i2c_status = reg_st_i2c;}
}

void send_i2c_data (uint8_t data)
{
	reg_txr_i2c = data;
	reg_cr_i2c = WRITE;
	check_i2c_busy();
}

void send_i2c_addr_dir (uint8_t address, uint8_t direction)
{
	if (direction) {reg_txr_i2c = (address << 1);}
	else {reg_txr_i2c = (address << 1) | 1;}
	reg_cr_i2c = START_BIT | WRITE; //0x90;
	check_i2c_busy();
}

void read_i2c_data ()
{
	reg_cr_i2c = READ; //0x20;
	check_i2c_busy();
}

void send_i2c_stop () 
{
	reg_cr_i2c = STOP_BIT | NACK; //0x48;
	check_i2c_busy();
}

void i2c_testbench (uint8_t mode)
{
	uint8_t i2c_check = 0;
	uint8_t i2c_rx_data;
	uint8_t mem_i2c[4] = {0xAA,0xBB,0xCC,0xDD};

	print("\n\n-------------------\n");
	print("   TEST I2C");
	print("\n-------------------\n");

	////////////////////I2C TEST//////////////////////
	// WRITE TO A SLAVE

	// configure internal registers
	reg_prer_lo_i2c = mode;
	reg_prer_hi_i2c = 0x00;
	reg_ctr_i2c = 0x80;

	// send slave address and transmission direction
	send_i2c_addr_dir(0x10,MASTER_TO_SLAVE);

	// send initial slave memory location
	send_i2c_data(0x00);

	print("\nWRITE: ");
	delay(10);

	// send data to memory location
	for(n=0; n<=3; n++) 
	{
		send_i2c_data(mem_i2c[n]);

		print_hex(mem_i2c[n],2);
		print(" ");
		delay(10);
	}

	// send stop bit and NACK
	send_i2c_stop();

	delay(10);

	// READ FROM A SLAVE
	print("\nREAD:  ");
	delay(10);

	for(n=0; n<=3; n++) {
		// send slave address and transmission direction
		send_i2c_addr_dir(0x10,MASTER_TO_SLAVE);
	
		// send initial slave memory location
		send_i2c_data(n);
	
		// send slave address and transmission direction
		send_i2c_addr_dir(0x10,SLAVE_TO_MASTER);
	
		// send first read command
		read_i2c_data();
		
		// check data received 
		i2c_rx_data = reg_rx_i2c;
		if(i2c_rx_data == mem_i2c[n]) {i2c_check++;}

		print_hex(i2c_rx_data,2);
		print(" ");

		// send stop bit and NACK
		send_i2c_stop();

		delay(10);

	}

	if (i2c_check == 4) {print("\n\nTest I2C passed!\n");}
	else {print("\n\nTest I2C not passed!\n");}
}

// --------------------------------------------------------
// SPI FUNCTIONS
// --------------------------------------------------------

void check_spi_busy ()
{
	spi_status = reg_stat_spi;
	while (((spi_status & 0b10) >> 1)) { spi_status = reg_stat_spi; spi_status = reg_stat_spi; }
}

void check_spi_buffer ()
{
	spi_status = reg_stat_spi;
	while (!(spi_status & 0b1)) { spi_status = reg_stat_spi; spi_status = reg_stat_spi; }
}

void send_spi_data (uint8_t data)
{
	reg_tx_buff_spi = data;
	check_spi_busy();
}

void spi_testbench (uint8_t SPI_BR)
{
	uint8_t mem_spi_w[8];
	uint8_t mem_spi_r[8];
	uint8_t spi_check = 0;


	print("\n\n-------------------\n");
	print("   TEST SPI");
	print("\n-------------------\n");

	reg_ss_spi = 0x00;
	for (cpol = 0; cpol <= 1; cpol++) {	
		for (cpha = 0; cpha <= 1; cpha++) {

			// load deselect slave register
			reg_ss_spi = 0x01;
		
			print("\n\nCPOL = ");
			print_dec(cpol);
			print("    CPHA = ");
			print_dec(cpha);
			print("\n");

			for (e = 0; e <= 3; e++) {

				// load control register
				reg_ctrl_spi = ( (0b1101 << 4) | ((cpol & 0b1) << 3) | ((cpha & 0b1) << 2) | (e & 0b11) );
				
				// load extended control register
				reg_pre_spi = SPI_BR;

				// load select slave register
				reg_ss_spi = 0x00;

				print("\nWRITE: ");

				// send data to spi slave			
				for(n=0; n<=7; n++)
				{
					//////////////////////////////					
					// send data
					spi_tx = ( ((cpol & 0b1) << 7) | ((cpha & 0b1) << 6) | ((e & 0b11) << 4) | (n & 0b1111) );
					
					send_spi_data(spi_tx);

					mem_spi_w[n] = spi_tx;

					print_hex(spi_tx,2);
					print(" ");
				}

				print("\nREAD:  ");

				// read data from spi slave
				for(n=0; n<=7; n++)
				{
					//////////////////////////////
	          		// send read command	
	          		send_spi_data(~n);

					spi_rx = reg_rx_buff_spi;

					mem_spi_r[n] = spi_rx;

					print_hex(spi_rx,2);
					print(" ");
				}

				// check data received
				for(n=0; n<=7; n++)
				{
					if (mem_spi_w[n] == mem_spi_r[n]) {spi_check++;}
					else {spi_check = spi_check;}
				}

			} //end e loop
		} // end cpha loop
	} // end cpol loop

	if (spi_check == 128) {print("\n\nTest SPI passed!\n");}
	else {print("\n\nTest SPI not passed!\n");}

	reg_ss_spi = 0x01;

	reg_ctrl_spi = 0b00010000;
}

// --------------------------------------------------------
// MENU FUNCTIONS
// --------------------------------------------------------

// Function definitions
void clear_screen ()
{
	print ("\e[1;1H\e[2J");
}

void press_any_key ()
{
	for (int rep = 10; rep > 0; rep--)
		{
			print("\n\nPress any key to continue...");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{
			default:
				break;
			}
			//clear_screen();
			break;
		}
}

void press_enter_key ()
{
	for (int rep = 10; rep > 0; rep--)
		{
			print("Press ENTER to continue...");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{
			case '\r':
				break;

			default:
				continue;
			}
			//clear_screen();
			break;
		}
}

void print_title ()
{
	print("             ______   _______  _______  _______\n"
			"   |\\     /|(  ___ \\ (  ____ \\(  ___  )(  ____ \\\n"
			"   | )   ( || (   ) )| (    \\/| (   ) || (    \\/\n"
			"   | |   | || (__/ / | (_____ | |   | || |\n"
			"   | |   | ||  __ (  (_____  )| |   | || |\n"
			"   | |   | || (  \\ \\       ) || |   | || |\n"
			"   | (___) || )___) )/\\____) || (___) || (____/\\\n"
			"   (_______)|/ \\___/ \\_______)(_______)(_______/\n"
			"\n"
			"A fork of PicoSoC (Clifford Wolf)\n"
			"by Omar Romera\n");
}

void pinout_map ()
{
	reg_leds=1;
	print("\n"
			"                                             +---+             +-----+\n"
			"                                       +-----|PWR|-------------| USB |-----+\n"
			"                                       |     +---+             +-----+     |\n"
			"                                       |                                   |\n"
			"              SCL_SLAVE / SCL_MASTER   | XX  +-+                        ·· |\n"
			"   SDA_SLAVE / SDA_MASTER / SWITCH_3   | XX  |X|                        ·X |   SUART_TX\n"
			"                            SWITCH_2   | ··  |X|              LED7 {X}  ·X |   LED_7 / SUART_RX\n"
			"                            SWITCH_1   | ··  |X|              LED6 {X}  ·· |   LED_6\n"
			"                            SWITCH_0   | ··  |X|              LED5 {X}  ·· |   LED_5\n"
			"                              Vcc3p3   | ·X  +-+              LED4 {X}  XX |   LED_4 / Vcc5 / GND\n"
			"                                       | ··                   LED3 {X}  ·· |   LED_3\n"
			"                                       | ··                   LED2 {X}  ·· |   LED_2\n"
			"                                       | ··                   LED1 {X}  ·· |   LED_1\n"
			"                                       | ··                   LED0 {X}  ·· |   LED_0\n"
			"                                       | ··                             ·· |\n"
			"                                       | ··    +---------------+        ·· |\n"
			"                                       | ··    |               |        ·· |\n"
			"                                       | ··    |               |   +-+  ·· |\n"
			"                                       | ··    |  Cyclone  IV  |   |X|  X· |   BUTTON_1 / Vcc3p3\n"
			"                                       | ··    |               |   +-+  ·· |\n"
			"                                       | ··    | EP4CE22F17C6N |        ·· |\n"
			"                                       | ··    |               |   +-+  ·· |\n"
			"                                       | ··    |               |   |X|  ·· |   BUTTON_0\n"
			"                                       | ··    +---------------+   +-+  ·· |\n"
			"                                       |                                   |\n"
			"                                       |     · · · · · · · · · · · · ·     |\n"
			"                                       |     · · · · · · · · · · · · ·     |\n"
			"                                       +-----------------------------------+\n\n");
}


void pinout_list ()
{
	reg_leds=2;
	print(""
			"PIN List:\n"
			"\n"
			"   I2C\n"
			"      J14    - SCL_SLAVE\n"
			"      J13    - SCL_MASTER\n"
			"      K15    - SDA_SLAVE\n"
			"      J16    - SDA_MASTER\n"
			"      Vcc3p3 - PULL UP RESISTOR 1K\n"
			"\n"
			"   SYS_UART\n"
			"      A3     - SUART_RX\n"
			"      C3     - SUART_TX\n"
			"\n"
			"   SPI\n"
			"      R8?    - CLOCK\n"
			"             - CHIP SELECT\n"
			"             - SCK\n"
			"             - MOSI\n"
			"             - MISO\n"
			"\n"
			"   LEDS\n"
			"      A15    - LED_0\n"
			"      A13    - LED_1\n"
			"      B13    - LED_2\n"
			"      A11    - LED_3\n"
			"      D1     - LED_4\n"
			"      F3     - LED_5\n"
			"      B1     - LED_6\n"
			"      L3     - LED_7\n"
			"\n"
			"   BUTTONS\n"
			"      J15    - BUTTON_0\n"
			"      E1     - BUTTON_1\n"
			"\n"
			"   SWITCHES\n"
			"      M1     - SWITCH_0\n"
			"      T8     - SWITCH_1\n"
			"      B9     - SWITCH_2\n"
			"      M15    - SWITCH_3\n"
			"\n");
}

void print_main_menu ()
{
		reg_leds=255;
		//print_title();

		//print("\n\n   [1] Pinout Map\n   [2] Pinout List\n   [3] LED testbench\n   [4] I2C testbench\n   [5] SPI testbench\n\n");
		
		print("MAIN");

		for (int rep = 10; rep > 0; rep--)
		{
			print("Select option> ");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{

			case '1':
				//clear_screen();
				pinout_map();
				//press_any_key();
				break;

			case '2':
				//clear_screen();
				pinout_list();
				//press_any_key();
				break;

			case '3':
				//clear_screen();
				print_led_menu();
				//press_any_key();
				break;

			case '4':
				//clear_screen();
				print_i2c_menu();
				//press_any_key();
				break;

			case '5':
				//clear_screen();
				print_spi_menu();
				//press_any_key();
				break;

			default:
				continue;
			}
			//clear_screen();
			break;
		}
}

void print_led_menu()
{
		reg_leds=3;
		//print_title();

		//print("\n\n   [1] Run LED testbench\n   [2] Run BUTTONS and SWITCHES testbench\n   [r] Return to main menu\n\n");

		print("LED");

		for (int rep = 10; rep > 0; rep--)
		{
			print("Select mode> ");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{

			case '1':
				//clear_screen();
				led_testbench();
				//press_any_key();
				break;

			case '2':
				//clear_screen();
				button_testbench();
				//press_any_key();
				break;

			case 'r':
				//clear_screen();
				print_main_menu();
				//press_any_key();
				break;

			default:
				continue;
			}
			//clear_screen();
			break;
		}
}

void print_i2c_menu()
{
		reg_leds=4;
		//print_title();

		//print("\n\n   [1] Run I2C testbench (Normal Mode)\n   [2] Run I2C testbench (Fast Mode)\n   [r] Return to main menu\n\n");
		
		print("I2C");

		for (int rep = 10; rep > 0; rep--)
		{
			print("Select mode> ");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{

			case '1':
				//clear_screen();
				i2c_testbench(I2C_100K_PRER);
				//press_any_key();
				break;

			case '2':
				//clear_screen();
				i2c_testbench(I2C_400K_PRER);
				//press_any_key();
				break;

			case 'r':
				//clear_screen();
				print_main_menu();
				//press_any_key();
				break;

			default:
				continue;
			}
			//clear_screen();
			break;
		}
}


void print_spi_menu ()
{
	reg_leds=5;
		//print_title();

		//print("\n\n   [1] Run SPI testbench (BR: 115200)\n   [2] Run SPI testbench (BR: 230400)\n   [3] Run SPI testbench (BR: 460800)\n   [4] Run SPI testbench (BR: 921600)\n   [r] Return to main menu\n\n");
		
		print("SPI");

		for (int rep = 10; rep > 0; rep--)
		{
			print("Select BaudRate> ");
			char cmd = getchar();
			if (cmd > 32 && cmd < 127)
				putchar(cmd);
			print("\n");

			switch (cmd)
			{

			case '1':
				//clear_screen();
				spi_testbench(SPI_BR_115200);
				//press_any_key();
				break;

			case '2':
				//clear_screen();
				spi_testbench(SPI_BR_230400);
				//press_any_key();
				break;

			case '3':
				//clear_screen();
				spi_testbench(SPI_BR_460800);
				//press_any_key();
				break;

			case '4':
				//clear_screen();
				spi_testbench(SPI_BR_921600);
				//press_any_key();
				break;

			case 'r':
				//clear_screen();
				print_main_menu();
				//press_any_key();
				break;

			default:
				continue;
			}
			//clear_screen();
			break;
		}
}

// --------------------------------------------------------
// MAIN FUNCTION
// --------------------------------------------------------

void main()
{
	reg_uart_clkdiv = CLK_FREQ / 115200L; // 434;
/*
	reg_leds = 0b00011000;
	delay(200);
	clear_screen();

	reg_leds = 255;
	print("Booting");

	reg_leds = 127;
	print(".");
	delay(1);

	reg_leds = 63;
	print(".");
	delay(1);

	reg_leds = 31;
	print(".");
	delay(1);

	reg_leds = 15;
	print(".");
	delay(1);

	reg_leds = 7;
	print(".");
	delay(1);

	reg_leds = 3;
	print(".");
	delay(1);

	reg_leds = 1;
	print(".\n");
	delay(1);

	reg_leds = 255;
*/
	press_enter_key();

	//print_title();
  
	while (1)
	{
		print_main_menu();
	}
}
