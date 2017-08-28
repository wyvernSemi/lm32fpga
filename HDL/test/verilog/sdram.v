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
// $Id: sdram.v,v 1.2 2017/08/28 10:32:26 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/verilog/sdram.v,v $
//
//=============================================================
//
// Simple model of an 8MB SDRAM memory, arranged as 4 banks
// of 256 columns by 4096 rows and 16 bits wide. It does no 
// checking of valid timings, and any non-conforming input can
// have undefined results.
//
//=============================================================

`include "test_defs.vh"

// SDRAM commands
`define DESL                      20'b10100000000000000000
`define NOP                       20'b10011100000000000000
`define MRS                       20'b10000000000000000000
`define ACT                       20'b10001100000000000000
`define READ                      20'b10010100000000000000
`define READA                     20'b10010100010000000000
`define WRIT                      20'b10010000000000000000
`define WRITA                     20'b10010000010000000000
`define PRE                       20'b10001000000000000000
`define PALL                      20'b10001000010000000000
`define BST                       20'b10011000000000000000
`define REF                       20'b11000100000000000000
`define SELF                      20'b10000100000000000000

// CKE commands

`define CLK_SUSP_MODE_ENTRY       20'b10000000000000000000 /* state is Activating    */
`define CLK_SUSP                  20'b00000000000000000000 /* state is Any           */
`define CLK_SUSP_MODE_EXIT        20'b01000000000000000000 /* state is Clock suspend */
`define CLK_REF                   `REF                     /* state is Idle          */ 
`define CLK_SELF                  `SELF                    /* state is Idle          */
`define CLK_SELF_EXIT1            20'b01011100000000000000 /* state is Self refresh  */
`define CLK_SELF_EXIT2            20'b01100000000000000000 /* state is Self refresh  */
`define CLK_PWR_DOWN_ENTRY        20'b10000000000000000000 /* state is Idle          */
`define CLK_PWR_DOWN_EXIT         20'b01000000000000000000 /* State is Power down    */

// Masks for the above commands (some bits 'don't care')
`define MASK_DESL                 20'b10100000000000000000
`define MASK_NOP                  20'b10111100000000000000
`define MASK_MRS                  20'b10111111010000000000
`define MASK_ACT                  20'b10111100000000000000
`define MASK_READ                 20'b10111100010000000000
`define MASK_READA                20'b10111100010000000000
`define MASK_WRIT                 20'b10111100010000000000
`define MASK_WRITA                20'b11111100010000000000
`define MASK_PRE                  20'b10111100010000000000
`define MASK_PALL                 20'b10111100010000000000
`define MASK_BST                  20'b10111100000000000000
`define MASK_REF                  20'b11111100000000000000
`define MASK_SELF                 20'b11111100000000000000

