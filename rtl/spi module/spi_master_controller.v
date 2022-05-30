/********1*********2*********3*********4*********5*********6*********7*********8
*
* Date:  21 / 10 / 2011
* Author: Joan Canals
*
* SPI MASTER Controller Generates SCLK clock
*
* Generates SPI serial clock with Phase and Polarity selection
*
* At CPOL=0 the base value of the clock is zero:
*   -For CPHA=0: data are captured on the clock's rising edge (low2high transition)
*                and data are propagated on a falling edge.
*   -For CPHA=1: data are captured on the clock's falling edge
*                and data are propagated on a rising edge.
* At CPOL=1 the base value of the clock is one (inversion of CPOL=0)
*   -For CPHA=0: data are captured on clock's falling edge
*                and data are propagated on a rising edge.
*   -For CPHA=1: data are captured on clock's rising edge
*                and data are propagated on a falling edge.
*                                 __    __    __    __    __    __    __    __
* SCLK@(CPol = 0, CPha = 0) _____|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |___
*                              __    __    __    __    __    __    __    __
* SCLK@(CPol = 0, CPha = 1) __|  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |______
*                           _____    __    __    __    __    __    __    __    ___
* SCLK@(CPol = 1, CPha = 0)      |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
*                           __    __    __    __    __    __    __    __    ______
* SCLK@(CPol = 1, CPha = 1)   |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
*
* MISO/MOSI                XXX| MSB |  6  |  5  |  4  |  3  |  2  |  1  | LSB |XXX
*
*                          ______|_____|_____|_____|_____|_____|_____|_____|______
*                              internal strobe for data capture (all modes)
*
* Generates SCLK = ClkDiv = Clk / 2(clkCnt+1)
*
* Sclk_aux is like SCLK@(Pol = 0, Pha = 0). It is used by serializer and
* deserializer modules.
*
*********1*********2*********3*********4*********5*********6*********7*********/

module spi_master_controller(
   Clk
  ,Rst_n
  ,MI
  ,MO
  ,SCLK
  ,CPol
  ,CPha
  ,Spr1
  ,Spr0
  ,CPre
  ,Spie
  ,Spse
  ,LoadMaster
  ,SpiBuf
  ,Busy
  ,WrBuf
  ,Int
  ,SpiSRRx
);
parameter SIZE = 8;

input             Clk;              // Clk
input             Rst_n;            // Reset. Asynchronous. Active low

// SPI Signals
input             MI;               // Master Input
output            MO;               // Master Output
output            SCLK;             // SPI Serial Clock

input  [SIZE-1:0] CPre;             // Prescaled Factor
input             CPol;             // Clock Polarity Bit
input             CPha;             // Clock Phase Bit
input             Spr1,Spr0;        // SPI Clock Rate Selector

// Control Signals
input             Spie;             // Enable Interrupt
input             Spse;             // SPI System Enable
input             LoadMaster;       // Load data form Buffer to SpiSRTx
input  [SIZE-1:0] SpiBuf;           // SPI Buffer
output            Busy;             // SPI transmiter/receiver is busy
output            WrBuf;            // Write Enable to write Data from SR to Buffer
output            Int;              // SPI interrupt
output [SIZE-1:0] SpiSRRx;          // SPI Shift Register Rx

// registerd outputs
reg               SCLK;
reg               WrBuf;
reg               Int;
reg    [SIZE-1:0] SpiSRRx;

// other registers
reg    [SIZE-1:0] txReg;            // Tx register
reg    [SIZE-1:0] clkCnt;           // generate Clk divider
reg         [2:0] cycle_cnt;        // sclk clock cycles counter
wire              pulse;            // enable sclk transition
wire              rstCount_n;       // reset gray counter
reg               cEn;              // 1: SPI Clock Enable; 0: SPI Clock Disable
wire              startT;           // 1: starts transmission- enables clock
reg               endT;             // 1: ends transmission- disables clock

// Transmitter master output assign
assign MO = txReg[7];

// generates start signal
assign startT = Spse & LoadMaster;

// generates busy singal
assign Busy = cEn;

// generates cEn signal
always @(posedge Clk or negedge Rst_n)
  if(!Rst_n)      cEn <= 1'b0;
  else if(startT) cEn <= 1'b1;
  else if(endT)   cEn <= 1'b0;
  else            cEn <= cEn;

