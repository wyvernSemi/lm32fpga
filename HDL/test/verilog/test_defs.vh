//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 6th June 2017
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
// $Id: test_defs.vh,v 1.6 2017/08/28 13:10:28 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/test_defs.vh,v $
//
//=============================================================
//
// Test harness common definitions. All test sub-module files
// should include this header.
//
//=============================================================

`ifndef _TEST_DEFS_VH_
`define _TEST_DEFS_VH_

`timescale 1ps / 1ps

`define PICOSECOND             1
`define NANOSECOND             (1000  * `PICOSECOND)
`define MICROSECOND            (1000  * `NANOSECOND)
`define MILLISECOND            (1000  * `MICROSECOND)
`define SECOND                 (1000  * `MILLISECOND)

`define REGDEL                 (1     * `NANOSECOND) 

`define CLKPERIOD50            (20    * `NANOSECOND)
`define CLKPERIODJTAG          (100   * `NANOSECOND)

// PLL clock outputs are 40MHz for clock 0 and 1, and 80MHz for clock 2
`define CLKMUL0                4
`define CLKDIV0                5
`define CLKMUL1                4
`define CLKDIV1                5
`define CLKMUL2                8
`define CLKDIV2                5

// Derive the system clock frequency in KHz from the previous definitions
`define SYS_CLK_FREQ_KHZ       ((1000000 / ((`CLKPERIOD50 * `CLKDIV0) / `CLKMUL0)) * 1000)

// In simulation, make the I2C interface run 10 times faster
`ifndef SIM
`define I2C_CLK_FREQ_KHZ       20
`else
`define I2C_CLK_FREQ_KHZ       2000
`endif

// Annoyingly, the phase parameter has to be a string, so can't be calculated
// from the other definitions. It is 100MHz period divided by 2, or
// `(CLKPERIOD50 * `CLKDIV2)/(`CLKMUL2 * 2), if these definitions change.
`define CLKPHASE2_180          "6250" 

// In simulation, make the UART interface run 10 times faster
`ifndef SIM
`define TEST_BAUDRATE          115200
`else
`define TEST_BAUDRATE          1152000
`endif

`endif