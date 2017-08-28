//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 22nd May 2017
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
// $Id: usb_jtag_cmd.v,v 1.2 2017/07/07 06:07:00 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/rtl/usb_jtag_cmd.v,v $
//
//=============================================================

module usb_jtag_cmd (
                   iCLK,
                   iRST_n,

                   TDO,
                   TDI,
                   TCS,
                   TCK,

                   iSR_DATA, 
                   oSR_DATA,  
                   oSR_ADDR,  
                   oSR_WE_N,  
                   oSR_OE_N,  
                   oSR_Select,

                   iSDR_DATA,
                   iSDR_Done,
                   oSDR_ADDR,
                   oSDR_DATA,
                   oSDR_RD,
                   oSDR_WR,

                   oLED_GREEN,
                   oLED_RED,

                   iDIG,
                   oSEG0,
                   oSEG1,
                   oSEG2,
                   oSEG3
);

// Clocks and reset
input         iCLK;
input         iRST_n;

// JTAG
input         TCK;
input         TCS;
input         TDI;
output        TDO;

// LED
output  [9:0] oLED_RED;
output  [7:0] oLED_GREEN;

// SRAM
input  [15:0] iSR_DATA;
output [15:0] oSR_DATA;
output [17:0] oSR_ADDR;
output        oSR_OE_N;
output        oSR_WE_N;
output  [1:0] oSR_Select;

// SDRAM
input  [15:0] iSDR_DATA;
input         iSDR_Done;
output [21:0] oSDR_ADDR;
output [15:0] oSDR_DATA;
output        oSDR_RD;
output        oSDR_WR;

// 7-SE
input  [31:0] iDIG;
output  [6:0] oSEG0;
output  [6:0] oSEG1;
output  [6:0] oSEG2;
output  [6:0] oSEG3;

wire   [31:0] oSEG7_DIG;
       
wire    [7:0] mRXD_DATA;
wire    [7:0] mTXD_DATA;
wire          mRXD_Ready;
wire          mTXD_Done;
wire          mTXD_Start;

  // JTAG to synchronous byte interface bridge 
  USB_JTAG       u1 (// HOST
                     .iTxD_DATA       (mTXD_DATA),
                     .oTxD_Done       (mTXD_Done),
                     .iTxD_Start      (mTXD_Start),
                     .oRxD_DATA       (mRXD_DATA),
                     .oRxD_Ready      (mRXD_Ready),

                     // Control       
                     .iRST_n          (iRST_n),
                     .iCLK            (iCLK),

                     //JTAG           
                     .TDO             (TDO),
                     .TDI             (TDI),
                     .TCS             (TCS),
                     .TCK             (TCK)
                    );
  
  // Command decoder
  CMD_Decode     u2 (
                     // Control
                     .iCLK            (iCLK),
                     .iRST_n          (iRST_n),

                     // USB JTAG      
                     .iRXD_DATA       (mRXD_DATA),
                     .iRXD_Ready      (mRXD_Ready),
                     .oTXD_DATA       (mTXD_DATA),
                     .oTXD_Start      (mTXD_Start),
                     .iTXD_Done       (mTXD_Done),

                     // LED + SEG7    
                     .oLED_GREEN      (oLED_GREEN),
                     .oLED_RED        (oLED_RED),
                     .oSEG7_DIG       (oSEG7_DIG),
                     .iDIG            (iDIG),
  
                     // SRAM          
                     .iSR_DATA        (iSR_DATA),
                     .oSR_DATA        (oSR_DATA),
                     .oSR_ADDR        (oSR_ADDR),
                     .oSR_WE_N        (oSR_WE_N),
                     .oSR_OE_N        (oSR_OE_N),
                     .oSR_Select      (oSR_Select),
                     
                     // SDRAM
                     .oSDR_DATA       (oSDR_DATA),
                     .iSDR_DATA       (iSDR_DATA),
                     .oSDR_ADDR       (oSDR_ADDR),
                     .iSDR_Done       (iSDR_Done),
                     .oSDR_WR         (oSDR_WR),
                     .oSDR_RD         (oSDR_RD)
                    );
                    
  // Seven segment display encoder    
  SEG7_LUT_4     u3 (.oSEG0           (oSEG0),
                     .oSEG1           (oSEG1),
                     .oSEG2           (oSEG2),
                     .oSEG3           (oSEG3),
                     .iDIG            (iDIG)
                    );                    
endmodule