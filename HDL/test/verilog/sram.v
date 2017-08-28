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
// $Id: sram.v,v 1.2 2017/08/28 10:33:37 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/sram.v,v $
//
//=============================================================
//
// Simple model of a 512KB SRAM memory (256K x 16).
//
//=============================================================

`include "test_defs.vh"

// SRAM 512KB
`define MEMBYTEADDRBITS        19
`define MEMSIZEBYTES           (1 << `MEMBYTEADDRBITS)

module sram (
              inout  [15:0] SRAM_DQ, 
              input  [17:0] SRAM_ADDR,
              input         SRAM_UB_N,
              input         SRAM_LB_N,
              input         SRAM_WE_N,
              input         SRAM_CE_N,
              input         SRAM_OE_N
             );

reg     [7:0] mem[`MEMSIZEBYTES-1:0];

wire [`MEMBYTEADDRBITS-1:0] byte_addr0 = {SRAM_ADDR, 1'b0};
wire [`MEMBYTEADDRBITS-1:0] byte_addr1 = {SRAM_ADDR, 1'b1};

wire   sram_read = ~SRAM_CE_N & ~SRAM_OE_N;

// DQ tristate control. Only drive if chip selected and output enable active.
assign SRAM_DQ   = {(~sram_read | SRAM_UB_N) ? 8'hzz : mem[byte_addr1], 
                    (~sram_read | SRAM_LB_N) ? 8'hzz : mem[byte_addr0]};

always @(*)
begin
  // Write to memory if chip selected, WE active and one or more 
  // byte enables active.
  if (~SRAM_CE_N & ~SRAM_WE_N)
  begin
    if (~SRAM_LB_N)
      mem[byte_addr0]   = SRAM_DQ [7:0];

    if (~SRAM_UB_N)
      mem[byte_addr1]   = SRAM_DQ [15:8];
  end
end

endmodule