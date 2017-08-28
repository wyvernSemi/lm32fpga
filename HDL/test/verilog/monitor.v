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
// $Id: monitor.v,v 1.4 2017/07/04 12:06:28 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/monitor.v,v $
//
//=============================================================
//
// Monitor of UUT ports connected, via TCP socket, to python GUI
// (if `DISABLE_PLI not defined). Currently monitors the green
// and red LED and seven segment display port, and the UART.
//
//=============================================================

`include "test_defs.vh"

// Command definitions for monitor PLI routines
// These must match the definitions in de1_pli.h
`define TCP_CMD_HEX            0
`define TCP_CMD_LEDR           1
`define TCP_CMD_LEDG           2

`define TIMEOUT_COUNT          2000000
`define RESETCYCLES            10

`define MON_BUFSIZE            16

`define LM32_TEST_PROG         "test_elf.hex"
`define LM32_BSS_DATA          "bss.hex"

`define RESULTS_ADDR           16'hfffc

module monitor (
              CLOCK_50,
              jtag_clk,
              nreset,
              
              jtag_done,
              
              PS2_CLK,
              PS2_DAT,
              
              txdata,
              txrdy,
              txack,
              rxdata,
              rxrdy,
              rxerr,

              HEX,
              LEDG,
              LEDR
              );

output        CLOCK_50;
output        jtag_clk;
output        nreset;
input         jtag_done;


output  [7:0] txdata;
output        txrdy;
input         txack;

input   [7:0] rxdata;
input         rxrdy; 
input         rxerr;

output        PS2_CLK;
output        PS2_DAT;

input  [27:0] HEX;
input   [7:0] LEDG;
input   [9:0] LEDR;

integer       count;
reg           nreset;
reg           CLOCK_50;
reg           jtag_clk;

reg    [27:0] HEX_last;
reg     [7:0] LEDG_last;
reg     [9:0] LEDR_last;

reg     [7:0] txdata;
reg           txrdy;

reg     [7:0] ipbuf [0:`MON_BUFSIZE-1];

reg  [80*8:1] prog_name;
reg  [80*8:1] bss_file;

integer       rxchar;
integer       do_finish;
integer       disable_gui;

integer       wptr;
integer       rptr;

wire          timeout       = (count >= `TIMEOUT_COUNT) ? 1'b1 : 1'b0;
wire          uart_inactive = ~rxrdy & ~txrdy;
wire          cpu_done      = LEDR[2];

// Flag when all interested parties have indicated that they are finished.
wire          all_done      = cpu_done & jtag_done & uart_inactive;

// Probe into UUT's UART to check RX ready to receive more data, to control
// input rate of user keyboard presses
wire lsr_dr_bit = test.UUT.u4.u_intface.lsr[0];
 
  // Pullups for open-collector signals
  pullup    r1  (PS2_CLK);
  pullup    r2  (PS2_DAT);

//-------------------------------------------------------------
// Create PLI call wrapper tasks to allow compilation with or 
// without the PLI code being included, but leaving the test
// code common to both circumstances.
//
task mon_de1init;
begin
`ifdef DISABLE_PLI
  // When no PLI, create dummy functionality to allow monitor to compile.
  $display("de1init dummy routine. PLI disabled.");
`else
  if (!disable_gui)
    $de1init();
`endif  
end
endtask

task mon_de1update;
input [31:0] cmd;
input [31:0] val;
begin
`ifdef DISABLE_PLI
  $display("de1update dummy routine. PLI disabled (cmd=%h val=%h).", cmd, val);
`else
  if (!disable_gui)
    $de1update(cmd, val);
`endif
end
endtask 

//-------------------------------------------------------------
// Initial block to load memory image and generate clocks
//-------------------------------------------------------------

initial
begin

  if (!$value$plusargs("FINISH=%d", do_finish))
    do_finish = 0;
    
  if (!$value$plusargs("DISABLE_GUI=%d", disable_gui))
    disable_gui = 0;
    
  if (!$value$plusargs("PROG_NAME=%s", prog_name))
    prog_name = `LM32_TEST_PROG;
    
  if (!$value$plusargs("BSS_FILE=%s", bss_file))
    bss_file = `LM32_BSS_DATA;

  count    = -1;
  nreset   = 1'b0;
  CLOCK_50 = 1'b1; 
  jtag_clk = 1'b1;
 
  mon_de1init();

