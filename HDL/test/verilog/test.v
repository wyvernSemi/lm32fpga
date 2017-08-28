//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 30th May 2017
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
// $Id: test.v,v 1.5 2017/08/28 13:05:19 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/test.v,v $
//
//=============================================================

//=============================================================
// test
//
// Top level test module, instantiating the UUT, drivers
// memory and a monitor
//
//=============================================================

`include "test_defs.vh"

module test;

wire        CLOCK_50;
wire        jtag_clk;
wire        nreset;
wire        jtag_done;

// Display interface
wire [27:0] HEX;
wire  [7:0] LEDG;
wire  [9:0] LEDR;

// UART
wire        UART_TXD;
wire        UART_RXD;

// SRAM Interface
wire [15:0] SRAM_DQ;  
wire [17:0] SRAM_ADDR;
wire        SRAM_UB_N;
wire        SRAM_LB_N;
wire        SRAM_WE_N;
wire        SRAM_CE_N;
wire        SRAM_OE_N;

// SDRAM Interface
wire [15:0] DRAM_DQ;
wire [11:0] DRAM_ADDR;
wire        DRAM_LDQM;
wire        DRAM_UDQM;
wire        DRAM_WE_N;
wire        DRAM_CAS_N;
wire        DRAM_RAS_N;
wire        DRAM_CS_N;
wire        DRAM_BA_0;
wire        DRAM_BA_1;
wire        DRAM_CLK;
wire        DRAM_CKE;

// USB-JTAG
wire        TDI;
wire        TCS;
wire        TDO;
wire        TCK;

// I2C
wire        I2C_SDAT;
wire        I2C_SCLK;

// PS2
wire        PS2_CLK;
wire        PS2_DAT;

// UART
wire        UART_TXRDY;
wire  [7:0] UART_TXDATA;
wire        UART_TXACK;
wire        UART_RXRDY;
wire  [7:0] UART_RXDATA;
wire        UART_RXERR;

wire [35:0] GPIO_0;
wire [35:0] GPIO_1;

//-------------------------------------------------------------
// Hierarchical code
  
  alt_lm32  UUT (
                // Clock Input
                .CLOCK_50              (CLOCK_50),

                // Push Button
                .KEY                   ({3'b111, nreset}),
                .SW                    (10'h000),

                // 7-SEG Display
                .HEX0                  (HEX[6:0]),
                .HEX1                  (HEX[13:7]),
                .HEX2                  (HEX[20:14]),
                .HEX3                  (HEX[27:21]),

                // LED
                .LEDG                  (LEDG),
                .LEDR                  (LEDR),

                // UART
                .UART_TXD              (UART_TXD),
                .UART_RXD              (UART_RXD),

                // SRAM Interface
                .SRAM_DQ               (SRAM_DQ),  
                .SRAM_ADDR             (SRAM_ADDR),
                .SRAM_UB_N             (SRAM_UB_N), 
                .SRAM_LB_N             (SRAM_LB_N),
                .SRAM_WE_N             (SRAM_WE_N),
                .SRAM_CE_N             (SRAM_CE_N),
                .SRAM_OE_N             (SRAM_OE_N),
                
                // SDRAM interface
                .DRAM_DQ               (DRAM_DQ),
                .DRAM_ADDR             (DRAM_ADDR),
                .DRAM_LDQM             (DRAM_LDQM),
                .DRAM_UDQM             (DRAM_UDQM),
                .DRAM_WE_N             (DRAM_WE_N),
                .DRAM_CAS_N            (DRAM_CAS_N),
                .DRAM_RAS_N            (DRAM_RAS_N),
                .DRAM_CS_N             (DRAM_CS_N),
                .DRAM_BA_0             (DRAM_BA_0),
                .DRAM_BA_1             (DRAM_BA_1),
                .DRAM_CLK              (DRAM_CLK),
                .DRAM_CKE              (DRAM_CKE),

                // USB JTAG link
                .TDI                   (TDI),
                .TCK                   (TCK),
                .TCS                   (TCS),
                .TDO                   (TDO),

                // I2C interface
                .I2C_SCLK              (I2C_SCLK),
                .I2C_SDAT              (I2C_SDAT),

                // PS2 interface
                .PS2_CLK               (PS2_CLK),
                .PS2_DAT               (PS2_DAT),

                // GPIO interface
                .GPIO_0                (GPIO_0),
                .GPIO_1                (GPIO_1)                
                );
        // Define parameters for PLL1 test component in UUT. PLL1 simulation
        // model has a compatible subset of parameters to the Altera component,
        // and so could be substituted for Altera's model.  
        defparam UUT.p1.altpll_component.inclk0_input_frequency = `CLKPERIOD50,    // inclk0 is 50MHz
                 UUT.p1.altpll_component.clk0_multiply_by       = `CLKMUL0,        // c0 is inclk0 * 4 / 5 = 40MHz
                 UUT.p1.altpll_component.clk0_divide_by         = `CLKDIV0,
                 UUT.p1.altpll_component.clk1_multiply_by       = `CLKMUL1,        // c1 is inclk0 * 4 / 5 = 40MHz
                 UUT.p1.altpll_component.clk1_divide_by         = `CLKDIV1,
                 UUT.p1.altpll_component.clk2_multiply_by       = `CLKMUL2,        // c2 is inclk0 * 8 / 5 = 80MHz
                 UUT.p1.altpll_component.clk2_divide_by         = `CLKDIV2,
                 UUT.p1.altpll_component.clk2_phase_shift       = `CLKPHASE2_180,  // 180 deg phase shift
                 UUT.u2.u1.clk_freq_khz                         = `SYS_CLK_FREQ_KHZ,
                 UUT.u2.u1.i2c_freq_khz                         = `I2C_CLK_FREQ_KHZ,
                 UUT.u4.BAUD_RATE                               = `TEST_BAUDRATE;
 
  
  sram     sram (
                .SRAM_DQ               (SRAM_DQ),  
                .SRAM_ADDR             (SRAM_ADDR),
                .SRAM_UB_N             (SRAM_UB_N), 
                .SRAM_LB_N             (SRAM_LB_N),
                .SRAM_WE_N             (SRAM_WE_N),
                .SRAM_CE_N             (SRAM_CE_N),
                .SRAM_OE_N             (SRAM_OE_N)
                );
                
  sdram_1Mx16x4  sdram (
                .DRAM_DQ               (DRAM_DQ),
                .DRAM_ADDR             (DRAM_ADDR),
                .DRAM_LDQM             (DRAM_LDQM),
                .DRAM_UDQM             (DRAM_UDQM),
                .DRAM_WE_N             (DRAM_WE_N),
                .DRAM_CAS_N            (DRAM_CAS_N),
                .DRAM_RAS_N            (DRAM_RAS_N),
                .DRAM_CS_N             (DRAM_CS_N),
                .DRAM_BA_0             (DRAM_BA_0),
                .DRAM_BA_1             (DRAM_BA_1),
                .DRAM_CLK              (DRAM_CLK),
                .DRAM_CKE              (DRAM_CKE)
                );  

  jtag_drv jtag (
                .clk                   (jtag_clk),
                .nreset                (nreset),
                
                .TDI                   (TDI),
                .TCK                   (TCK),
                .TCS                   (TCS),
                .TDO                   (TDO),
                
                .done                  (jtag_done)
                );
                

  uart_drv uart (
                 .clk                  (CLOCK_50), 
                 .nreset               (nreset), 
                 
                 .rx                   (UART_TXD), 
                 .tx                   (UART_RXD),
                 
                 .txrdy                (UART_TXRDY),
                 .txdata               (UART_TXDATA),
                 .txack                (UART_TXACK),
                 
                 .rxrdy                (UART_RXRDY),
                 .rxdata               (UART_RXDATA),
                 .rxerr                (UART_RXERR)
                 ); 

  i2c_drv   i2c (
                 .I2C_SCLK             (I2C_SCLK),
                 .I2C_SDAT             (I2C_SDAT)
                 );                 

  monitor   mon ( 
                .CLOCK_50              (CLOCK_50),
                .jtag_clk              (jtag_clk),
                .nreset                (nreset),
                
                .jtag_done             (jtag_done),
                
                // PS2 interface
                .PS2_CLK               (PS2_CLK),
                .PS2_DAT               (PS2_DAT),
                
                // LEDs
                .HEX                   (HEX),
                .LEDG                  (LEDG),
                .LEDR                  (LEDR),
                
                // UART
                .txrdy                 (UART_TXRDY),
                .txdata                (UART_TXDATA),
                .txack                 (UART_TXACK),
                .rxrdy                 (UART_RXRDY),
                .rxdata                (UART_RXDATA),
                .rxerr                 (UART_RXERR)
                );   
               
endmodule
