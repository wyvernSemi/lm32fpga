//Legal Notice: (C)2006 Altera Corporation. All rights reserved. Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// Modifications Copryright (c) 2017 Simon Southwell. All rights reserved.

module SEG7_LUT (oSEG, iDIG);

input   [4:0]   iDIG;
output  [6:0]   oSEG;
reg     [6:0]   oSEG;

always @(iDIG)
begin
  case(iDIG)
  5'h00: oSEG = 7'b1000000;
  5'h01: oSEG = 7'b1111001;        // ---0----
  5'h02: oSEG = 7'b0100100;        // |      |
  5'h03: oSEG = 7'b0110000;        // 5      1
  5'h04: oSEG = 7'b0011001;        // |      |
  5'h05: oSEG = 7'b0010010;        // ---6----
  5'h06: oSEG = 7'b0000010;        // |      |
  5'h07: oSEG = 7'b1111000;        // 4      2
  5'h08: oSEG = 7'b0000000;        // |      |
  5'h09: oSEG = 7'b0010000;        // ---3----
  5'h0a: oSEG = 7'b0001000;
  5'h0b: oSEG = 7'b0000011;
  5'h0c: oSEG = 7'b1000110;
  5'h0d: oSEG = 7'b0100001;
  5'h0e: oSEG = 7'b0000110;
  5'h0f: oSEG = 7'b0001110;
  5'h10: oSEG = 7'b1111111; // OFF
  5'h11: oSEG = 7'b0001001; // H
  5'h12: oSEG = 7'b0001011; // ALT h
  5'h13: oSEG = 7'b0100011; // ALT o
  5'h14: oSEG = 7'b1000111; // L
  5'h15: oSEG = 7'b0001100; // P
  5'h16: oSEG = 7'b0000111; // t
  5'h17: oSEG = 7'b1100011; // u
  5'h18: oSEG = 7'b0010001; // y
  5'h19: oSEG = 7'b0111111; // dash (-)
  5'h1a: oSEG = 7'b0100000; // ALT a
  5'h1b: oSEG = 7'b0011100; // Degrees 
  5'h1c: oSEG = 7'b0100111; // ALT c
  5'h1d: oSEG = 7'b0101011; // n
  5'h1e: oSEG = 7'b0000100; // ALT e
  5'h1f: oSEG = 7'b0101111; // r
  endcase
end

endmodule
