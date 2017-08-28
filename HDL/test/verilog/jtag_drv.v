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
// $Id: jtag_drv.v,v 1.3 2017/07/04 12:04:57 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/jtag_drv.v,v $
//
//=============================================================
//
// JTAG command driver module. Reads commands (from test.hex)
// into its internal memory (mem), and starts executing them 
// when reset is deactivated, sending data over the UUT's JTAG
// interface.
//
// The packet format is an MSB 4 byte time, followed by an 8
// byte command:
//
// 4 bytes: delta time (jtag_clk count) for command (MSB),
//          counting from the end of the last command
// 8 bytes: command= <action>
//                   <target>
//                   <hw_addr[23:16>
//                   <hw_addr[15:8]>
//                   <hw_addr[7:0]>
//                   <data[15:8]>
//                   <data[7:0]>
//                   <mode>
// 
// <action> : SETUP(61)   ERASE(72)   WRITE(83)   READ(94)
//            LCD_DAT(a5) LCD_CMD(b6)
//
// <target> : LED(f0)     SEG7(e1)    PS2(d2)     FLASH(c3)
//            SDRAM(b4)   SRAM(a5)    LCD(96)     VGA(87)
//            SDRSEL(1f)  FLSEL(2e)
//
//            EXTIO(3d)   SET_REG(4c) SRSEL(5b)
// <mode>   : OUTSEL(33)  NORMAL(aa)  DISPLAY(cc) BURST(ff)
//
//=============================================================

`include "test_defs.vh"

`define JTAG_CMD_FILE          "test.hex"

`define JTAG_BUF_BITS          10
`define JTAG_BUF_SIZE          (1 << `JTAG_BUF_BITS)

`define JTAG_CYCLES_PER_BIT    2
`define JTAG_CYCLES_PER_BYTE   (8 * `JTAG_CYCLES_PER_BIT)
`define JTAG_BYTES_PER_CMD     8

module jtag_drv(
               TDI,
               TCK,
               TCS,
               TDO,
               clk,
               nreset,
               done
);

output       TCK;
input        TDO;
output       TCS;
output       TDI;

input        clk;
input        nreset;

output       done;

reg [80*8:1] jtag_name;
reg    [7:0] mem [`JTAG_BUF_SIZE-1:0];
reg    [7:0] curr_byte;
reg   [15:0] rx_shift_reg;

integer      mem_addr;
integer      count;
integer      byte_count;
integer      bit_count;
integer      next_cmd_count;
integer      len;

reg          TCS;
reg          TCK;
reg          TDI;

reg          rd_cmd;
reg          reading;
reg          done;

initial
begin
  count      = -1;
  len        = 0;
  byte_count = 0;
  bit_count  = 0;
  TCS        = 1'b1;
  TCK        = 1'b0;
  rd_cmd     = 1'b0;
  done       = 1'b0;
  
  if (!$value$plusargs("JTAG_FILE=%s", jtag_name))
    jtag_name = `JTAG_CMD_FILE;
  
  // Load test vectors into the memory
  $readmemh(jtag_name, mem);
  
  // Get first command count
  next_cmd_count = (mem[0] << 24) | (mem[1] << 16) | (mem[2] << 8) | mem[3];
  
  // Get first length
  len            = mem[4];
  mem_addr       = 5;
 
end

always @(posedge clk)
begin
  count = count + 1;
  
  if (nreset == 1'b1 && done == 1'b0)
  begin
  
    if (count == next_cmd_count)
    begin
      // Activate the interface
      TCS            <= #`REGDEL 1'b0;
      
      // Get the next byte to transmit, and increment the address
      curr_byte      <= #`REGDEL mem[mem_addr];
      mem_addr       <= #`REGDEL mem_addr + 1;
      
      // Set the bit and byte counts for a command transfer
      byte_count     <= #`REGDEL len - 1;
      
      // Add an extra TCK on the first transfer to satisfy the receiver logic in the UUT.
      // Not sure why this is, but thats the way it works with the hardware.
      bit_count      <= #`REGDEL `JTAG_CYCLES_PER_BYTE + `JTAG_CYCLES_PER_BIT;
      
      // If starting a new command, and last was a read command
      // The flag this as a reading commnd
      if (rd_cmd)
      begin
        reading      <= #`REGDEL 1'b1;
        rd_cmd       <= #`REGDEL 1'b0;
      end
      else
      begin
        // Flag if this is a read cmd
        rd_cmd         <= #`REGDEL (mem[mem_addr] == 8'h94) ? 1'b1 : 1'b0;
      end
    end

    // Whilst active and just finished a byte transfer...
    if (TCS == 1'b0 && bit_count == 0 && byte_count != 0)
    begin
      // Decrement the byte count
      byte_count     <= #`REGDEL byte_count - 1;
      
      // Get the next byte.
      curr_byte      <= #`REGDEL mem[mem_addr];
      mem_addr       <= #`REGDEL mem_addr + 1;
      
      // Reset the bit count for the next byte transfer
      bit_count      <= #`REGDEL `JTAG_CYCLES_PER_BYTE;
    end    
    
    // If active and no more bits to send, get the next command time and 
    // deselect the interface    
    if (TCS == 1'b0 && bit_count == 0 && byte_count == 0)
    begin
      // Get the time for the next command, which is the current count plus command delta count
      next_cmd_count <= #`REGDEL(mem[mem_addr] << 24) | (mem[mem_addr+1] << 16) | (mem[mem_addr+2] << 8) | mem[mem_addr+3] +
                                 count;
      len            <= #`REGDEL mem[mem_addr+4];
      mem_addr       <= #`REGDEL mem_addr + 5;
      
      // Deactivate the interface
      TCS            <= #`REGDEL 1'b1;
      
      if (reading)
      begin
        reading      <= #`REGDEL 1'b0;
        //$display ("jtag_drv: Read word 0x%h", rx_shift_reg);
      end
      
      // If delta time is all 1s, then finish
      if ((mem[mem_addr] & mem[mem_addr+1] & mem[mem_addr+2] & mem[mem_addr+3]) == 8'hff)
      begin
        # 0 done = 1'b1;
      end
    end
    
    // If a byte transfer currently active...
    if (bit_count != 0)
    begin
    
      bit_count      <= #`REGDEL bit_count - 1;
             
      // If bit count odd, the set the TCK output
      if (bit_count & 1)
      begin
        TCK          <= 1'b1; // No delay for TCK, as this will clock the control/data outputs
      end
      // If bit count even, clear the TCK output and update the TDI with the next bit
      else
      begin
        TCK          <= 1'b0;
        TDI          <= #`REGDEL curr_byte[0];
        
        // Shift in the transmitted data
        rx_shift_reg <= #`REGDEL {TDO, rx_shift_reg[15:1]};
        
        if (bit_count <= 16)
          curr_byte  <= #`REGDEL {1'b0, curr_byte[7:1]};  
      end
    end
    else
    begin
      TCK            <= 1'b0;
    end
  end    
end

endmodule