`define MASK_CLK_SUSP_MODE_ENTRY  20'b11000000000000000000
`define MASK_CLK_SUSP             20'b11000000000000000000
`define MASK_CLK_SUSP_MODE_EXIT   20'b11000000000000000000
`define MASK_CLK_REF              `MASK_REF                    
`define MASK_CLK_SELF             `MASK_SELF                   
`define MASK_CLK_SELF_EXIT1       20'b11111100000000000000
`define MASK_CLK_SELF_EXIT2       20'b11100000000000000000
`define MASK_CLK_PWR_DOWN_ENTRY   20'b01000000000000000000
`define MASK_CLK_PWR_DOWN_EXIT    20'b01000000000000000000

// State machine state enumerations
`define STATE_PRE                 0
`define STATE_IDLE                1
`define STATE_SELF                2
`define STATE_REF                 3
`define STATE_MRS                 4
`define STATE_PWR_DOWN            5
`define STATE_ROW_ACTV            6
`define STATE_ACT_PWR_DOWN        7
`define STATE_WRITE               8
`define STATE_WRITE_SUSP          9
`define STATE_WRITEA              10
`define STATE_WRITEA_SUSP         11
`define STATE_READ                12
`define STATE_READ_SUSP           13
`define STATE_READA               14
`define STATE_READA_SUSP          15

//-------------------------------------------------------------
// Memory model module
//-------------------------------------------------------------

module sdram_1Mx16x4 (
                      inout  [15:0] DRAM_DQ,        // SDRAM Data bus 16 Bits
                      input  [11:0] DRAM_ADDR,      // SDRAM Address bus 12 Bits
                      input         DRAM_LDQM,      // SDRAM Low-byte Data Mask 
                      input         DRAM_UDQM,      // SDRAM High-byte Data Mask
                      input         DRAM_WE_N,      // SDRAM Write Enable
                      input         DRAM_CAS_N,     // SDRAM Column Address Strobe
                      input         DRAM_RAS_N,     // SDRAM Row Address Strobe
                      input         DRAM_CS_N,      // SDRAM Chip Select
                      input         DRAM_BA_0,      // SDRAM Bank Address 0
                      input         DRAM_BA_1,      // SDRAM Bank Address 0
                      input         DRAM_CLK,       // SDRAM Clock
                      input         DRAM_CKE        // SDRAM Clock Enable
);

parameter SDRAM_NUM_BANKS = 4;
parameter SDRAM_NUM_ROWS  = 4096;
parameter SDRAM_NUM_COLS  = 256;

//-------------------------------------------------------------
// Internal state (only updated when DRAM_CKE high
//-------------------------------------------------------------

// Memory: 2 bytes x 4 banks x 4K rows x 256 columns
reg    [15:0] mem [0:SDRAM_NUM_BANKS-1][0:SDRAM_NUM_ROWS-1][0:SDRAM_NUM_COLS-1];

// Registered version of inputs
reg    [15:0] dram_dq_reg;               // Registered DRAM_DQ input
reg    [13:0] dram_cas_addr_reg;         // Registered CAS addr, latched on DRAM_CAS_N and chip selected
reg    [11:0] dram_ras_addr_reg [0:3];   // Registered RAS addr for each bank, latched on DRAM_RAS_N and exit to row active state
reg     [1:0] dram_dqm_reg [0:2];        // Delay line of DRAM_xDQM inputs
reg           dram_we_n_reg;             // Registered DRAM_WE_N input, latched with CAS address
reg           cke_last;                  // Delayed version of DRAM_CKE

// Pipelined version of the cancel_transfer signal, to line up with read pipeline
reg     [2:0] cancel_tranfer_reg;

// Mode register
reg    [13:0] mode_reg;

// State machine state
integer state, next_state;

// Sequence counters
integer rd_count [0:3];
integer wr_count [0:3];

// General purpose integer
integer i;

//-------------------------------------------------------------
// Initial block
//-------------------------------------------------------------

// There is no reset input, so emulate a power up detector
// in this initial block to force the state machine and
// access sequencers to be in a power up state.
initial
begin
  // Force state to powerup value
  state                =  `STATE_PRE;
  
  // Clear access sequence counters
  for (i = 0; i < 4; i = i + 1)
  begin
    begin
      rd_count[i]      = 0;
      wr_count[i]      = 0;
    end
  end
end

//-------------------------------------------------------------
// Tasks and functions
//-------------------------------------------------------------

// Calculate the CAS address for the given start address, the 
// wrap type, the block length, and the current count in the
// sequence (counts down from BL to 1)
function [7:0] calc_addr;
input  [7:0] addr;
input  [8:0] bl;
input  [8:0] seq_count;
input        wrap_type;
reg    [8:0] mask;
reg    [8:0] count;
begin
  // Mask for the bottom log2(bl) bits
  mask  = bl - 1;
  
  // Create count that goes up from 0 to bl-1, as seq_count goes 
  // from bl down to 1;
  count = bl - seq_count;
  
  // Calculate the sequential address, clearing the bottom log2(bl)
  // bits, and adding the count to the start address, modulo bl.
  calc_addr = (addr & ~mask[7:0]) | ((addr + count[7:0]) & mask[7:0]);
  
  // If interleaving the sequential address is XORed with the
  // start address modulo bl to produce the pattern.
  if (wrap_type)
    calc_addr = calc_addr ^ (addr & mask[7:0]);
