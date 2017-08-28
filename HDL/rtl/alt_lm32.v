//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 22nd May 2017
//
// This code is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The code is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this code. If not, see <http://www.gnu.org/licenses/>.
//
// $Id: alt_lm32.v,v 1.7 2017/08/23 09:17:11 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/alt_lm32.v,v $
//
//=============================================================
// altera message_level Level1 

`include "lm32_include.v"

// Top level for terasIC/Altera DE1 platform based lm32 system
module alt_lm32 (
                // Clock Input
                CLOCK_24,              // 24 MHz
                CLOCK_27,              // 27 MHz
                CLOCK_50,              // 50 MHz
                EXT_CLOCK,             // External Clock

                // Push Button
                KEY,                   // Pushbutton[3:0]

                // DPDT Switch
                SW,                    // Toggle Switch[9:0]

                // 7-SEG Display
                HEX0,                  // Seven Segment Digit 0
                HEX1,                  // Seven Segment Digit 1
                HEX2,                  // Seven Segment Digit 2
                HEX3,                  // Seven Segment Digit 3

                // LED
                LEDG,                  // LED Green[7:0]
                LEDR,                  // LED Red[9:0]

                // UART
                UART_TXD,              // UART Transmitter
                UART_RXD,              // UART Receiver

                // SDRAM Interface
                DRAM_DQ,               // SDRAM Data bus 16 Bits
                DRAM_ADDR,             // SDRAM Address bus 12 Bits
                DRAM_LDQM,             // SDRAM Low-byte Data Mask 
                DRAM_UDQM,             // SDRAM High-byte Data Mask
                DRAM_WE_N,             // SDRAM Write Enable
                DRAM_CAS_N,            // SDRAM Column Address Strobe
                DRAM_RAS_N,            // SDRAM Row Address Strobe
                DRAM_CS_N,             // SDRAM Chip Select
                DRAM_BA_0,             // SDRAM Bank Address 0
                DRAM_BA_1,             // SDRAM Bank Address 1
                DRAM_CLK,              // SDRAM Clock
                DRAM_CKE,              // SDRAM Clock Enable

                // Flash Interface
                FL_DQ,                 // FLASH Data bus 8 Bits
                FL_ADDR,               // FLASH Address bus 22 Bits
                FL_WE_N,               // FLASH Write Enable
                FL_RST_N,              // FLASH Reset
                FL_OE_N,               // FLASH Output Enable
                FL_CE_N,               // FLASH Chip Enable

                // SRAM Interface
                SRAM_DQ,               // SRAM Data bus 16 Bits
                SRAM_ADDR,             // SRAM Address bus 18 Bits
                SRAM_UB_N,             // SRAM High-byte Data Mask 
                SRAM_LB_N,             // SRAM Low-byte Data Mask 
                SRAM_WE_N,             // SRAM Write Enable
                SRAM_CE_N,             // SRAM Chip Enable
                SRAM_OE_N,             // SRAM Output Enable

                // SD_Card Interface 
                SD_DAT,                // SD Card Data
                SD_DAT3,               // SD Card Data 3
                SD_CMD,                // SD Card Command Signal
                SD_CLK,                // SD Card Clock

                // USB JTAG link
                TDI,                   // CPLD -> FPGA (data in)
                TCK,                   // CPLD -> FPGA (clk)
                TCS,                   // CPLD -> FPGA (CS)
                TDO,                   // FPGA -> CPLD (data out)

                // I2C
                I2C_SDAT,              // I2C Data
                I2C_SCLK,              // I2C Clock

                // PS2
                PS2_DAT,               // PS2 Data
                PS2_CLK,               // PS2 Clock

                // VGA
                VGA_HS,                // VGA H_SYNC
                VGA_VS,                // VGA V_SYNC
                VGA_R,                 // VGA Red[3:0]
                VGA_G,                 // VGA Green[3:0]
                VGA_B,                 // VGA Blue[3:0]

                // Audio CODEC
                AUD_ADCLRCK,           // Audio CODEC ADC LR Clock
                AUD_ADCDAT,            // Audio CODEC ADC Data
                AUD_DACLRCK,           // Audio CODEC DAC LR Clock
                AUD_DACDAT,            // Audio CODEC DAC Data
                AUD_BCLK,              // Audio CODEC Bit-Stream Clock
                AUD_XCK,               // Audio CODEC Chip Clock

                // GPIO
                GPIO_0,                // GPIO Connection 0
                GPIO_1                 // GPIO Connection 1
        );

parameter sys_clk_period_ps = 20000;

parameter sys_clk_freq_khz  = 1000000/(sys_clk_period_ps/1000);   

// Clock Input
input   [1:0] CLOCK_24;      // 24 MHz
input   [1:0] CLOCK_27;      // 27 MHz
input         CLOCK_50;      // 50 MHz
input         EXT_CLOCK;     // External Clock

// Push Button
input   [3:0] KEY;           // Pushbutton[3:0]

// DPDT Switch
input   [9:0] SW;            // Toggle Switch[9:0]

// 7-SEG Display
output  [6:0] HEX0;          // Seven Segment Digit 0
output  [6:0] HEX1;          // Seven Segment Digit 1
output  [6:0] HEX2;          // Seven Segment Digit 2
output  [6:0] HEX3;          // Seven Segment Digit 3

// LED
output  [7:0] LEDG;          // LED Green[7:0]
output  [9:0] LEDR;          // LED Red[9:0]

// UART
output        UART_TXD;      // UART Transmitter
input         UART_RXD;      // UART Receiver

// SDRAM Interface
inout  [15:0] DRAM_DQ;       // SDRAM Data bus 16 Bits
output [11:0] DRAM_ADDR;     // SDRAM Address bus 12 Bits
output        DRAM_LDQM;     // SDRAM Low-byte Data Mask 
output        DRAM_UDQM;     // SDRAM High-byte Data Mask
output        DRAM_WE_N;     // SDRAM Write Enable
output        DRAM_CAS_N;    // SDRAM Column Address Strobe
output        DRAM_RAS_N;    // SDRAM Row Address Strobe
output        DRAM_CS_N;     // SDRAM Chip Select
output        DRAM_BA_0;     // SDRAM Bank Address 0
output        DRAM_BA_1;     // SDRAM Bank Address 0
output        DRAM_CLK;      // SDRAM Clock
output        DRAM_CKE;      // SDRAM Clock Enable

// Flash Interface
inout   [7:0] FL_DQ;         // FLASH Data bus 8 Bits
output [21:0] FL_ADDR;       // FLASH Address bus 22 Bits
output        FL_WE_N;       // FLASH Write Enable
output        FL_RST_N;      // FLASH Reset
output        FL_OE_N;       // FLASH Output Enable
output        FL_CE_N;       // FLASH Chip Enable

// SRAM Interface
inout  [15:0] SRAM_DQ;       // SRAM Data bus 16 Bits
output [17:0] SRAM_ADDR;     // SRAM Address bus 18 Bits
output        SRAM_UB_N;     // SRAM High-byte Data Mask 
output        SRAM_LB_N;     // SRAM Low-byte Data Mask 
output        SRAM_WE_N;     // SRAM Write Enable
output        SRAM_CE_N;     // SRAM Chip Enable
output        SRAM_OE_N;     // SRAM Output Enable

// SD Card Interface
inout         SD_DAT;        // SD Card Data
inout         SD_DAT3;       // SD Card Data 3
inout         SD_CMD;        // SD Card Command Signal
output        SD_CLK;        // SD Card Clock

// I2C
inout         I2C_SDAT;      // I2C Data
output        I2C_SCLK;      // I2C Clock

// PS2
input         PS2_DAT;       // PS2 Data
input         PS2_CLK;       // PS2 Clock

// USB JTAG link
input         TDI;           // CPLD -> FPGA (data in)
input         TCK;           // CPLD -> FPGA (clk)
input         TCS;           // CPLD -> FPGA (CS)
output        TDO;           // FPGA -> CPLD (data out)

// VGA
output        VGA_HS;        // VGA H_SYNC
output        VGA_VS;        // VGA V_SYNC
output  [3:0] VGA_R;         // VGA Red[3:0]
output  [3:0] VGA_G;         // VGA Green[3:0]
output  [3:0] VGA_B;         // VGA Blue[3:0]

// Audio CODEC 
output        AUD_ADCLRCK;   // Audio CODEC ADC LR Clock
input         AUD_ADCDAT;    // Audio CODEC ADC Data
output        AUD_DACLRCK;   // Audio CODEC DAC LR Clock
output        AUD_DACDAT;    // Audio CODEC DAC Data
inout         AUD_BCLK;      // Audio CODEC Bit-Stream Clock
output        AUD_XCK;       // Audio CODEC Chip Clock

// GPIO
inout  [35:0] GPIO_0;        // GPIO Connection 0
inout  [35:0] GPIO_1;        // GPIO Connection 1

// sram_clk synchronous to sys_clk, but 180 deg phase shift.
//             ___     ___     ___
// sys_clk   _/   \___/   \___/  
//           _   _   _   _   _   _
// sram_clk   \_/ \_/ \_/ \_/ \_/
//
wire          sys_clk;
wire          sdram_clk;
wire          sram_clk;
wire          mTCK;
wire          nreset;

// SRAM interconnect from controller
wire   [17:0] mSR_ADDR;
wire   [15:0] mRS2SR_DATA;
wire          mSR_OE;
wire          mSR_WE;

// SDRAM
wire   [15:0] mSDR_DATAC2M;
wire   [15:0] mSDR_DATAM2C;
wire          mSDR_Done;
wire   [21:0] mSDR_ADDR;
wire          mSDR_RD;
wire          mSDR_WR;


// Async Port Select
wire    [1:0] mSR_Select;

// CPU's external interrupt lines
wire   [`LM32_INTERRUPT_RNG] interrupt;

