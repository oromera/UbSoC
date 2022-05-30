// I2C module testbench

/////////////////////////////////////////////////////////////////////
// synopsys translate_off
`timescale 1ns / 10ps

// synopsys translate_on

module tb_i2c ();

	// System signals
	reg clk;
	reg resetn;
	reg i2c_slave_rst;
	reg [7:0] mem [0:3];

	// Parameters
	parameter HALF_CLOCK_PERIOD_50M 	= 10;
	parameter HALF_CLOCK_PERIOD_10M 	= 50;
	parameter HALF_CLOCK_PERIOD_1M 		= 500;
	parameter HALF_CLOCK_PERIOD_100K 	= 5000;
	parameter PERIOD = 100;
	parameter SADR = 7'b001_0000;

	// Tristate pullup lines
	tri1 scl, sda;

	wire scl_padoen_oe, sda_padoen_oe;
	wire scl_pad_o, sda_pad_o;
	wire scl_pad_i, sda_pad_i;

	assign scl = scl_padoen_oe ? 1'bz : scl_pad_o;
	assign sda = sda_padoen_oe ? 1'bz : sda_pad_o;
	assign scl_pad_i = scl;
	assign sda_pad_i = sda;

	// Master signals
	wire [7:0] rx_byte;
	wire [7:0] status;
	reg [7:0] data_input = 0;
	reg [4:0] enable = 0;

	parameter EN_PRER_LO = 5'b0_0001;
	parameter EN_PRER_HI = 5'b0_0010;
	parameter EN_CTR 	 = 5'b0_0100;
	parameter EN_TXR 	 = 5'b0_1000;
	parameter EN_CR 	 = 5'b1_0000;

	integer i;

	// hookup i2c master model
	i2c_master_top i2c_master (
		.clk_i(clk),
		.arst_i(resetn),
	
		// input, output and enable registers
		.reg_i(data_input),     			// general register input
		.en_prer_lo_i(enable[0]),    	// clock prescale register low byte enable
		.en_prer_hi_i(enable[1]),    	// clock prescale register high byte enable
		.en_ctr_i(enable[2]),       		// control register enable
		.en_txr_i(enable[3]),        	// transmit register enable
		.en_cr_i(enable[4]),         	// command register enable
	
		.rxr_o(rx_byte),     				 // receive register
		.sr_o(status),      				 // status register
	
		// I2C signals
		// i2c clock line
		.scl_pad_i(scl_pad_i),       			 // SCL-line input
		.scl_pad_o(scl_pad_o),           // SCL-line output (always 1'b0)
		.scl_padoen_o(scl_padoen_oe),    // SCL-line output enable (active low)
	
		// i2c data line
		.sda_pad_i(sda_pad_i),       	         // SDA-line input
		.sda_pad_o(sda_pad_o),           // SDA-line output (always 1'b0)
		.sda_padoen_o(sda_padoen_oe)      // SDA-line output enable (active low)
	);

	// hookup i2c slave model
	i2cSlaveTop i2c_slave_full (
		.clk(clk),
  		.rst(i2c_slave_rst),
  		.sda(sda),
  		.scl(scl)
	);

	// Testbench signals
	wire irq_flag;
	wire TiP;
	wire al;
	wire i2c_busy;
	wire RxACK;

	assign irq_flag = status[0];
	assign TiP 		= status[1];
	assign al 		= status[5];
	assign i2c_busy = status[6];
	assign RxACK 	= status[7];

	// control parameters
	parameter CORE_ENABLE 	   = 8'b1000_0000;
	parameter CORE_DISABLE	   = 8'b0000_0000;
	parameter CORE_IRQ_ENABLE  = 8'b0100_0000;
	parameter CORE_IRQ_DISABLE = 8'b0000_0000;

	// transmit parameters
	parameter READ_TO_SLAVE	   = 1'b1;
	parameter WRITE_TO_SLAVE   = 1'b0;

	// command parameters
	parameter START_BIT = 8'b1000_0000;
	parameter STOP_BIT	= 8'b0100_0000;
	parameter READ		= 8'b0010_0000;
	parameter WRITE		= 8'b0001_0000;
	parameter NACK		= 8'b0000_1000;
	parameter IRQ_ACK	= 8'b0000_0001;

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
		end
	endtask

	task send_stop;
		begin
			WaitClock;
			write_reg(EN_CR, STOP_BIT | NACK);  //SET STO bit, SET RD bit AND SET NACK}
			WaitClock;
		end
	endtask

	task write_reg; 
		input [4:0] sel_enable;
		input [7:0] data_w_r;
		begin
			@(posedge clk);
			enable = sel_enable;
			data_input = data_w_r;
			@(posedge clk);
			enable = 5'b0_0000;
		end
		
	endtask

	task read_slave;
		input [4:0] sel_enable;
		input [7:0] data_w_r;
		begin
			write_reg(sel_enable, data_w_r);
			//send_stop;
		end
	endtask

	task send_byte;
		input [7:0] byte_to_send;
		begin
			WaitClock;
			//$display("Status: irq_flag: %b, TiP: %b, al: %b, i2c_busy: %b, RxACK: %b", irq_flag, TiP, al, i2c_busy, RxACK);
			if (!RxACK) begin
		    	WaitClock;
		   		write_reg(EN_TXR, byte_to_send);	// DATA TO TRASNMIT REGISTER
		   		WaitClock;
		   		write_reg(EN_CR, WRITE);		// SET WR command
		   		WaitClock;
			end else begin
		    	//$display("NO ACK RECEIVED at %t ps", $stime*10);
		    	$stop;
			end
			//$display("Transmission in Progress");
			while(TiP) #1;
			//$display("Transmission successful at %t ps", $stime*10);
		end
	endtask

	task send_adr_dir;
		input [6:0] adr_to_send;
		input dir;
		begin
			WaitClock;
			write_reg(EN_TXR, {adr_to_send,dir});  		// ADDRESS + DIRECTION BIT TO TRASNMIT REGISTER
			WaitClock;
			write_reg(EN_CR, START_BIT | WRITE);		// SET STA bit, SET WR bit			
			WaitClock;
			//$display("Status: irq_flag: %b, TiP: %b, al: %b, i2c_busy: %b, RxACK: %b", irq_flag, TiP, al, i2c_busy, RxACK);
			//$display("Transmission in Progress");
			while(TiP) #1;
			//$display("Transmission successful at %t ps", $stime*10);
		end
	endtask

initial begin
	
	clk   = 0;
	resetn = 1;

	mem[0] = 0;
	mem[1] = 0;
	mem[2] = 0;
	mem[3] = 0;

	#10;
	i2c_slave_rst = 1;
	#100;
	i2c_slave_rst = 0;

	#5;
	resetn = 1'b0; // assert reset
	repeat(1) @(posedge clk);
	resetn = 1'b1; // negate reset

	$display("");

	//
	//--------------------------------------------
	// I2C write and read
	//--------------------------------------------
	//

	// WRITE TO A SLAVE
	//
	// configure internal registers
	write_reg(EN_PRER_LO, 8'h13);	 			// PRESCALE LOW
	WaitClock;
	write_reg(EN_PRER_HI, 8'h00);	 			// PRESCALE HIGH
	WaitClock;
	write_reg(EN_CTR, CORE_ENABLE);		 		// ENABLE I2C CORE
	WaitClock;

	$display("---------------------------------------------------");
	$display("WRITE TO A SLAVE");
	$display("---------------------------------------------------");

	// send slave address and transmission direction
	send_adr_dir(SADR,WRITE_TO_SLAVE);

	// send initial slave memory location
	send_byte(8'h00);
	
	// send data to initial memory location
	send_byte(8'hAA);

	// send data to next memory location
	send_byte(8'hBB);

	// send data to next memory location
	send_byte(8'hCC);

	// send data to next memory location
	send_byte(8'hDD);

	// send stop bit and NACK
	send_stop;
   	//$display("STOP", $time*10, "ps");

   	if (i2c_slave_full.u_i2cSlave.myReg0 == 8'hAA) $display("PASS first  transmission");
   	else $display("FAIL first  transmission");
	if (i2c_slave_full.u_i2cSlave.myReg1 == 8'hBB) $display("PASS second transmission");
   	else $display("FAIL second transmission");
   	if (i2c_slave_full.u_i2cSlave.myReg2 == 8'hCC) $display("PASS third  transmission");
   	else $display("FAIL third  transmission");
   	if (i2c_slave_full.u_i2cSlave.myReg3 == 8'hDD) $display("PASS fourth transmission");
   	else $display("FAIL fourth transmission");

   	$display("---------------------------------------------------");	
	$display("READ FROM A SLAVE");
	$display("---------------------------------------------------");
	#50000;
	
	mem[0] = i2c_slave_full.u_i2cSlave.myReg0;
	mem[1] = i2c_slave_full.u_i2cSlave.myReg1;
	mem[2] = i2c_slave_full.u_i2cSlave.myReg2;
	mem[3] = i2c_slave_full.u_i2cSlave.myReg3;

	// READ FROM A SLAVE
	//
	for(i=0;i<=3;i=i+1) begin
		// send slave address and transmission direction
		send_adr_dir(SADR,WRITE_TO_SLAVE);

		// send initial slave memory location
		send_byte(i);

		// send slave address and transmission direction
		send_adr_dir(SADR,READ_TO_SLAVE);

		// send read command
		read_slave(EN_CR, READ);

		// send stop bit and NACK
		send_stop;

		while (i2c_busy) #1;
		if (rx_byte == mem[i]) $display("PASS: Expected: %H, Received: %H", mem[i], rx_byte);
		else $display("FAIL: Expected: %H, Received: %H", mem[i], rx_byte);
		#5000;
	end

	$display("");

	#5000;
	$stop;

end // end initial begin

endmodule