end
endfunction


//-------------------------------------------------------------
// Combinatorial logic
//-------------------------------------------------------------

// Bit blast mode register fields for convenience
wire [2:0] burst_length     =   mode_reg[2:0];
wire       wrap_type        =   mode_reg[3];  
wire [2:0] cas_latency      =   mode_reg[6:4];
wire       std_test_set     =   mode_reg[9:7] == 3'b001;
wire       single_write     =   mode_reg[9:7] == 3'b100;
wire       burst_write      = ~|mode_reg[13:7];
wire       full_page        =  ~wrap_type & (&burst_length);
 
// Calculate a decoded burst length 
wire [8:0] adj_bl           = full_page                ? 9'd256 : 
                              (burst_length == 3'b000) ? 9'd1   : 
                              (burst_length == 3'b001) ? 9'd2   :
                              (burst_length == 3'b010) ? 9'd4   :
                                                         9'd8;

// Amalgamate the inputs into a single command word.
wire [19:0] cmd             = {cke_last,  DRAM_CKE, 
                               DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N,
                               DRAM_BA_1, DRAM_BA_0,  DRAM_ADDR};

// Extract the active bank from the registered CAS address
wire  [1:0] active_bank     = dram_cas_addr_reg[13:12];

// Select the appropriate ras address latched when DRAM_RAS_N was low
wire [11:0] active_ras_addr = dram_ras_addr_reg[active_bank];

// Active CAS address is the last one latched when DRAM_CAS_N was low
wire  [7:0] active_cas_addr = dram_cas_addr_reg;

// Select the sequence counter for the active read/write bank
wire [31:0] active_counter  = dram_we_n_reg ? rd_count[active_bank] : 
                                              wr_count[active_bank];

// Flag when the active counter reaches a data portion of the sequence,
// i.e. when the count is active and equal to, or less than the burst length
wire        active_data_cyc = active_counter > 0 && active_counter <= adj_bl;

// Adjust the CAS address to sequence the burst as selected by the MRS 
// register's wrap type
wire  [7:0] adj_cas_addr    = calc_addr(active_cas_addr,
                                        adj_bl,
                                        active_counter[8:0],
                                        wrap_type);

// Fetch the word from the actively addressed location (used in both reads an writes
wire [15:0] active_rd_data  = mem [active_bank][active_ras_addr][adj_cas_addr[7:0]];

// Calculate when the SDRAM outputs should be active. I.e. when the delayed
// mask is high and an active read counter cycle.
wire  [1:0] dram_dq_oe      = ~dram_dqm_reg[2] & {2{active_data_cyc & dram_we_n_reg}};

// Extract the mask for writes
wire  [1:0] dram_wr_mask    = dram_dqm_reg[0];

// Drive the data output on active read cycles only
assign DRAM_DQ              = {dram_dq_oe[1] ? active_rd_data[15:8] : 8'hzz,
                               dram_dq_oe[0] ? active_rd_data [7:0] : 8'hzz};

// TRansfers are to be cancelled when access or precharge commands arrive
wire cancel_tranfer         = ((cmd & `MASK_WRIT) == `WRIT || (cmd & `MASK_WRITA) == `WRITA || 
                               (cmd & `MASK_READ) == `READ || (cmd * `MASK_READA) == `READA || 
                               (cmd & `MASK_PRE)  == `PRE);

// Write will be cancelled immediately                               
wire cancel_wr              = cancel_tranfer;

// Reads will be cancelled after the CAS latency.
wire cancel_rd              = cancel_tranfer_reg[cas_latency[1:0] - 2'b01];

//-------------------------------------------------------------
// Update internal state
//-------------------------------------------------------------
                  
always @(posedge DRAM_CLK)
begin
  // Register the DQ and CKE inputs, unqualified 
  dram_dq_reg             <= DRAM_DQ;
  cke_last                <= DRAM_CKE;
  cancel_tranfer_reg      <= {cancel_tranfer_reg[1:0], cancel_tranfer};
  
  // Update rest of state only if the clock is enabled
  if (DRAM_CKE)
  begin
    // Update state machine
    state                 <= next_state; 

    // Register DQM signals
    dram_dqm_reg[0]       <= {DRAM_UDQM, DRAM_LDQM};
    
    // Create delayed mask signals for pipeline
    dram_dqm_reg[1]       <= dram_dqm_reg[0];
    dram_dqm_reg[2]       <= dram_dqm_reg[1];
   
    // Process command input only when chip selected
    if (DRAM_CS_N == 1'b0)
    begin
    
      // Latch the CAS address, bank selects and WE_N pins whenever CAS_N active
      if (DRAM_CAS_N == 1'b0)
      begin
        dram_cas_addr_reg <= {DRAM_BA_1, DRAM_BA_0, DRAM_ADDR};
        dram_we_n_reg     <= DRAM_WE_N;
      end

      // Latch the address inputs to selected register (indexed by BA{1:0]),
      // whenever RAS_N active, and entering ROW_ACTV state
      if (DRAM_RAS_N == 1'b0 && next_state == `STATE_ROW_ACTV)
      begin
        dram_ras_addr_reg[{DRAM_BA_1, DRAM_BA_0}] <= DRAM_ADDR;
      end
    end

    // Update memory only on an active write cycle
    if (~dram_we_n_reg & active_data_cyc)
    begin
      mem [active_bank][active_ras_addr][adj_cas_addr[7:0]] <= 
            {dram_wr_mask[1] ? active_rd_data[15:8] : dram_dq_reg[15:8],
             dram_wr_mask[0] ? active_rd_data [7:0] : dram_dq_reg [7:0]};
    end    
    
    // Process data transfer sequences, by decrementing 
    // any non-zero counter---could be overidden in 
    // subsequenct code.
    for (i = 0; i < 4; i = i + 1)
    begin
      rd_count[i]         <= rd_count[i] ? (rd_count[i] - 1) : 0;
      wr_count[i]         <= wr_count[i] ? (wr_count[i] - 1) : 0;
    end
    
    // Can only process read/write commands (and precharge termination)
    // when entering (or re-entering) these row activation, data access, 
    // or precharge states 
    if (next_state == `STATE_ROW_ACTV ||
        next_state == `STATE_WRITE    ||
        next_state == `STATE_WRITEA   ||
        next_state == `STATE_READ     ||
        next_state == `STATE_READA    ||
        next_state == `STATE_PRE      ||
        next_state == `STATE_IDLE)
    begin 
      // Cancel any outstanding write on receipt of a new access command, or precharge
      if (cancel_wr)
      begin
        for (i = 0; i < 4; i = i + 1)
        begin
          wr_count[i]     <= 0;
        end
      end
      
      // Cancel any outstanding read on receipt of a new access command, or precharge,
      // pipelined for cas latency
      if (cancel_rd)
      begin
        for (i = 0; i < 4; i = i + 1)
        begin
          rd_count[i]     <= 0;
        end
      end
      
      // Start a new write access to addressed bank
      if ((cmd & `MASK_WRIT) == `WRIT || (cmd & `MASK_WRITA) == `WRITA)
      begin
        wr_count[{DRAM_BA_1, DRAM_BA_0}] <= adj_bl;
      end
      // Start a new read accesses to addressed block
      else if ((cmd & `MASK_READ) == `READ || (cmd & `MASK_READA) == `READA)
      begin
        rd_count[{DRAM_BA_1, DRAM_BA_0}] <= cas_latency - 1 + adj_bl;
      end
    end
    
    // Latch the MRS register when in MRS state
    if (next_state == `STATE_MRS)
    begin
      mode_reg            <= {DRAM_BA_1, DRAM_BA_0, DRAM_ADDR};
    end
  end
end

//-------------------------------------------------------------
// SDRAM state machine
//-------------------------------------------------------------

always @(*)
begin

  // Make default next state to remain in current state
  next_state <= state;
  
  case(state)
  `STATE_PRE         :
  begin
    next_state <= `STATE_IDLE;
  end
  
  `STATE_IDLE        :
  begin
    if (cmd == `SELF)
      next_state <= `STATE_SELF;
    else if ((cmd & `MASK_MRS) == `MRS)
      next_state <= `STATE_MRS;
    else if ((cmd & `MASK_REF) == `REF)
      next_state <= `STATE_REF;
    else if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_PWR_DOWN;
    else if ((cmd & `MASK_ACT) == `ACT)
      next_state <= `STATE_ROW_ACTV;    
  end
  
  `STATE_SELF        :
  begin
    if ((cmd & `MASK_CLK_SELF_EXIT1) == `CLK_SELF_EXIT1 || 
        (cmd & `MASK_CLK_SELF_EXIT2) == `CLK_SELF_EXIT2)
      next_state <= `STATE_IDLE;
  end
  
  `STATE_REF         :
  begin
    next_state <= `STATE_PRE;
  end
  
  `STATE_MRS         :
   begin
     next_state <= `STATE_IDLE;
   end
   
  `STATE_PWR_DOWN    :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_IDLE;
  end
  
  `STATE_ROW_ACTV    :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_ACT_PWR_DOWN;
    else if ((cmd & `MASK_WRIT) == `WRIT)
      next_state <= `STATE_WRITE;
    else if ((cmd & `MASK_WRITA) == `WRITA)
      next_state <= `STATE_WRITEA;
    else if ((cmd & `MASK_READ) == `READ)
      next_state <= `STATE_READ;
    else if ((cmd & `MASK_READA) == `READA)
      next_state <= `STATE_READA;
  end
  
  `STATE_ACT_PWR_DOWN:
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_ROW_ACTV;
  end
   
  `STATE_WRITE       :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_WRITE_SUSP;
    else if ((cmd  & `MASK_BST) == `BST)
      next_state <= `STATE_ROW_ACTV;
    else if ((cmd  & `MASK_WRITA) == `WRITA)
      next_state <= `STATE_WRITEA;
    else if ((cmd  & `MASK_PRE) == `PRE)
      next_state <= `STATE_PRE;
    if ((cmd  & `MASK_WRIT) == `WRIT)
      next_state <= `STATE_WRITE;
    else if ((cmd  & `MASK_READ) == `READ)
      next_state <= `STATE_READ;
    else if ((cmd  & `MASK_READA) == `READA)
      next_state <= `STATE_READA;
  end
  
  `STATE_READ        :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_READ_SUSP;
    else if ((cmd & `MASK_BST) == `BST)
      next_state <= `STATE_ROW_ACTV;
    else if ((cmd & `MASK_WRITA) == `WRITA)
      next_state <= `STATE_WRITEA;
    else if ((cmd & `MASK_PRE) == `PRE)
      next_state <= `STATE_PRE;
    else if ((cmd & `MASK_WRIT) == `WRIT)
      next_state <= `STATE_WRITE;
    else if ((cmd & `MASK_READ) == `READ)
      next_state <= `STATE_READ;
    else if ((cmd & `MASK_READA) == `READA)
      next_state <= `STATE_READA;
  end
  
  `STATE_WRITEA      :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_WRITEA_SUSP;
    else
      next_state <= `STATE_PRE;
  end
  
  `STATE_READA       :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_ENTRY) == `CLK_PWR_DOWN_ENTRY)
      next_state <= `STATE_READA_SUSP;
    else
      next_state <= `STATE_PRE;
  end

  `STATE_WRITE_SUSP  :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `MASK_CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_WRITE;
  end

  `STATE_WRITEA_SUSP :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `MASK_CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_WRITEA;
  end

  `STATE_READ_SUSP   :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `MASK_CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_READ;
  end

  `STATE_READA_SUSP  :
  begin
    if ((cmd & `MASK_CLK_PWR_DOWN_EXIT) == `MASK_CLK_PWR_DOWN_EXIT)
      next_state <= `STATE_READA;
  end
  endcase
end

endmodule