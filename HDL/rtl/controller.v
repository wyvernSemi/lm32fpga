//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 24th May 2017
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
// $Id: controller.v,v 1.8 2017/08/23 09:17:11 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/controller.v,v $
//
//=============================================================

`include "regs.vh"

`define TEST_STATUS_ADDR       32'h0000fffc
`define TEST_HALT_ADDR         32'hfffffffc

// ------------------------------------------------
// System controller.
//
// Arbitrates access to SRAM between CMD_Decode,
// CPU IBUS and CPU DBUS. Generates CPU busses'
// acks, and multiplexes returned read data.
// Controls enabling/reseting of CPU, and captures
// test status data.
// 
// ------------------------------------------------

module controller (sys_clk,
                   sram_clk,
                   nreset,
                   
                   wb_cyc,
                   wb_stb_sram,
                   wb_stb_local,
                   wb_we,
                   wb_sel,
                   wb_ack,
                   wb_adr,
                   wb_dat_o,
                   wb_dat_i,
                   
                   mSR_Select,
                   mSR_WE,
                   mSR_OE,
                   mSR_ADDR,                   
                   mRS2SR_DATA,
                   
                   mSDR_DATAC2M,
                   mSDR_DATAM2C,
                   mSDR_Done,
                   mSDR_ADDR,
                   mSDR_RD,
                   mSDR_WR,

                   status,
                   cpu_done,
                   resetcpu,
                   
                   gpio0_in,
                   gpio1_in,                  
                   gpio0_out,
                   gpio1_out,
                   gpio0_oe,
                   gpio1_oe,
                   
                   sw,
                   key,
                   
                   ps2_clk,
                   ps2_dat,
                   ps2_int,
                   
                   I2C_SCLK,
                   I2C_SDAT_OUT,
                   I2C_SDAT_IN,
                   
                   SRAM_DQ,
                   SRAM_DQ_OUT,
                   SRAM_DQ_OE,
                   SRAM_ADDR,
                   SRAM_UB_N,
                   SRAM_LB_N,
                   SRAM_OE_N,
                   SRAM_WE_N,
                   SRAM_CE_N,

                   DRAM_DQ,
                   DRAM_ADDR,
                   DRAM_LDQM,
                   DRAM_UDQM,
                   DRAM_WE_N,
                   DRAM_CAS_N,
                   DRAM_RAS_N,
                   DRAM_CS_N,
                   DRAM_BA_0,
                   DRAM_BA_1,
                   DRAM_CLK,
                   DRAM_CKE

                   );

// Clocks and reset
input          sys_clk;
input          sram_clk;
input          nreset;

// Wishbone bus
input          wb_cyc;
input          wb_stb_sram;
input          wb_stb_local;
input          wb_we;
input    [3:0] wb_sel;
input   [31:0] wb_adr;
input   [31:0] wb_dat_o; // An input, but matches name of LM32 interface
output  [31:0] wb_dat_i; // An output, but matches name of LM32 interface
output         wb_ack;

// USB-JTAG SRAM bus
input          mSR_Select;
input          mSR_WE;
input          mSR_OE;
input   [17:0] mSR_ADDR;
input   [15:0] mRS2SR_DATA;

// USB-JTAG SDRAM bus
input   [15:0] mSDR_DATAC2M;
output  [15:0] mSDR_DATAM2C;
output         mSDR_Done;
input   [21:0] mSDR_ADDR;
input          mSDR_RD;
input          mSDR_WR;

// Execution control and status
output  [31:0] status;
output         cpu_done;
output         resetcpu;

// SRAM interface
input   [15:0] SRAM_DQ;
output  [15:0] SRAM_DQ_OUT;
output         SRAM_DQ_OE;
output  [17:0] SRAM_ADDR;
output         SRAM_UB_N;
output         SRAM_LB_N;
output         SRAM_OE_N;
output         SRAM_WE_N;
output         SRAM_CE_N;

// SDRAM Interface
inout   [15:0] DRAM_DQ;
output  [11:0] DRAM_ADDR;
output         DRAM_LDQM;
output         DRAM_UDQM;
output         DRAM_WE_N;
output         DRAM_CAS_N;
output         DRAM_RAS_N;
output         DRAM_CS_N;
output         DRAM_BA_0;
output         DRAM_BA_1;
output         DRAM_CLK;
output         DRAM_CKE;

input   [35:0] gpio0_in;
input   [35:0] gpio1_in;
output  [35:0] gpio0_out;
output  [35:0] gpio1_out;
output  [35:0] gpio0_oe;
output  [35:0] gpio1_oe;

input    [9:0] sw;
input    [3:0] key;

input          ps2_clk;
input          ps2_dat;
output         ps2_int;

output         I2C_SDAT_OUT;
input          I2C_SDAT_IN;
output         I2C_SCLK;

//-------------------------------------------------------------
// Internal state
//-------------------------------------------------------------

reg     [31:0] status;
reg            resetcpu; 
reg            cpu_done; 
reg            sram_ack;
reg     [15:0] sram_latched_data; 
reg            swen_reg;

reg     [39:0] gpio0_out_reg;
reg     [39:0] gpio1_out_reg;
reg     [39:0] gpio0_oe_reg;
reg     [39:0] gpio1_oe_reg;


reg            ps2_clk_last;
reg      [9:0] ps2_shift;
reg      [3:0] ps2_bit_count;  
reg     [31:0] ps2_rx_data;


reg     [23:0] i2c_data;
reg            i2c_go;
reg            i2c_ack;

//-------------------------------------------------------------
//Combinatorial logic
//-------------------------------------------------------------
wire           dram_cs_n_1_dummy;

wire    [31:0] internal_dat;
wire           i2c_end;
wire           i2c_active;
wire           i2c_ack_out;

wire    [31:0] gpio_addr   = `GPIO_BASE_ADDR;
wire    [31:0] ps2_addr    = `PS2_BASE_ADDR;
wire    [31:0] i2c_addr    = `I2C_BASE_ADDR;