// divider factor
always @(posedge Clk or negedge Rst_n)
  if(!Rst_n) clkCnt <= 8'h0;
  else begin
    case ({Spr1,Spr0}) // synopsys full_case parallel_case
      2'b00: clkCnt <= 8'h01;   // 4
      2'b01: clkCnt <= 8'h03;   // 8
      2'b10: clkCnt <= 8'h07;   // 16
      2'b11: clkCnt <= CPre;    //
    endcase
  end

// generate reset!
assign rstCount_n = Rst_n & cEn;

// generate clock enable signal
gray_counter #(SIZE) GC(
   .clk_i            (Clk)
  ,.rst_n_i          (rstCount_n)
  ,.en_i             (cEn)
  ,.period_i         (clkCnt)
  ,.clock_o          (pulse)
);

// FINITE STATE MACHINE
parameter IDLE   = 2'b00
         ,PHASE1 = 2'b01
         ,PHASE2 = 2'b10;

reg [1:0] state;
reg [1:0] next;

always @(posedge Clk or negedge Rst_n)
  if(!Rst_n) state <= IDLE;
  else       state <= next;

always @(state or startT or pulse or cycle_cnt)
  case(state)
    IDLE   : if(startT) next = PHASE1;
             else      next = IDLE;

    PHASE1 : if(pulse) next = PHASE2;
             else      next = PHASE1;

    PHASE2 : if(pulse) begin
               if(cycle_cnt == 3'd7) next = IDLE;
               else                  next = PHASE1;
             end else                next = PHASE2;
    default : next = IDLE;
  endcase


always @(posedge Clk or negedge Rst_n)
  if(!Rst_n) begin
    SCLK      <= 1'b0;
    cycle_cnt <= 3'd0;
    txReg     <= 8'd0;
    SpiSRRx   <= 8'd0;
    endT      <= 1'b0;
    WrBuf     <= 1'b0;
    Int       <= 1'b0;
  end else begin
    case(state)
      IDLE   : begin
                 cycle_cnt <= 3'd0;
                 txReg     <= SpiBuf;
                 SpiSRRx   <= 8'd0;
                 endT      <= 1'b0;
                 WrBuf     <= 1'b0;
                 Int       <= 1'b0;
                 if(!startT) begin
                   SCLK      <= CPol;
                 end else begin
                   if(CPha) begin
                     SCLK     <= ~CPol;
                   end else begin
                     SCLK     <= CPol;
                   end
                 end
               end

      PHASE1 : begin
                 cycle_cnt <= cycle_cnt;
                 txReg     <= txReg;
                 endT      <= 1'b0;
                 WrBuf     <= 1'b0;
                 Int       <= 1'b0;
                 if(pulse) begin
                   SCLK     <= ~SCLK;
                   SpiSRRx  <= {SpiSRRx[6:0],MI};
                 end else begin
                   SCLK     <= SCLK;
                   SpiSRRx  <= SpiSRRx;
                 end
               end

      PHASE2 : begin
                 SpiSRRx <= SpiSRRx;
                 if(pulse) begin
                   txReg     <= {txReg[6:0],1'b0};
                   cycle_cnt <= cycle_cnt + 1'b1;
                   if(cycle_cnt == 3'd7) begin
                     SCLK    <= CPol;
                     endT    <= 1'b1;
                     WrBuf     <= 1'b1;
                     Int       <= 1'b1 & Spie;
                   end else begin
                     SCLK    <= ~SCLK;
                     endT    <= 1'b0;
                     WrBuf   <= 1'b0;
                     Int     <= 1'b0;
                   end
                 end else begin
                   cycle_cnt <= cycle_cnt;
                   SCLK      <= SCLK;
                   endT      <= 1'b0;
                   WrBuf     <= 1'b0;
                   Int       <= 1'b0;
                 end
                end // case: PHASE2

      default : begin
                  SCLK      <= 1'b0;
                  cycle_cnt <= 3'd0;
                  txReg     <= 8'd0;
                  SpiSRRx   <= 8'd0;
                  endT      <= 1'b0;
                  WrBuf     <= 1'b0;
                  Int       <= 1'b0;
                end
    endcase
  end

endmodule