// Interrupts from peripherals
wire          uart_int;
wire          timer_int;
wire          ps2_int;

// CPU's  bus interconnect  
wire          wb_ack;       
wire          wb_ack_ctrl;
wire          wb_ack_uart;
wire          wb_ack_timer;
wire   [31:0] wb_dat_ctrl_i;
wire    [7:0] wb_dat_uart_o;
wire   [31:0] wb_dat_timer_o;
wire   [31:0] wb_dat_o;
wire   [31:0] wb_dat_i;
wire   [31:0] wb_adr;
wire          wb_cyc;
wire          wb_stb; 
wire    [3:0] wb_sel;
wire          wb_we;

// LED control from usb_jtag_cmd
wire    [9:0] cmd_ledr;

// Control wires from controller
wire   [31:0] status;
wire          cpu_done;
wire          resetcpu;

// SDRAM non-tristate output data and control
wire          SRAM_DQ_OE;
wire   [15:0] SRAM_DQ_OUT;

// Address decode
wire          sram_stb;
wire          uart0_stb; 
wire          timer_stb;
wire          local_stb;

wire   [35:0] gpio0_out;
wire   [35:0] gpio1_out;
wire   [35:0] gpio0_oe;
wire   [35:0] gpio1_oe;

wire          I2C_SDAT_OUT;

