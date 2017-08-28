//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 11th August 2017
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
// $Id: wb_mux.v,v 1.1 2017/08/22 09:16:05 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/wb_mux.v,v $
//
//=============================================================

`include "regs.vh"

// Wishbone bus multiplexer, with high priority and low priority 
// bus master interfaces, muxed to a single interface. High
// priority interface always wins when bus is inactive, but low
// priority access is not interrupted if already started when 
// high prirority request asserted.

module wb_mux (sys_clk,
               resetcpu,
               
               // High priority bus
               h_cyc,
               h_stb,
               h_we,
               h_sel,
               h_ack,
               h_adr,
               h_dat_o,
               h_dat_i,

               // Low priority bus
               l_cyc,
               l_stb,
               l_we,
               l_sel,
               l_ack,
               l_adr,
               l_dat_o,
               l_dat_i,

               // Muxed bus
               m_cyc,
               m_stb,
               m_we,
               m_sel,
               m_ack,
               m_adr,
               m_dat_o,
               m_dat_i

);

input          sys_clk;
input          resetcpu;

input          h_cyc;
input          h_stb;
input          h_we;
input    [3:0] h_sel;
input   [31:0] h_adr;
input   [31:0] h_dat_o; // An input, but matches name of LM32 interface
output  [31:0] h_dat_i; // An output, but matches name of LM32 interface
output         h_ack;

input          l_cyc;
input          l_stb;
input          l_we;
input    [3:0] l_sel;
input   [31:0] l_adr;
input   [31:0] l_dat_o; // An input, but matches name of LM32 interface
output  [31:0] l_dat_i; // An output, but matches name of LM32 interface
output         l_ack;

output         m_cyc;
output         m_stb;
output         m_we;
output   [3:0] m_sel;
output  [31:0] m_adr;
output  [31:0] m_dat_o;
input   [31:0] m_dat_i;
input          m_ack;

reg            active;
reg            h_owns_bus_reg;

// Select high priority bus, if bus inactive and high priority bus
// requesting, or (when active), it is the selected bus.
wire   sel_h         = (h_cyc & ~active) | (h_owns_bus_reg & active);

// Mux the outputs from the two busses
assign m_cyc         = h_cyc | l_cyc;
assign m_stb         = sel_h ? h_stb   : l_stb;
assign m_we          = sel_h ? h_we    : l_we;
assign m_sel         = sel_h ? h_sel   : l_sel;
assign m_adr         = sel_h ? h_adr   : l_adr;
assign m_dat_o       = sel_h ? h_dat_o : l_dat_o;

// Route read data back to sources (regardless of bus selection)
assign h_dat_i       = m_dat_i;
assign l_dat_i       = m_dat_i;

// Route ACK back to selected bus.
// Using h_owns_bus_reg assumes there can be no ACK earlier than the 
// next cycle. If ACK can be in the same cycle as assertion of m_cyc,
// then sel_h should be used, but this has slow timing and could, potentially,
// create a timing loop, as ack would then be dependant on <x>_cyc.
assign h_ack         =  h_owns_bus_reg & m_ack;
assign l_ack         = ~h_owns_bus_reg & m_ack;

always @(posedge sys_clk  or posedge resetcpu)
begin
  if (resetcpu == 1'b1)
  begin
    active          <= 1'b0;
    h_owns_bus_reg  <= 1'b0;
  end
  else
  begin
    // Go active (and hold) if either bus requesting, clearing state on the returned ACK
    active          <= (active | h_cyc | l_cyc) & ~m_ack;
    
    // Flag high priority bus ownership, and hold, or if that bus requesting and inactive.
    h_owns_bus_reg  <= (active & h_owns_bus_reg) | (~active & h_cyc);
  end
end

endmodule