/********1*********2*********3*********4*********5*********6*********7*********8
*
* Date:  21 / 10 / 2011
* Author: Joan Canals
*
* Serial Peripheral Interface Bus TOP module
*
*********1*********2*********3*********4*********5*********6*********7*********/

module spi_master_top(
   Clk
  ,Rst_n
  ,Wr
  ,Rd
  ,Addr
  ,DataIn
  ,DataOut
  ,SCLK
  ,MOSI
  ,MISO
  ,SS
  ,Int
  ,spi_cpol_debug
  ,spi_cpha_debug
);
parameter SIZE = 8;

input             Clk;              // Clock
input             Rst_n;            // Reset. Asynchronous. Active low

// Internal Data Bus
input             Wr;               // Write enable. Active high
input             Rd;               // Read enable. Active high
input  [SIZE-1:0] Addr;             // Registers Address
input  [SIZE-1:0] DataIn;           // Data input
output [SIZE-1:0] DataOut;          // Data output

// SPI port
output            SCLK;             // SPI serial clock pad output
output            MOSI;             // Master Out Slave Out pad output
input             MISO;             // Master In  Slave In
output [SIZE-1:0] SS;               // Slave Selector

// Others
output            Int;              // SPI interrupt
output            spi_cpol_debug;   // SPI Clock Polarity debug
output            spi_cpha_debug;   // SPI Clock Phase debug


wire              cPol;             // SPI Clock Polarity
wire              cPha;             // SPI Clock Phase
wire              spr1,spr0;        // SPI Clock Rate Selector
wire   [SIZE-1:0] cPre;             // SPI Prescaled Clock Value

wire              busy;             // SPI tranceiver is busy
wire   [SIZE-1:0] spiSRRx;          // Data from SPI Shift Register Rx
wire   [SIZE-1:0] spiBuf;           // SPI Buffer Register
wire              wrBuf;            // Write Enable for SpiSR Data
wire              spie;             // Enable interrupt
wire              spse;             // Enable system
wire              loadMaster;       // Load data form SpiBuf to SpiSRTx

assign spi_cpol_debug = cPol;
assign spi_cpha_debug = cPha;

spi_master_registers SPI_REG(
   .Clk               (Clk)
  ,.Rst_n             (Rst_n)

  ,.Wr                (Wr)
  ,.Rd                (Rd)
  ,.Addr              (Addr)
  ,.DataIn            (DataIn)
  ,.DataOut           (DataOut)

  ,.CPol              (cPol)
  ,.CPha              (cPha)
  ,.Spr1              (spr1)
  ,.Spr0              (spr0)
  ,.CPre              (cPre)

  ,.SS                (SS)

  ,.Busy              (busy)
  ,.SpiSRRx           (spiSRRx)
  ,.SpiBuf            (spiBuf)
  ,.WrBuf             (wrBuf)
  ,.Spie              (spie)
  ,.Spse              (spse)
  ,.LoadMaster        (loadMaster)
);

spi_master_controller MSTR_CTRL(
   .Clk               (Clk)
  ,.Rst_n             (Rst_n)

  ,.MI                (MISO)
  ,.MO                (MOSI)
  ,.SCLK              (SCLK)

  ,.CPre              (cPre)
  ,.CPol              (cPol)
  ,.CPha              (cPha)
  ,.Spr1              (spr1)
  ,.Spr0              (spr0)

  ,.Spie              (spie)
  ,.Spse              (spse)
  ,.LoadMaster        (loadMaster)
  ,.SpiBuf            (spiBuf)
  ,.Busy              (busy)
  ,.WrBuf             (wrBuf)
  ,.Int               (Int)
  ,.SpiSRRx           (spiSRRx)
);

endmodule
