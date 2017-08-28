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

//////////////////      Command Action  /////////////////////
parameter SETUP   = 8'h61;
parameter ERASE   = 8'h72;
parameter WRITE   = 8'h83;
parameter READ    = 8'h94;
parameter LCD_DAT = 8'ha5;
parameter LCD_CMD = 8'hb6;
//////////////////      Command Target  /////////////////////
parameter LED     = 8'hF0;
parameter SEG7    = 8'hE1;
parameter PS2     = 8'hD2;
parameter FLASH   = 8'hC3;
parameter SDRAM   = 8'hB4;
parameter SRAM    = 8'hA5;
parameter LCD     = 8'h96;
parameter VGA     = 8'h87;
parameter SDRSEL  = 8'h1F;
parameter FLSEL   = 8'h2E;
parameter EXTIO   = 8'h3D;
parameter SET_REG = 8'h4C;
parameter SRSEL   = 8'h5B;
//////////////////      Command Mode    /////////////////////
parameter OUTSEL  = 8'h33;
parameter NORMAL  = 8'hAA;
parameter DISPLAY = 8'hCC;
parameter BURST   = 8'hFF;