// Unused outputs drive to something 'inactive'
assign FL_ADDR      = 22'h000000;
assign FL_WE_N      = 1'b1;
assign FL_RST_N     = 1'b1;
assign FL_OE_N      = 1'b1;
assign FL_CE_N      = 1'b1;

assign SD_CLK       = 1'b0;

assign VGA_HS       = 1'b0;
assign VGA_VS       = 1'b0;
assign VGA_R        = 4'h0;
assign VGA_G        = 4'h0;
assign VGA_B        = 4'h0;

assign AUD_DACDAT   = 1'b0;
assign AUD_XCK      = 1'b0;

// All unused inout ports turn to tri-state
assign FL_DQ        = 8'hzz;
assign SD_DAT       = 1'bz;
assign SD_DAT3      = 1'bz;
assign SD_CMD       = 1'bz;
assign AUD_ADCLRCK  = 1'bz;
assign AUD_DACLRCK  = 1'bz;
assign AUD_BCLK     = 1'bz;

// Reset from pushbutton input
assign nreset       = KEY[0]; // Keys are on a schmitt trigger, so should be bounce free.

// Tri-state SRAM data
assign SRAM_DQ      = SRAM_DQ_OE ? SRAM_DQ_OUT : 16'hzzzz;

// Tristate control for GPIO
genvar i;
generate
  for (i = 0; i < 36; i = i + 1)
  begin : GPIO_ASSIGN
    assign GPIO_0[i] = gpio0_oe[i] ? gpio0_out[i] : 1'bz;
    assign GPIO_1[i] = gpio1_oe[i] ? gpio1_out[i] : 1'bz;
  end
endgenerate

// Tristate for I2C
assign I2C_SDAT      = I2C_SDAT_OUT ? 1'bz : 1'b0;

