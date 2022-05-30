/********1*********2*********3*********4*********5*********6*********7*********8
*
* Date:  21 / 10 / 2011
* Author: Joan Canals
*
* Configuration and Status Registers for SPI Bus.
*
*===============================================================================
* SPICTRL:   Serial Peripheral Interface Control Register           (Write/Read)
*            Used only in Master Mode.
*-------------------------------------------------------------------------------
*    bit[7]  : SPIE ? Serial Peripheral Interrupt Enable
*                0 = SPI interrupts disabled
*                1 = SPI interrupt enable
*    bit[6]  : SPSE ? Serial Peripheral System Enable
*                0 = SPI System off
*                1 = SPI System on
*    bit[5]  : Reserved
*    bit[4]  : Reserved
*    bit[3]  : CPOL ? Clock Polarity
*                0 = the base value of the clock is zero
*                1 = the base value of the clock is one
*    bit[2]  : CPHA ? Clock Phase
*                At CPOL=0 the base value of the clock is zero:
*                  - For CPHA=0: data are captured on the clock's rising edge (low2high
*                    transition) and data are propagated on a falling edge.
*                  - For CPHA=1: data are captured on the clock's falling edge and data
*                    are propagated on a rising edge.
*                At CPOL=1 the base value of the clock is one (inversion of CPOL=0)
*                  - For CPHA=0: data are captured on clock's falling edge and data are
*                    propagated on a rising edge.
*                  - For CPHA=1: data are captured on clock's rising edge and data are
*                    propagated on a falling edge.
*    bit[1:0]: SPR1 and SPR0 ? SPI Clock Rate Selects
*               These three serial peripheral rate bits select one of eight
*               baud rates (Table 1) to be used as SCK if the device is a master;
*               however, they have no effect in the slave mode.
*
*                  | SPR1 | SPR0 | Clock Divide By |
*                  |  0   |   0  |        4        |
*                  |  0   |   1  |        8        |
*                  |  1   |   0  |       16        |
*                  |  1   |   1  |     SPIPRE      |
*
*===============================================================================
* SPISTAT:   Serial Peripheral Interface Status Register                  (Read)
*            Used only in Master Mode.
*-------------------------------------------------------------------------------
*    bit[7]  : WCOL ? Write Collision Detect bit (Only in Master mode)
*                 0 = No collision.
*                 1 = The SSPBUF register is written while it is still transmitting
*                     the previous word.
*    bit[5:2]: Reserved bits.
*    bit[1]  : BUSY ? SPI Bus Busy Bit
*                 1 = Transmission not complete.
*                 0 = Transmission completed.
*    bit[0]  : BF   ? Buffer Full Status Bit. (Receive mode only)
*                 0 = Receive not complete.SPIBUFF is empty.
*                 1 = Receive complete. SPIBUFF is full.
*
*===============================================================================
* SPISS : Serial Peripheral Interface Slave Selector Register       (Write/Read)
*         Used only in Master Mode.
*-------------------------------------------------------------------------------
*
*===============================================================================
* SPIPRE: Serial Preipheral Interface Prescaled Value Register      (Write/Read)
*         Used only in Master Mode.
*-------------------------------------------------------------------------------
*
*===============================================================================
* SPIBUFF: Serial Peripheral Interface Transmited/Received Data Register
*         (Write/Read)
*-------------------------------------------------------------------------------
*
*********1*********2*********3*********4*********5*********6*********7*********/
// Definicio de registres
`define SPICTRL  8'h00   // WR
`define SPISTAT  8'h01   // R
`define SPIBUFF  8'h02   // WR
`define SPISS    8'h03   // WR
`define SPIPRE   8'h04   // WR

module spi_master_registers(
   Clk
  ,Rst_n
  ,Wr
  ,Rd
  ,Addr
  ,DataIn
  ,DataOut
  ,CPol
  ,CPha
  ,Spr1
  ,Spr0
  ,CPre
  ,SS
  ,Busy
  ,SpiSRRx
  ,SpiBuf
  ,WrBuf
  ,Spie
  ,Spse
  ,LoadMaster
);
parameter SIZE = 8;

// System Signals
input             Clk;              // Clock
input             Rst_n;            // Reset. Asynchronous. Active low

// Internal Data Bus
input             Wr;               // Write enable. Active high
input             Rd;               // Read enable. Active high
input  [SIZE-1:0] Addr;             // Registers Address
input  [SIZE-1:0] DataIn;           // Data input
output [SIZE-1:0] DataOut;          // Data output

// SPI Clock Config Signals
output            CPol;             // SPI Clock Polarity
output            CPha;             // SPI Clock Phase
output            Spr1,Spr0;        // SPI Clock Rate Selector
output [SIZE-1:0] CPre;             // SPI Prescaled Value

// Others
output [SIZE-1:0] SS;               // SPI Slave Selector Outputs

// Other Ctrl config signals
input             Busy;             // SPI tranceiver is busy
input  [SIZE-1:0] SpiSRRx;          // Data from SPI Shift Register
output [SIZE-1:0] SpiBuf;           // SPI Buffer Register
input             WrBuf;            // Write Enable for SpiSRRx Data
output            Spie;             // Enable Interrupt
output            Spse;             // Enable system
output            LoadMaster;       // Load data form SpiBuf to SpiSRTx

//----------------------------------------------------------------------------------
// SPICTRL Register
reg [SIZE-1:0] spiCtrl;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)
    spiCtrl <= 8'h10;
  else if(Wr & (Addr == `SPICTRL))
    spiCtrl <= DataIn;