// CPU SRAM access logic.
wire           swrite      =  wb_cyc & wb_stb_sram & wb_we;
wire           sube        =  sram_ack ? wb_sel[0] : wb_sel[2];
wire           slbe        =  sram_ack ? wb_sel[1] : wb_sel[3];

wire    [17:0] saddr       = {wb_adr[18:2], sram_ack};
wire    [15:0] sdata_out   = sram_ack ? {wb_dat_o[7:0],   wb_dat_o[15:8]} :
                                        {wb_dat_o[23:16], wb_dat_o[31:24]};      // Big endian
                                        
wire    [31:0] sdata_in    = {sram_latched_data[7:0], sram_latched_data[15:8], 
                              SRAM_DQ[7:0],           SRAM_DQ[15:8]};          // Big endian

// Acknowledge immediately for local accesses, or on SRAM acknowledge.
assign         wb_ack      = wb_stb_local ? wb_cyc : sram_ack;

// Mux to the local bus for local accesses, else the SRAM returned data
assign         wb_dat_i    = wb_stb_local ? internal_dat : sdata_in;

// Connect the SRAM signals to either JTAG or CPU signals,
// depending on mSR_Select                                                
assign         SRAM_ADDR   = mSR_Select ? mSR_ADDR : saddr;
assign         SRAM_UB_N   = mSR_Select ? 1'b0     : ~sube;
assign         SRAM_LB_N   = mSR_Select ? 1'b0     : ~slbe;
assign         SRAM_OE_N   = mSR_Select ? mSR_OE   : swrite;
assign         SRAM_WE_N   = swen_reg;
assign         SRAM_CE_N   = 1'b0;

// Arbitrate access write data to the SRAM data bus. mSR_Select is 
// set for JTAG access, and clear for CPU. When no active writes, 
// bus is tri-stated (SRAM_DQ_OE clear).
assign         SRAM_DQ_OUT = mSR_Select ? mRS2SR_DATA : sdata_out ;
assign         SRAM_DQ_OE  = (mSR_Select & ~mSR_WE) | (~mSR_Select & swrite); 

//-------------------------------------------------------------
// SRAM state update logic
//-------------------------------------------------------------