// Connect peripheral interrupts to CPU external interrupt pins
assign interrupt     = {{`LM32_INTERRUPT_WIDTH-4{1'b0}}, ps2_int, timer_int, uart_int};   

// Read LEDs controlled by command decoder ORed with internal status.
assign LEDR          = cmd_ledr | {{9{1'b0}}, cpu_done, ~resetcpu, mSR_Select[0]};

// Export the DRAM clock
assign DRAM_CLK      = sdram_clk;

  CLK_LOCK       p0 (.inclk           (TCK),
                     .outclk          (mTCK)
                    );

  // PLL for 50MHz input to 50/100MHz output
  PLL1           p1 (.inclk0          (CLOCK_50),
                     .c0              (sys_clk),
                     .c1              (sdram_clk),
                     .c2              (sram_clk)
                    );
    
  // USB-JTAG command decoder
  usb_jtag_cmd   u1 (
                     // Control
                     .iCLK            (sys_clk),
                     .iRST_n          (nreset),
                     
                     //JTAG           
                     .TDO             (TDO),
                     .TDI             (TDI),
                     .TCS             (TCS),
                     .TCK             (mTCK),

                     // LED + SEG7    
                     .oLED_GREEN      (LEDG),
                     .oLED_RED        (cmd_ledr),
                     
                     // Seven segment display
                     .iDIG            (status),
                     .oSEG0           (HEX0),
                     .oSEG1           (HEX1),
                     .oSEG2           (HEX2),
                     .oSEG3           (HEX3),
 
                     // SRAM          
                     .iSR_DATA        (SRAM_DQ),
                     .oSR_DATA        (mRS2SR_DATA),
                     .oSR_ADDR        (mSR_ADDR),
                     .oSR_WE_N        (mSR_WE),
                     .oSR_OE_N        (mSR_OE),
                     .oSR_Select      (mSR_Select),
                     
                     // SDRAM
                     .oSDR_DATA       (mSDR_DATAC2M),
                     .iSDR_DATA       (mSDR_DATAM2C),
                     .oSDR_ADDR       (mSDR_ADDR),
                     .iSDR_Done       (mSDR_Done),
                     .oSDR_WR         (mSDR_WR),
                     .oSDR_RD         (mSDR_RD)
                     );
                           
  
  // System controller  
  controller     u2 (.sys_clk         (sys_clk),
                     .sram_clk        (sram_clk),
                     .nreset          (nreset),

                     .wb_cyc          (wb_cyc),
                     .wb_stb_sram     (sram_stb),
                     .wb_stb_local    (local_stb),
                     .wb_we           (wb_we),
                     .wb_sel          (wb_sel),
                     .wb_ack          (wb_ack_ctrl),
                     .wb_adr          (wb_adr),
                     .wb_dat_o        (wb_dat_o),
                     .wb_dat_i        (wb_dat_ctrl_i),

                     .mSR_Select      (mSR_Select[0]),
                     .mSR_WE          (mSR_WE),
                     .mSR_OE          (mSR_OE),
                     .mSR_ADDR        (mSR_ADDR),
                     .mRS2SR_DATA     (mRS2SR_DATA),
                     
                     .mSDR_DATAC2M    (mSDR_DATAC2M),
                     .mSDR_DATAM2C    (mSDR_DATAM2C),
                     .mSDR_ADDR       (mSDR_ADDR),
                     .mSDR_Done       (mSDR_Done),
                     .mSDR_WR         (mSDR_WR),
                     .mSDR_RD         (mSDR_RD),

                     .status          (status),
                     .cpu_done        (cpu_done),
                     .resetcpu        (resetcpu),
                     
                     .gpio0_in        (GPIO_0),
                     .gpio1_in        (GPIO_1),
                     .gpio0_out       (gpio0_out),
                     .gpio1_out       (gpio1_out),
                     .gpio0_oe        (gpio0_oe),
                     .gpio1_oe        (gpio1_oe),
                     
                     .sw              (SW),
                     .key             (KEY),
                     
                     .ps2_clk         (PS2_CLK),
                     .ps2_dat         (PS2_DAT),
                     .ps2_int         (ps2_int),
                     
                     .I2C_SDAT_IN     (I2C_SDAT),
                     .I2C_SDAT_OUT    (I2C_SDAT_OUT),
                     .I2C_SCLK        (I2C_SCLK),

                     .SRAM_DQ         (SRAM_DQ),
                     .SRAM_DQ_OUT     (SRAM_DQ_OUT),
                     .SRAM_DQ_OE      (SRAM_DQ_OE),
                     .SRAM_ADDR       (SRAM_ADDR),
                     .SRAM_UB_N       (SRAM_UB_N),
                     .SRAM_LB_N       (SRAM_LB_N),
                     .SRAM_OE_N       (SRAM_OE_N),
                     .SRAM_WE_N       (SRAM_WE_N),
                     .SRAM_CE_N       (SRAM_CE_N)
                    );
                     defparam  u2.u2.REF_PER = 600, // 64000 ns / 4096 rows / sys_clk_period in ns - margin
                               u2.u2.SC_CL   = 3,
                               u2.u2.SC_RRD  = 7,
                               u2.u2.SC_PM   = 1,
                               u2.u2.SC_BL   = 1;    

  // Address decode for CPU data bus
  address_decode u3 (
                     .sys_clk         (sys_clk),
                     .nreset          (nreset),
                     
                     // Data bus inputs
                     .wb_adr           (wb_adr),
                     .wb_ack_uart      (wb_ack_uart),
                     .wb_ack_timer     (wb_ack_timer),
                     .wb_ack_ctrl      (wb_ack_ctrl),
                     .wb_stb           (wb_stb),
                     .wb_dat_uart_o    (wb_dat_uart_o),
                     .wb_dat_timer_o   (wb_dat_timer_o),
                     .wb_dat_ctrl_i    (wb_dat_ctrl_i),

                     // Decoded strobes (peripheral selects)
                     .sram_stb        (sram_stb),
                     .uart0_stb       (uart0_stb),
                     .timer_stb       (timer_stb),
                     .local_stb       (local_stb),
                     
                     // Returned ACK and read data
                     .wb_ack           (wb_ack),
                     .wb_dat_i         (wb_dat_i)
                     );                    
  
  // LatticeSemi UART  
  uart_core  #(.CLK_IN_MHZ (50),
               .BAUD_RATE  (115200))
                 u4 (
                      // System clock and reset
                     .CLK             (sys_clk),
                     .RESET           (resetcpu),
    
                      // Wishbone interface signals
                     .UART_CYC_I      (wb_cyc),
                     .UART_STB_I      (uart0_stb),
                     .UART_WE_I       (wb_we),
                     .UART_LOCK_I     (1'b0),
                     .UART_CTI_I      (3'b000),
                     .UART_BTE_I      (2'b00),
                     .UART_ADR_I      (wb_adr[5:2]),
                     .UART_DAT_I      (wb_dat_o[7:0]),
                     .UART_SEL_I      (wb_sel[0]),
                     .UART_ACK_O      (wb_ack_uart),
                     .UART_RTY_O      (),
                     .UART_ERR_O      (),
                     .UART_DAT_O      (wb_dat_uart_o),
    
                     .INTR            (uart_int),
    
                     // Receiver interface
                     .SIN             (UART_RXD),
                     .SOUT            (UART_TXD)    
                     );

  // LatticeSemi Timer
  timer   #(.PERIOD_WIDTH(32), 
            .PERIOD_NUM(0))  
                 u5 (
                     //system clock and reset
                     .CLK_I           (sys_clk),
                     .RST_I           (resetcpu),
                     
                     .S_ADR_I         (wb_adr),
                     .S_DAT_I         (wb_dat_o),
                     .S_WE_I          (wb_we),
                     .S_STB_I         (timer_stb),
                     .S_CYC_I         (wb_cyc),
                     .S_CTI_I         (3'b000),
                     .S_BTE_I         (2'b00),
                     .S_LOCK_I        (1'b0),
                     .S_SEL_I         (wb_sel),
                     .S_DAT_O         (wb_dat_timer_o),
                     .S_ACK_O         (wb_ack_timer),
                     .S_RTY_O         (),
                     .S_ERR_O         (),
                     .S_INT_O         (timer_int),
                     
                     .RSTREQ_O        (),
                     .TOPULSE_O       ()
                     );                    
                    
  // LatticeMico32 CPU
  lm32_wrap      u6 (
                     // Timing
                     .sys_clk         (sys_clk),
                     .resetcpu        (resetcpu),

                     // Interrupts
                     .interrupt       (interrupt),

                     // Master CPU bus (wishbone)
                     .m_ack           (wb_ack),
                     .m_adr           (wb_adr),
                     .m_cyc           (wb_cyc),
                     .m_dat_i         (wb_dat_i),
                     .m_dat_o         (wb_dat_o),
                     .m_sel           (wb_sel),
                     .m_stb           (wb_stb),
                     .m_we            (wb_we)
                    );

endmodule