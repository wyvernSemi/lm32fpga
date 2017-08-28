//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 10th June 2017
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
// $Id: uart_drv.v,v 1.2 2017/06/29 14:26:58 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/uart_drv.v,v $
//
//=============================================================
//
// Simple UART driver.
//
//=============================================================

`include "test_defs.vh"

module uart_drv (clk,    nreset, rx,    tx, 
                 rxdata, rxrdy,  rxerr,
                 txdata, txrdy,  txack);

//-------------------------------------------------------------
// Parameters
//-------------------------------------------------------------
                 
// User overridable parameters
parameter clk_period_ns = `CLKPERIOD50/`NANOSECOND;
parameter baud_rate     = `TEST_BAUDRATE;
parameter stop_bits     = 1;
parameter data_bits     = 8;
parameter parity_bit    = 0;
parameter parity_odd    = 0;

// Derived parameters
parameter  clks_per_bit = (`MILLISECOND/clk_period_ns)/baud_rate;

//-------------------------------------------------------------
// Port declarations
//-------------------------------------------------------------

input          clk;
input          nreset;
input          rx;
output         tx;

input    [7:0] txdata;
input          txrdy;
output         txack;

output   [7:0] rxdata;
output         rxrdy; 
output         rxerr;

//-------------------------------------------------------------
// Internal state
//-------------------------------------------------------------

reg      [7:0] rxdata;
reg            rxrdy;
reg            txack;
reg            txack_last;

reg      [7:0] rx_shift;
reg            last_rx;
reg            rxerr;

reg            last_txrdy;
reg      [7:0] txdata_reg;
reg            txdata_par_reg;
reg      [3:0] txidx;

reg      [3:0] rx_bit_count;
integer        rx_dly_count;
reg      [3:0] tx_bit_count;
integer        tx_dly_count;

//-------------------------------------------------------------
// Combinatorial logic
//-------------------------------------------------------------

// RX shift register is LSB first
wire     [7:0] next_rx_shift = {rx, rx_shift[7:1]};

// Create appropriate wide tx data with start bit (1'b0), data, optional parity
// and stop bits, right justified to index from 0 to n (LSB first). Blanks are 
// filled with 1'b1 for stop bit(s).
wire    [11:0] tx_data       = {2'b11, parity_bit ? {txdata_par_reg, txdata_reg} : {1'b1, txdata_reg}, 1'b0};

// TX output is as per index into tx_data
assign      tx               = tx_data[txidx];               

//-------------------------------------------------------------
// Receiver logic
//-------------------------------------------------------------

always @(posedge clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    rx_bit_count          <= 4'h0;
    rx_dly_count          <= 4'h0;
    last_rx               <= 1'b1;
    rxrdy                 <= 1'b0;
    rxerr                 <= 1'b0;
  end
  else
  begin
    rxrdy                 <= 1'b0;
    last_rx               <= rx;
    rx_dly_count          <= rx_dly_count - ((rx_dly_count != 4'h0) ? 1 : 0);
    
    // Start bit detected
    if (rx == 1'b0 && last_rx == 1'b1 && rx_bit_count == 4'h0 && rx_dly_count == 4'h0)
    begin
       // Set the bit counter to count data all bits, including parity.
       rx_bit_count       <= data_bits + parity_bit;
       
       // First delay count if for half of the period
       rx_dly_count       <= clks_per_bit + clks_per_bit/2;
    end
    
    // If the delay count is at the end of the count...
    if (rx_dly_count == 4'h1)
    begin
      // If the bits still to be processed...
      if (rx_bit_count != 0)
      begin
        // Decrement the bit count for this bit
        rx_bit_count      <= rx_bit_count - 4'h1;
        
        // Reset the bit delay for a whole bit period, plus 1 to compensate
        // for the delay count being at 1 now, rather than 0.
        rx_dly_count      <= clks_per_bit + 1;
        
        // Sample the RX data and shift in.
        rx_shift          <= next_rx_shift;
        
        // When at the last data bit, display the received character
        if (rx_bit_count == parity_bit+1)
        begin
          rxrdy           <= 1'b1;
          rxdata          <= next_rx_shift;
        end
        
        // If a parity bit, and at the last bit, check the parity
        if (parity_bit == 1 && rx_bit_count == 4'h1)
        begin
          if (^rx_shift[7:0] != (parity_odd ? 1'b1 : 1'b0))
          begin
            $display("UART: ***ERROR parity failed");
            rxerr         <= 1'b1;
          end
        end
      end
    end   
  end
end
  
//-------------------------------------------------------------  
// Transmission logic
//-------------------------------------------------------------

always @(posedge clk or negedge nreset)
begin
  if (nreset == 1'b0)
  begin
    txack                 <= 1'b0;
    txack_last            <= 1'b0;
    tx_bit_count          <= 4'h0;
    tx_dly_count          <= 4'h0;
    txidx                 <= 4'd11; // Point to top stop bit by default.
  end
  else
  begin
    last_txrdy            <= txrdy;
    txack                 <= 1'b0;
    txack_last            <= txack;
    
    tx_dly_count          <= tx_dly_count - ((tx_dly_count != 0) ? 1 : 0);
    
    // Start of transmission (txrdy goes from 0 to 1, or acknowledged last cycle
    // and txrdy active, for back to back transmissions.
    if ((txrdy == 1'b1 && last_txrdy == 1'b0) || (txrdy == 1'b1 && txack_last == 1'b1))
    begin
      txdata_reg          <= txdata;
      txdata_par_reg      <= (^txdata) ^ (parity_odd ? 1'b0 : 1'b1);
      tx_bit_count        <= 1 + data_bits + parity_bit + stop_bits;
      tx_dly_count        <= clks_per_bit;
      txidx               <= 0;
    end
    
    // Active transmission
    if (tx_bit_count != 4'h0 && tx_dly_count == 4'h1)
    begin
      tx_bit_count        <= tx_bit_count - 4'h1;
      txidx               <= txidx        + 4'h1;
      tx_dly_count        <= clks_per_bit;
    end
    
    // Last cycle of transmission
    if (tx_bit_count == 4'h1 && tx_dly_count == 1)
    begin
      txack               <= 1'b1;
    end
  end 
end

endmodule


