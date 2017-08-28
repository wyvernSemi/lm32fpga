//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 21st August 2017
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
// $Id: lm32_wrap.v,v 1.1 2017/08/22 09:16:05 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/lm32_wrap.v,v $
//
//=============================================================

`include "lm32_include.v"

module lm32_wrap (sys_clk,
                  resetcpu,
                  
                  interrupt,
                  
                  m_ack,
                  m_adr,
                  m_cyc,
                  m_dat_i,
                  m_dat_o,
                  m_sel,
                  m_stb,
                  m_we
);

input         sys_clk;
input         resetcpu;
input [`LM32_INTERRUPT_RNG] interrupt;

input         m_ack;       
output [31:0] m_dat_o;
input  [31:0] m_dat_i;
output [31:0] m_adr;
output        m_cyc;
output        m_stb; 
output  [3:0] m_sel;
output        m_we;

wire          d_ack;       
wire   [31:0] d_dat_o;
wire   [31:0] d_dat_i;
wire   [31:0] d_adr;
wire          d_cyc;
wire          d_stb; 
wire    [3:0] d_sel;
wire          d_we;

wire          i_ack;       
wire   [31:0] i_dat;
wire   [31:0] i_adr;
wire          i_cyc;
wire          i_stb;

  // LatticeMico32 CPU
  lm32_top       u1 (
                     // Timing
                     .clk_i           (sys_clk),
                     .rst_i           (resetcpu),

                     // Interrupts
                     .interrupt       (interrupt),

                     // Instruction bus (wishbone)
                     .I_ACK_I         (i_ack),
                     .I_ADR_O         (i_adr),
                     .I_BTE_O         (),
                     .I_CTI_O         (),
                     .I_CYC_O         (i_cyc),
                     .I_DAT_I         (i_dat),
                     .I_DAT_O         (),
                     .I_ERR_I         (1'b0),
                     .I_LOCK_O        (),
                     .I_RTY_I         (1'b0),
                     .I_SEL_O         (),
                     .I_STB_O         (i_stb),
                     .I_WE_O          (),

                     // Data bus (wishbone)
                     .D_ACK_I         (d_ack),
                     .D_ADR_O         (d_adr),
                     .D_BTE_O         (),
                     .D_CTI_O         (),
                     .D_CYC_O         (d_cyc),
                     .D_DAT_I         (d_dat_i),
                     .D_DAT_O         (d_dat_o),
                     .D_ERR_I         (1'b0),
                     .D_LOCK_O        (),
                     .D_RTY_I         (1'b0),
                     .D_SEL_O         (d_sel),
                     .D_STB_O         (d_stb),
                     .D_WE_O          (d_we)
                    );
                    
  wb_mux          u2 (.sys_clk         (sys_clk),
                      .resetcpu        (resetcpu),
                      
                      // High priority bus
                      .h_cyc           (i_cyc),
                      .h_stb           (i_stb),
                      .h_we            (1'b0),
                      .h_sel           (4'hf),
                      .h_ack           (i_ack),
                      .h_adr           (i_adr),
                      .h_dat_o         (32'h00000000),
                      .h_dat_i         (i_dat),
                      
                      // Low priority bus
                      .l_cyc           (d_cyc),
                      .l_stb           (d_stb),
                      .l_we            (d_we),
                      .l_sel           (d_sel),
                      .l_ack           (d_ack),
                      .l_adr           (d_adr),
                      .l_dat_o         (d_dat_o),
                      .l_dat_i         (d_dat_i),
                      
                      // Muxed bus
                      .m_cyc           (m_cyc),
                      .m_stb           (m_stb),
                      .m_we            (m_we),
                      .m_sel           (m_sel),
                      .m_ack           (m_ack),
                      .m_adr           (m_adr),
                      .m_dat_o         (m_dat_o),
                      .m_dat_i         (m_dat_i)

); 

endmodule                    