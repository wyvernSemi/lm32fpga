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
// $Id: lm32_config.v,v 1.1 2017/06/10 13:59:52 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/lm32_config.v,v $
//
//=============================================================

`ifdef LM32_CONFIG_V
`else
`define LM32_CONFIG_V

`define CFG_EBA_RESET                  32'h0
`define CFG_DEBA_RESET                 32'h0

`define CFG_PL_MULTIPLY_ENABLED
`define CFG_PL_BARREL_SHIFT_ENABLED
`define CFG_SIGN_EXTEND_ENABLED
`define CFG_MC_DIVIDE_ENABLED

`define CFG_ICACHE_ENABLED
`define CFG_ICACHE_ASSOCIATIVITY       1
`define CFG_ICACHE_SETS                256
`define CFG_ICACHE_BYTES_PER_LINE      16
`define CFG_ICACHE_BASE_ADDRESS        32'h0
`define CFG_ICACHE_LIMIT               32'h7fffffff

`define CFG_DCACHE_ENABLED
`define CFG_DCACHE_ASSOCIATIVITY       1
`define CFG_DCACHE_SETS                256
`define CFG_DCACHE_BYTES_PER_LINE      16
`define CFG_DCACHE_BASE_ADDRESS        32'h0
`define CFG_DCACHE_LIMIT               32'h7fffffff

// Enable Debugging
//`define CFG_JTAG_ENABLED
//`define CFG_JTAG_UART_ENABLED
`define CFG_DEBUG_ENABLED
//`define CFG_HW_DEBUG_ENABLED
`define CFG_ROM_DEBUG_ENABLED
`define CFG_BREAKPOINTS                32'h4
`define CFG_WATCHPOINTS                32'h4
//`define CFG_EXTERNAL_BREAK_ENABLED

// Enable MMU
`define CFG_MMU_ENABLED

// Define the macro that converts memory sizes to number of required address bits
`define CLOG2 $clog2

`endif