`ifndef DISABLE_BSS_INIT
  // Load the SRAM with BSS data (so the CPU does not have to initialise)
  $readmemh(bss_file, test.sram.mem);
`endif  
  
  // Load the SRAM with the LM32 test program
  $readmemh(prog_name, test.sram.mem);
  
  // Generate the clocks for the UUT and the JTAG driver.
  fork
     forever #(`CLKPERIOD50  / 2) CLOCK_50 = ~CLOCK_50;
     forever #(`CLKPERIODJTAG/ 2) jtag_clk = ~jtag_clk;
  join   
end

//-------------------------------------------------------------
// Synchronously release nreset
//-------------------------------------------------------------

always @(posedge CLOCK_50)
begin
  if (count >= `RESETCYCLES)
  begin
    nreset <= #`REGDEL 1'b1;
  end
  
  // Keep a cycle count for debug purposes
  count = count + 1;
end

//-------------------------------------------------------------
// When all drivers finished or timed out, stop the simulation
//-------------------------------------------------------------

always @(posedge CLOCK_50 or negedge nreset)
begin
  if (nreset == 1'b1)
  begin
    if (all_done == 1'b1 || timeout == 1'b1)
    begin
      if (do_finish == 0)
        #0 $stop;
      else
        $display("RAM 0x%h = 0x%h%h%h%h", `RESULTS_ADDR,
                                          test.sram.mem[`RESULTS_ADDR], 
                                          test.sram.mem[`RESULTS_ADDR+1], 
                                          test.sram.mem[`RESULTS_ADDR+2], 
                                          test.sram.mem[`RESULTS_ADDR+3]);
        #0 $finish;
    end
  end
end

//-------------------------------------------------------------
// LED monitoring
//-------------------------------------------------------------

// Monitoring of inputs is done synchronously to avoid multiple
// calls to the update fuction if individual bits get updated 
// in different delta cycles for a single change
always @(posedge CLOCK_50)
begin
  // When not reset, check if the inputs change and call the de1update task
  // with this information.
  if (nreset)
  begin
    // Continually latch the current input values.
    HEX_last   <= HEX;
    LEDG_last  <= LEDG;
    LEDR_last  <= LEDR;

    // Update seven seg display on change of HEX
    if (HEX !== HEX_last)
    begin
      mon_de1update(`TCP_CMD_HEX, {4'h0, HEX});
    end

    // Update red LEDs on change of LEDR
    if (LEDR !== LEDR_last)
    begin
      mon_de1update(`TCP_CMD_LEDR, {22'h000000, LEDR});
    end
    
    // Update green LEDs on change of LEDG
    if (LEDG !== LEDG_last)
    begin
      mon_de1update(`TCP_CMD_LEDG, {24'h000000, LEDG});
    end    
  end    
end

//-------------------------------------------------------------
// UART monitoring
//-------------------------------------------------------------

// Receiving
always @(posedge CLOCK_50)
begin
  if (nreset == 1'b1)
  begin
    // If receiving a character....
    if (rxrdy == 1'b1)
    begin
      // If not in error, write character to screen
      if (rxerr == 1'b0)
      begin
        $de1putchar(rxdata);
      end
      // If flagged as an error display '?'
      else
      begin
        $de1putchar(32'h0000003f);
      end
    end
  end
end

// Transmitting
always @(posedge CLOCK_50)
begin
  if (nreset == 1'b0)
  begin
    txrdy      <= #`REGDEL 1'b0;
    wptr       <= #`REGDEL 0;
    rptr       <= #`REGDEL 0;
  end
  else
  begin
    // By default, if txrdy set, keep set until acknowledged
    txrdy      <= #`REGDEL txrdy & ~txack;
    
    // See if there is an input byte from the keyboard, over the PLI, and
    // put into the buffer if there is.
    rxchar    = $de1getchar();  
    if (rxchar != -1)
    begin
       //$display("got char: %c", rxchar);
       ipbuf[wptr % `MON_BUFSIZE] <= #`REGDEL rxchar;
       wptr                       <= #`REGDEL wptr + 1;
    end
    
    // If no active transfer, or just being acknowleged, then
    // if another UUT's input buffer is ready...
    if (lsr_dr_bit == 1'b0 && (txrdy == 1'b0 || txack == 1'b1) && rptr != wptr)
    begin
      //$display("sending %c", ipbuf[rptr % `MON_BUFSIZE]);
      txrdy  <= #`REGDEL 1'b1;
      txdata <= #`REGDEL ipbuf[rptr % `MON_BUFSIZE];
      rptr   <= #`REGDEL rptr + 1;
    end
  end
end

endmodule