// SPICTRL reg Decoder
assign Spie = spiCtrl[7];
assign Spse = spiCtrl[6];
assign CPol = spiCtrl[3];
assign CPha = spiCtrl[2];
assign Spr1 = spiCtrl[1];
assign Spr0 = spiCtrl[0];

// Generate Load to SpiSRTx in master mode
reg [1:0] loadMaster_aux;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)
    loadMaster_aux <= 2'b00;
  else
    loadMaster_aux <= {loadMaster_aux[0],(Wr & (Addr == `SPIBUFF))};

assign LoadMaster = loadMaster_aux[1];
//----------------------------------------------------------------------------------
// SPISTAT Register
// write collision detection bit
reg wcol;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)
    wcol <= 1'b0;
  else if(Wr & (Addr == `SPIBUFF) & Busy)
    wcol <= 1'b1;
  else if(!Busy)
    wcol <= 1'b0;

// SPI Buffer Full bit
reg bf;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)
    bf <= 1'b0;
  else if(WrBuf)
    bf <= 1'b1;
  else if((Rd | Wr) & (Addr == `SPIBUFF))
    bf <= 1'b0;

//----------------------------------------------------------------------------------
// SPIBUFF Register
reg [SIZE-1:0] SpiBuf;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)                       SpiBuf <= 8'h00;
  else if(Wr & (Addr == `SPIBUFF)) SpiBuf <= DataIn;
  else if(WrBuf)                   SpiBuf <= SpiSRRx;

//----------------------------------------------------------------------------------
// SPISS Register
reg [SIZE-1:0] SS;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)                     SS <= 8'hFF;
  else if(Wr & (Addr == `SPISS)) SS <= DataIn;

//----------------------------------------------------------------------------------
// SPIPRE Register
reg [SIZE-1:0] CPre;

always @(negedge Clk or negedge Rst_n)
  if(!Rst_n)                      CPre <= 8'h07;
  else if(Wr & (Addr == `SPIPRE)) CPre <= DataIn;

//----------------------------------------------------------------------------------
// Read Process for all Registers
reg [SIZE-1:0] DataOut;

always @(Addr or Spie or Spse or CPol or CPha or Spr1 or
         Spr0 or SpiBuf or SS or CPre or wcol or Busy or bf)
  case(Addr)
    `SPICTRL  : DataOut = {Spie,Spse,1'b1,1'b1,CPol,CPha,Spr1,Spr0};
    `SPISTAT  : DataOut = {wcol,5'b0_0000,Busy,bf};
    `SPIBUFF  : DataOut = SpiBuf;
    `SPISS    : DataOut = SS;
    `SPIPRE   : DataOut = CPre;
    default   : DataOut = 8'h00;
  endcase

endmodule
