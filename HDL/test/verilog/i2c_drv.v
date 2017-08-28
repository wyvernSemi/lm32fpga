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
// $Id: i2c_drv.v,v 1.3 2017/06/29 18:40:04 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/i2c_drv.v,v $
//
//=============================================================

`include "test_defs.vh"

module i2c_drv (I2C_SCLK, I2C_SDAT);

input I2C_SCLK;
inout I2C_SDAT;

reg     [8:0] i2c_shift;
reg           i2c_ack;
reg           i2c_ack_negedge;
reg           i2c_got_addr;
reg     [3:0] i2c_count;

initial
begin
  i2c_got_addr    = 1'b0;
  i2c_count       = 0;
  i2c_ack         = 1'b1;
  i2c_ack_negedge = 1'b1;
end

  // Add a pullup on the I2C data line
  pullup    r1  (I2C_SDAT);

assign I2C_SDAT = i2c_ack_negedge ? 1'bz : 1'b0;

// -------------------------------------------------------------------------
// Start/Stop detection
// -------------------------------------------------------------------------
always @(I2C_SDAT)
begin
  // If DAT changed when CLK high, then a start or a stop
  if (I2C_SCLK == 1'b1)
  begin
    // If DAT falling edge, than start
    if (I2C_SDAT == 1'b0)
    begin
      i2c_count = 4'd9;
    end
    
    // DAT rising edge is a stop
    if (I2C_SDAT == 1'b1)
    begin
      i2c_count    = 4'd0;
      i2c_got_addr = 1'b0;
    end
  end
end

// -------------------------------------------------------------------------
// Receiver
// -------------------------------------------------------------------------
always @(posedge I2C_SCLK)
begin
  i2c_shift      <= #`REGDEL {i2c_shift[7:0], I2C_SDAT};
  i2c_count      <= #`REGDEL i2c_count - 4'd1;
  i2c_ack        <= #`REGDEL (i2c_count == 4'd2) ? 1'b0 : 1'b1;
  
  // Acknowledge cycle
  if (i2c_count == 4'd1)
  begin    
    // Reset count for another byte
    i2c_count    <= #`REGDEL 4'd9;
     
    if (i2c_got_addr == 1'b0)
    begin
      // Set 'got address', so only valid for first byte 
      i2c_got_addr <= #`REGDEL 1'b1;
      $display("i2c_drv: got address %h (RNW = %b)", i2c_shift[7:0], i2c_shift[0]);
    end
    else
    begin
      $display("i2c_drv: got byte    %h", i2c_shift[7:0]);
    end
  end
end

// -------------------------------------------------------------------------
// Make sure driving output signal only changes with I2C_SCLK low
// -------------------------------------------------------------------------
always @(negedge I2C_SCLK)
begin
  i2c_ack_negedge <= #`REGDEL i2c_ack;
end

endmodule