// On an active bus cycle, acknowledge on second cycle, allowing
// two reads from SRAM to construct 32 bit word from each 16 bit
// SRAM read value. sram_ack is used as lower address bit. The
// first cycle's read data is stored in sram_latched_data.
always @(posedge sys_clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    sram_ack              <= 1'b0;
    sram_latched_data     <= 16'h0000;
  end
  else
  begin  
    sram_ack              <= 1'b0;
    
    if ((wb_cyc & wb_stb_sram & ~sram_ack) == 1'b1)
    begin
      sram_ack            <= 1'b1;
      sram_latched_data   <= SRAM_DQ;
    end
  end
end

//-------------------------------------------------------------
// SRAM write enable generation
//-------------------------------------------------------------

// A write is active when either JTAG write or CPU write, selected
// on mSR_Select bit 0
wire wr_req                = mSR_Select ? ~mSR_WE : swrite;

// Generate a write enable signal for only half of a write access
// giving plenty of timing margin on writes, without the need for 
// complex constraints. sram_clk has a maximum frequency of 80MHz
// in order to meet the minimum timings for SRAM on the ALTERA 
// Cyclone II DE1 development board.
//             ___     ___     ___
// sys_clk   _/   \___/   \___/  
//           _   _   _   _   _   _
// sram_clk   \_/ \_/ \_/ \_/ \_/
//             _______
//  OEn      X/       \XXXXXXXXXXXX
//           ___     _____________
//  WEn         \___/

always @(posedge sram_clk  or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    swen_reg              <= 1'b1;
  end
  else
  begin
    if ((swen_reg & wr_req) == 1'b1)
    begin
      swen_reg            <= 1'b0;
    end
    else
    begin
      swen_reg            <= 1'b1;
    end
  end
end

//-------------------------------------------------------------
// Status state update logic
//-------------------------------------------------------------

// Put test status address into a wire for ease of bit slicing
wire [31:0] test_addr      = `TEST_STATUS_ADDR;
wire [31:0] test_halt_addr = `TEST_HALT_ADDR;

// Generate CPU reset, and latch test status. When a JTAG write to test
// status address, the CPU us asserted or deasserted according to whether
// JTAG is master of the SRAM bus or not. The status is captured if the
// CPU does a write access to the test address.
always @(posedge sys_clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    resetcpu              <=  1'b1;
    status                <=  32'h00000000;
    
    // By default, flag the CPU as done, since not all the code
    // running on the system will update this, and test code waiting
    // on CPU completion might hang. Software using this feature
    // should clear this flag early on program execution, and set
    // it just prior to completion.
    cpu_done              <=  1'b1;
  end
  else
  begin
    // If CPU potentially writing to a test address...
    if ((wb_cyc & wb_we & wb_ack) == 1'b1)
    begin
      // If writing to the test_addr SRAM test result location,
      // latch the data into status
      if (wb_stb_sram == 1'b1 && wb_adr == test_addr)
      begin
        status            <= wb_dat_o;
      end
      
      // If writing to the test 'CPU done' local address,
      // update the 'CPU done' state
      if (wb_stb_local == 1'b1 && wb_adr == test_halt_addr)
      begin
        cpu_done          <= wb_dat_o[0];
      end
    end

    // If controller writes to test location, when SRAM selected 
    // or CPU, release CPU reset, or reassert if SRAM selected for JTAG
    if (mSR_WE == 1'b0 && mSR_ADDR == test_addr[18:1])
    begin
      resetcpu            <= mSR_Select;
    end
  end
end

//-------------------------------------------------------------
// GPIO state update logic
//-------------------------------------------------------------

// Expand the 36 bits of the GPIO ports to the 40 bit connector positions, for register reads
wire [39:0] gpio40_0_in    = {gpio0_in[35:26], 1'b0, 1'b1, gpio0_in[25:10], 1'b0, 1'b1, gpio0_in[9:0]};
wire [39:0] gpio40_1_in    = {gpio0_in[35:26], 1'b0, 1'b1, gpio0_in[25:10], 1'b0, 1'b1, gpio0_in[9:0]};
wire [39:0] gpio40_0_oe_in = {gpio0_oe[35:26], 1'b0, 1'b1, gpio0_oe[25:10], 1'b0, 1'b1, gpio0_oe[9:0]}; 
wire [39:0] gpio40_1_oe_in = {gpio1_oe[35:26], 1'b0, 1'b1, gpio1_oe[25:10], 1'b0, 1'b1, gpio1_oe[9:0]}; 

// Collapse the 40 bit registers with connector positions, to 36 bit outputs
assign      gpio0_out      = {gpio0_out_reg[39:30], gpio0_out_reg[27:12], gpio0_out_reg[9:0]};
assign      gpio1_out      = {gpio1_out_reg[39:30], gpio1_out_reg[27:12], gpio1_out_reg[9:0]};
assign      gpio0_oe       = {gpio0_oe_reg [39:30], gpio0_oe_reg [27:12], gpio0_oe_reg [9:0]};
assign      gpio1_oe       = {gpio1_oe_reg [39:30], gpio1_oe_reg [27:12], gpio1_oe_reg [9:0]};

// Mux the internal registers to internal read data
wire [31:0] gpio_dat = (wb_adr[5:2] == (`GPIO_0_LO_REG >> 2))      ? gpio0_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_0_HI_REG >> 2))      ? {24'h000000, gpio40_0_in[39:32]} : 
                       (wb_adr[5:2] == (`GPIO_1_LO_REG >> 2))      ? gpio0_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_1_HI_REG >> 2))      ? {24'h000000, gpio40_1_in[39:32]} :
                       (wb_adr[5:2] == (`GPIO_0_OE_LO_REG >> 2))   ? gpio0_oe_reg[31:0] :
                       (wb_adr[5:2] == (`GPIO_0_OE_HI_REG >> 2))   ? {24'h000000, gpio0_oe_reg[39:32]} :
                       (wb_adr[5:2] == (`GPIO_1_OE_LO_REG >> 2))   ? gpio1_oe_reg[31:0] :
                       (wb_adr[5:2] == (`GPIO_1_OE_HI_REG >> 2))   ? {24'h000000, gpio1_oe_reg[39:32]} :
                       (wb_adr[5:2] == (`GPIO_0_X_LO_REG >> 2))    ? gpio40_0_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_0_X_HI_REG >> 2))    ? {24'h000000, gpio40_0_in[39:32]} : 
                       (wb_adr[5:2] == (`GPIO_1_X_LO_REG >> 2))    ? gpio40_0_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_1_X_HI_REG >> 2))    ? {24'h000000, gpio40_1_in[39:32]} :
                       (wb_adr[5:2] == (`GPIO_0_X_OE_LO_REG >> 2)) ? gpio40_0_oe_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_0_X_OE_HI_REG >> 2)) ? {24'h000000, gpio40_0_oe_in[39:32]} :
                       (wb_adr[5:2] == (`GPIO_1_X_OE_LO_REG >> 2)) ? gpio40_1_oe_in[31:0] :
                       (wb_adr[5:2] == (`GPIO_1_X_OE_HI_REG >> 2)) ? {24'h000000, gpio40_1_oe_in[39:32]} :
                                                              32'h00000000;
                                                              
wire [31:0] sw_dat   = (wb_adr[5:2] == (`SWITCH_DPDT_REG >>2)) ? {22'h000000,  sw}  :
                       (wb_adr[5:2] == (`SWITCH_KEY_REG >> 2)) ? {28'h0000000, key} :
                                                                 32'h00000000;
                     
assign internal_dat  = (wb_adr[30:28] == gpio_addr[30:28]) ? gpio_dat          : 
                       (wb_adr[30:28] == ps2_addr[30:28])  ? ps2_rx_data       :
                       (wb_adr[30:28] == i2c_addr[30:28])  ? {i2c_active, i2c_ack, 6'h00, i2c_data} :
                                                            sw_dat;
                                                      
// GPIO register writes                      
always @(posedge sys_clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    gpio0_out_reg         <= 40'd0;
    gpio1_out_reg         <= 40'd0;
    gpio0_oe_reg          <= 40'd0;
    gpio1_oe_reg          <= 40'd0;
  end
  else
  begin
    // If CPU writing to an internal address....
    if ((wb_cyc & wb_stb_local & wb_we) == 1'b1)
    begin
      // If writing to the GPIO registers...
      if (wb_adr[31:28] == gpio_addr[31:28])
      begin
        case (wb_adr[5:2])
        // Write as a contiguous 36 bits, mapped to the 40 bits of connector
        (`GPIO_0_LO_REG    >> 2):   gpio0_out_reg[35:0]  <= {wb_dat_o[31:26], 1'b0, 1'b1, wb_dat_o[25:10], 1'b0, 1'b1, wb_dat_o[9:0]};
        (`GPIO_0_HI_REG    >> 2):   gpio0_out_reg[39:36] <=  wb_dat_o[3:0];
        (`GPIO_1_LO_REG    >> 2):   gpio1_out_reg[35:0]  <= {wb_dat_o[31:26], 1'b0, 1'b1, wb_dat_o[25:10], 1'b0, 1'b1, wb_dat_o[9:0]};
        (`GPIO_1_HI_REG    >> 2):   gpio1_out_reg[39:36] <=  wb_dat_o[3:0];
        (`GPIO_0_OE_LO_REG >> 2):   gpio0_oe_reg [35:0]  <= {wb_dat_o[31:26], 1'b0, 1'b1, wb_dat_o[25:10], 1'b0, 1'b1, wb_dat_o[9:0]};
        (`GPIO_0_OE_HI_REG >> 2):   gpio0_oe_reg [39:36] <=  wb_dat_o[3:0];
        (`GPIO_1_OE_LO_REG >> 2):   gpio1_oe_reg [35:0]  <= {wb_dat_o[31:26], 1'b0, 1'b1, wb_dat_o[25:10], 1'b0, 1'b1, wb_dat_o[9:0]};
        (`GPIO_1_OE_HI_REG >> 2):   gpio1_oe_reg [39:36] <=  wb_dat_o[3:0];
        
        // Write directly as 40 bits of connector. Bits 10, 11, 28 and 29 have no affect (VCC and GND positions)
        (`GPIO_0_X_LO_REG    >> 2): gpio0_out_reg[31:0]  <= wb_dat_o;
        (`GPIO_0_X_HI_REG    >> 2): gpio0_out_reg[39:32] <= wb_dat_o[7:0];
        (`GPIO_1_X_LO_REG    >> 2): gpio1_out_reg[31:0]  <= wb_dat_o;
        (`GPIO_1_X_HI_REG    >> 2): gpio1_out_reg[39:32] <= wb_dat_o[7:0];
        (`GPIO_0_X_OE_LO_REG >> 2): gpio0_oe_reg [31:0]  <= wb_dat_o;
        (`GPIO_0_X_OE_HI_REG >> 2): gpio0_oe_reg [39:32] <= wb_dat_o[7:0];
        (`GPIO_1_X_OE_LO_REG >> 2): gpio1_oe_reg [31:0]  <= wb_dat_o;
        (`GPIO_1_X_OE_HI_REG >> 2): gpio1_oe_reg [39:32] <= wb_dat_o[7:0];
        endcase
      end
    end
  end
end

//-------------------------------------------------------------
// PS2 logic
//-------------------------------------------------------------

// Assert PS2 interrupt line whenever there is a valid byte
// in the PS2 rx data register.
assign ps2_int = ps2_rx_data[`PS2_RX_VALID_RNG];

always @(posedge sys_clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    ps2_clk_last                   <= 1'b1;
    ps2_bit_count                  <= 4'h0;
    ps2_rx_data[`PS2_RX_VALID_RNG] <= 1'b0;   
  end
  else
  begin
    ps2_clk_last          <= ps2_clk;
    
    // On falling edge of clock...
    if (ps2_clk_last == 1'b1 && ps2_clk == 1'b0)
    begin
      // Shift in data bit
      ps2_shift           <= {ps2_dat, ps2_shift[9:1]};
      
      // If this is the start bit, set the bit counter
      if (ps2_bit_count == 4'h0)
      begin
        ps2_bit_count <= 4'd11;
      end
      
      // If this is the stop bit....
      if (ps2_bit_count == 4'h1)
      begin
        // Latch the shifted in data
        ps2_rx_data[28:0]             <= {21'h000000, ps2_shift[8:1]};
        
        // Set the valid bit
        ps2_rx_data[`PS2_RX_VALID_RNG]   <= 1'b1;
        
        // Set the parity error if not odd parity (sticky)
        ps2_rx_data[`PS2_RX_PAR_ERR_RNG] <= ps2_rx_data[`PS2_RX_PAR_ERR_RNG] | (~^ps2_shift[9:1]);
        
        // Set overflow bit if valid bit not clear (sticky)
        ps2_rx_data[`PS2_RX_OVRFLOW_RNG] <= ps2_rx_data[`PS2_RX_OVRFLOW_RNG] | ps2_rx_data[`PS2_RX_VALID_RNG];
      end
    end
    
    // If CPU accessing a PS2 address....
    if ((wb_cyc & wb_stb_local) == 1'b1 && wb_adr[31:28] == ps2_addr[31:28])
    begin
      // Writing to the PS2 register (regardless of address offset)
      if (wb_we)
      begin
        ps2_rx_data <= wb_dat_o;
      end
      // When reading from the PS2 RX register, clear the valid bit 
      // (register can be peek'd without clearing valid at `PS2_RX_PEEK_OFFSET)
      else
      begin
        if (wb_adr[5:2] == (`PS2_RX_REG >> 2))
        begin
          ps2_rx_data[`PS2_RX_VALID_RNG] <= 1'b0;
        end
      end
    end
  end
end

//-------------------------------------------------------------
// I2C
//-------------------------------------------------------------

always @(posedge sys_clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    i2c_go  <= 1'b0;
    i2c_ack <= 1'b0;
  end
  else
  begin
    // If CPU writing to an I2C address....
    if ((wb_cyc & wb_stb_local & wb_we) == 1'b1 && wb_adr[31:28] == i2c_addr[31:28])
    begin
      i2c_data <= wb_dat_o[23:0];
      i2c_go   <= 1'b1;
      i2c_ack  <= 1'b0;
    end
    
    if (i2c_end == 1'b1)
    begin
      i2c_go  <= 1'b0;
      i2c_ack <= i2c_ack_out;
    end
  end
end

I2C_Controller   u1 (
                     .clk         (sys_clk),
                     .nreset      (nreset),
                     
                     .I2C_SCLK    (I2C_SCLK),
                     .I2C_SDAT_OUT(I2C_SDAT_OUT),
                     .I2C_SDAT_IN (I2C_SDAT_IN),
                     
                     .I2C_DATA    (i2c_data),
                     .GO          (i2c_go),      
                     .END         (i2c_end),     
                     .W_R         (1'b1),     
                     .ACK         (i2c_ack_out),
                     .ACTIVE      (i2c_active)
                     );
                    
                    

Sdram_Controller u2 (
                      // HOST
                     .CLK             (sys_clk),
                     .REF_CLK         (sys_clk),
                     .RESET_N         (nreset),
                     
                     .ADDR            ({1'b0, mSDR_ADDR}),
                     .WR              (mSDR_WR),
                     .RD              (mSDR_RD),
                     .LENGTH          (8'h01),
                     .ACT             (),
                     .DONE            (mSDR_Done),
                     .DATAIN          (mSDR_DATAC2M),
                     .DATAOUT         (mSDR_DATAM2C),
                     .IN_REQ          (),
                     .OUT_VALID       (),
                     .DM              (2'b00),
                     
                     //	SDRAM
                     .SA              (DRAM_ADDR),
                     .BA              ({DRAM_BA_1, DRAM_BA_0}),
                     .CS_N            ({dram_cs_n_1_dummy, DRAM_CS_N}),
                     .CKE             (DRAM_CKE),
                     .RAS_N           (DRAM_RAS_N),
                     .CAS_N           (DRAM_CAS_N),
                     .WE_N            (DRAM_WE_N),
                     .DQ              (DRAM_DQ),
                     .DQM             ({DRAM_UDQM, DRAM_LDQM})
                     );
endmodule