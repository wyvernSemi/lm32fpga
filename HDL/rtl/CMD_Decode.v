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

module CMD_Decode(
  // USB JTAG
  iRXD_DATA, oTXD_DATA, iRXD_Ready, iTXD_Done, oTXD_Start,

  // LED
  oLED_RED,oLED_GREEN,

  // 7-SEG
  oSEG7_DIG, iDIG,

  // VGA
  oOSD_CUR_EN, oCursor_X, oCursor_Y,
  oCursor_R,   oCursor_G, oCursor_B,

  // FLASH
  oFL_DATA, iFL_DATA, oFL_ADDR, iFL_Ready, oFL_Start, oFL_CMD,

  // SDRAM
  oSDR_DATA, iSDR_DATA, oSDR_ADDR, iSDR_Done, oSDR_WR, oSDR_RD,

  // SRAM
  oSR_DATA, iSR_DATA, oSR_ADDR, oSR_WE_N, oSR_OE_N,

  // PS2
  iPS2_ScanCode, iPS2_Ready,

  // Async Port Select
  oSDR_Select, oFL_Select, oSR_Select,

  // Control
  iCLK, iRST_n
);

// Include paramater definitions
`include "RS232_Command.vh"
`include "Flash_Command.vh"


// USB JTAG
input       [7:0] iRXD_DATA;
input             iRXD_Ready, iTXD_Done;
output      [7:0] oTXD_DATA;
output            oTXD_Start;

// LED
output reg  [9:0] oLED_RED;
output reg  [7:0] oLED_GREEN;

// 7-SEG
output reg [31:0] oSEG7_DIG;
input      [31:0] iDIG;

// VGA
output reg  [9:0] oCursor_X;
output reg  [9:0] oCursor_Y;
output reg  [9:0] oCursor_R;
output reg  [9:0] oCursor_G;
output reg  [9:0] oCursor_B;
output reg  [1:0] oOSD_CUR_EN;

// FLASH
input       [7:0] iFL_DATA;
input             iFL_Ready;
output reg [21:0] oFL_ADDR;
output reg  [7:0] oFL_DATA;
output reg  [2:0] oFL_CMD;
output reg        oFL_Start;

// SDRAM
input      [15:0] iSDR_DATA;
input             iSDR_Done;
output reg [21:0] oSDR_ADDR;
output reg [15:0] oSDR_DATA;
output            oSDR_RD;
output            oSDR_WR;

// SRAM
input      [15:0] iSR_DATA;
output reg [15:0] oSR_DATA;
output reg [17:0] oSR_ADDR;
output            oSR_OE_N;
output            oSR_WE_N;

// PS2
input       [7:0] iPS2_ScanCode;
input             iPS2_Ready;

// Async Port Select
output reg  [1:0] oSDR_Select;
output reg  [1:0] oFL_Select;
output reg  [1:0] oSR_Select;

// Control
input iCLK;
input iRST_n;

// Internal Register
reg [63:0] CMD_Tmp;
reg  [2:0] mFL_ST, mSDR_ST, mPS2_ST, mSR_ST, mLCD_ST, mSEG7_ST;

// SDRAM Control Register
reg        mSDR_WRn, mSDR_Start;

// SRAM Control Register
reg        mSR_WRn, mSR_Start;

// Active Flag
reg        f_SETUP, f_LED,   f_SEG7, f_SDR_SEL, f_FL_SEL, f_SR_SEL;
reg        f_FLASH, f_SDRAM, f_PS2,  f_SRAM,    f_VGA;
reg        active_last;

// USB JTAG TXD Output
reg        oFL_TXD_Start, oSDR_TXD_Start, oPS2_TXD_Start, oSR_TXD_Start, oSEG7_TXD_Start;
reg  [7:0] oFL_TXD_DATA,  oSDR_TXD_DATA,  oPS2_TXD_DATA,  oSR_TXD_DATA;

// TXD Output Select Register
reg        sel_FL, sel_SDR, sel_PS2, sel_SR, sel_SEG7;


wire [7:0]  CMD_Action  = CMD_Tmp[63:56];
wire [7:0]  CMD_Target  = CMD_Tmp[55:48];
wire [23:0] CMD_ADDR    = CMD_Tmp[47:24];
wire [15:0] CMD_DATA    = CMD_Tmp[23: 8];
wire [7:0]  CMD_MODE    = CMD_Tmp[ 7: 0];

wire [7:0]  Pre_Target  = CMD_Tmp[47:40];

wire        active         = f_SETUP | f_LED   | f_SEG7 | f_SDR_SEL | f_FL_SEL | f_SR_SEL |
                             f_FLASH | f_SDRAM | f_PS2  | f_SRAM    | f_VGA;
wire        going_inactive = active_last & ~active;


assign oTXD_Start = sel_FL   ? oFL_TXD_Start   :
                    sel_SDR  ? oSDR_TXD_Start  :
                    sel_SR   ? oSR_TXD_Start   :
                    sel_SEG7 ? oSEG7_TXD_Start :
                               oPS2_TXD_Start;

assign oTXD_DATA  = sel_FL   ? oFL_TXD_DATA   :
                    sel_SDR  ? oSDR_TXD_DATA  :
                    sel_SR   ? oSR_TXD_DATA   :
                    sel_SEG7 ? oSEG7_DIG[7:0] :
                               oPS2_TXD_DATA;

/////////////////////////////////////////////////////////
////////////////   Async Source Select      /////////////
always @(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oSDR_Select <= 2'b00;
    oFL_Select  <= 2'b00;
    oSR_Select  <= 2'b00;
    
    f_SDR_SEL   <= 1'b0;
    f_FL_SEL    <= 1'b0;
    f_SR_SEL    <= 1'b0;
  end
  else
  begin
    if (iRXD_Ready == 1'b1)
    begin
      case (Pre_Target)
      SDRSEL : begin f_SDR_SEL <= 1'b1; end
      FLSEL  : begin f_FL_SEL  <= 1'b1; end
      SRSEL  : begin f_SR_SEL  <= 1'b1; end
      endcase
    end
    
    if ((CMD_Action == SETUP) && (CMD_MODE == OUTSEL) && (CMD_ADDR == 24'h123456))
    begin
      if (f_SDR_SEL)
      begin
        oSDR_Select <= CMD_DATA[1:0];
      end
      else if (f_FL_SEL)
      begin
        oFL_Select  <= CMD_DATA[1:0];
      end
      else if (f_SR_SEL)
      begin
        oSR_Select  <= CMD_DATA[1:0];
      end
    end
    
    if (f_SDR_SEL)  
    begin    
      f_SDR_SEL     <= 1'b0;
    end
      
    if (f_FL_SEL)
    begin
      f_FL_SEL      <= 1'b0;
    end
      
    if (f_SR_SEL)
    begin
      f_SR_SEL      <= 1'b0;
    end
  end
end

/////////////////////////////////////////////////////////
/////////////////   TXD  Output Select      /////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    sel_FL   <= 1'b0;
    sel_SDR  <= 1'b0;
    sel_PS2  <= 1'b0;
    sel_SR   <= 1'b0;
    sel_SEG7 <= 1'b0;
    f_SETUP  <= 1'b0;
  end
  else
  begin
    if (iRXD_Ready && (Pre_Target == SET_REG))
    begin
      f_SETUP<=1;
    end

    if (f_SETUP)
    begin
    
      if ((CMD_Action == SETUP) && (CMD_MODE == OUTSEL) && (CMD_ADDR == 24'h123456))
      begin
        sel_FL   <= 1'b0;
        sel_SDR  <= 1'b0;
        sel_PS2  <= 1'b0;
        sel_SR   <= 1'b0;
        sel_SEG7 <= 1'b0; 
         
        case(CMD_DATA[7:0])
        FLASH:
        begin
          sel_FL   <= 1'b1;
        end
        SDRAM:
        begin
          sel_SDR  <= 1'b1;
        end
        PS2:
        begin
          sel_PS2  <= 1'b1;
        end
        SRAM:
        begin
          sel_SR   <= 1'b1;
        end
        SEG7:
        begin
          sel_SEG7 <= 1'b1;
        end
        endcase
      end

      f_SETUP <= 0;
    end
  end
end
                        
/////////////////////////////////////////////////////////
///////    Shift Register For Command Temp  /////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    CMD_Tmp <= {64{1'b0}};
    active_last <= 1'b0;
  end
  else
  begin
    active_last <= active;
    if (iRXD_Ready)
    begin
      CMD_Tmp <= {CMD_Tmp[55:0], iRXD_DATA};
    end
    else if (going_inactive)
    begin
      CMD_Tmp <= {64{1'b0}};
    end
  end
end

/////////////////////////////////////////////////////////
////////////////     LED Control    /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oLED_RED   <= {10{1'b0}};
    oLED_GREEN <= {8{1'b0}};
    f_LED      <= 1'b0;
  end
  else
  begin
    if (iRXD_Ready && (Pre_Target == LED))
    begin
      f_LED <= 1'b1;
    end

    if (f_LED)
    begin
      if ((CMD_Action == WRITE) && (CMD_MODE == DISPLAY))
      begin
        oLED_RED   <= CMD_ADDR[9:0];
        oLED_GREEN <= CMD_DATA[7:0];
      end

      f_LED <= 1'b0;
    end
  end
end

/////////////////////////////////////////////////////////
////////////////    7-SEG Control   /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oSEG7_DIG               <= {32{1'b0}};
    f_SEG7                  <= 1'b0;
    oSEG7_TXD_Start         <= 1'b0;
    mSEG7_ST                <= 3'b000;
  end
  else
  begin
    if (iRXD_Ready && (Pre_Target == SEG7) )
    begin
      f_SEG7                <= 1'b1;
    end

    if (f_SEG7)
    begin
      if ((CMD_Action == WRITE) && (CMD_MODE == DISPLAY))
      begin
        oSEG7_DIG           <= {CMD_ADDR[15:0], CMD_DATA};
        f_SEG7              <= 1'b0;
      end
      else if ((CMD_Action == READ) && (CMD_MODE == NORMAL))
      begin
        case(mSEG7_ST)
        3'b000:
        begin
          oSEG7_TXD_Start   <= 1'b1;
          oSEG7_DIG         <= iDIG;
          mSEG7_ST          <= 3'b001;
        end
        3'b001:
        begin
          if(iTXD_Done)
          begin
            oSEG7_TXD_Start <= 1'b0;
            mSEG7_ST        <= 3'b010;
          end
        end
        3'b010:
        begin
          oSEG7_TXD_Start   <= 1'b1;
          oSEG7_DIG         <= {8'h00, iDIG[31:8]};
          mSEG7_ST          <= 3'b011;
        end
        3'b011:
        begin
          if(iTXD_Done)
          begin
            oSEG7_TXD_Start <= 1'b0;
            mSEG7_ST        <= 3'b000;
            f_SEG7          <= 1'b0;
          end
        end
        endcase
      end
      else
      begin
        f_SEG7              <= 1'b0;
      end      
    end
  end
end

/////////////////////////////////////////////////////////
////////////////    Flash Control   /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if(!iRST_n)
  begin
    oFL_TXD_Start <= 1'b0;
    oFL_Start     <= 1'b0;
    f_FLASH       <= 1'b0;
    mFL_ST        <= 3'b000;
  end
  else
  begin
    if (CMD_Action == READ)
    begin
      oFL_CMD <= CMD_READ;
    end
    else if (CMD_Action == WRITE)
    begin
      oFL_CMD <= CMD_WRITE;
    end
    else if (CMD_Action == ERASE)
    begin
      oFL_CMD <= CMD_CHP_ERA;
    end
    else
    begin
      oFL_CMD <= 3'b000;
    end
                
    if (iRXD_Ready && (Pre_Target == FLASH))
    begin
      f_FLASH <= 1'b1;
    end

    if (f_FLASH)
    begin
      case(mFL_ST)
      3'b000:
      begin
        if ((CMD_MODE == NORMAL) && (CMD_Target == FLASH) && (CMD_DATA[15:8] == 8'hFF))
        begin
          oFL_ADDR  <= CMD_ADDR[21:0];
          oFL_DATA  <= CMD_DATA[7:0];
          oFL_Start <= 1'b1;
          mFL_ST    <= 3'b001;
        end
        else
        begin
          mFL_ST    <= 3'b000;
          f_FLASH   <= 1'b0;
        end
      end     

      3'b001:
      begin
        if (iFL_Ready)
        begin
          mFL_ST    <= 3'b010;
          oFL_Start <= 1'b0;
        end     
      end

      3'b010:
      begin
        oFL_Start   <= 1'b1;
        mFL_ST      <= 3'b011;
      end
      
      3'b011:
      begin
        if (iFL_Ready)
        begin
          mFL_ST    <= 3'b100;
          oFL_Start <= 1'b0;
        end     
      end

      3'b100:
      begin
        oFL_Start   <= 1'b1;
        mFL_ST      <= 3'b101;
      end

      3'b101:
      begin
        if (iFL_Ready)
        begin
          if (oFL_CMD == CMD_READ)
          begin
            mFL_ST   <= 3'b110;
          end
          else
          begin
            mFL_ST   <= 3'b000;
            f_FLASH  <= 1'b0;                                                      
          end
          oFL_Start  <= 1'b0;
        end                             
      end

      3'b110:
      begin
        oFL_TXD_DATA  <= iFL_DATA;
        oFL_TXD_Start <= 1'b1;
        mFL_ST        <= 3'b111;
      end

      3'b111:
      begin
        if (iTXD_Done)
        begin
          oFL_TXD_Start <= 1'b0;
          mFL_ST        <= 3'b000;
          f_FLASH       <= 1'b0;
        end
      end
      endcase
    end
  end
end

/////////////////////////////////////////////////////////
/////////////////   PS2 Control     /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oPS2_TXD_Start <= 1'b0;
    f_PS2          <= 1'b0;
    mPS2_ST        <= 3'b000;
  end
  else
  begin
    if (iPS2_Ready && iPS2_ScanCode!=8'h2e)
    begin
      f_PS2         <= 1'b1;
      oPS2_TXD_DATA <= iPS2_ScanCode;
    end

    if (f_PS2)
    begin
      case(mPS2_ST)
      3'b000:
      begin
        oPS2_TXD_Start <= 1'b1;
        mPS2_ST        <= 1'b1;
      end

      3'b001:
      begin
        if(iTXD_Done)
        begin
          oPS2_TXD_Start <= 1'b0;
          mPS2_ST        <= 3'b000;
          f_PS2          <= 1'b0;
        end
      end
      endcase
    end
  end
end

reg [15:0] SDR_DATA_reg;

/////////////////////////////////////////////////////////
////////////////    Sdram Control   /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oSDR_TXD_Start <= 1'b0;
    mSDR_WRn       <= 1'b0;
    mSDR_Start     <= 1'b0;
    f_SDRAM        <= 1'b0;
    mSDR_ST        <= 3'b000;
    oSDR_ADDR      <= 22'h000000;
  end
  else
  begin
    if (CMD_Action == READ)
    begin
      mSDR_WRn     <= 1'b0;
    end
    else if( CMD_Action == WRITE )
    begin
      mSDR_WRn     <=      1'b1;
    end
                
    if (iRXD_Ready && (Pre_Target == SDRAM))
    begin
      f_SDRAM <= 1'b1;
    end

    if (f_SDRAM)
    begin
      case(mSDR_ST)
      3'b000:
      begin
        if ((CMD_MODE == NORMAL) && (CMD_Target == SDRAM))
        begin
          oSDR_ADDR  <= CMD_ADDR[21:0];
          oSDR_DATA  <= CMD_DATA;
          mSDR_Start <= 1'b1;
          mSDR_ST    <= 3'b001;
        end
        else
        begin
          mSDR_ST    <= 3'b000;
          f_SDRAM    <= 1'b0;
        end
      end

      3'b001:
      begin
        if (iSDR_Done)
        begin
          if (mSDR_WRn == 1'b0)
          begin
            mSDR_ST <= 3'b010;
          end
          else
          begin
            mSDR_ST    <= 3'b000;
            f_SDRAM    <= 1'b0;                                                      
            mSDR_Start <= 1'b0;
          end
        end
        else
           SDR_DATA_reg <= iSDR_DATA;        
      end

      3'b010:
      begin
        oSDR_TXD_DATA   <= SDR_DATA_reg[7:0];
        oSDR_TXD_Start  <= 1'b1;
        mSDR_ST         <= 3'b011;
      end

      3'b011:
      begin
        if (iTXD_Done)
        begin
          oSDR_TXD_Start <= 1'b0;
          mSDR_ST        <= 3'b100;
        end                                                                                     
      end

      3'b100:
      begin
        oSDR_TXD_DATA  <= SDR_DATA_reg[15:8];
        oSDR_TXD_Start <= 1'b1;
        mSDR_ST        <= 3'b101;
      end

      3'b101:
      begin
        if (iTXD_Done)
        begin
          mSDR_Start     <= 1'b0;
          oSDR_TXD_Start <= 1'b0;
          mSDR_ST        <= 3'b000;
          f_SDRAM        <= 1'b0;
        end                             
      end
      endcase
    end
  end
end

assign oSDR_WR = mSDR_WRn  & mSDR_Start;
assign oSDR_RD = ~mSDR_WRn & mSDR_Start;

/////////////////////////////////////////////////////////
////////////////    SRAM Control    /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oSR_TXD_Start <= 1'b0;
    mSR_WRn       <= 1'b0;
    mSR_Start     <= 1'b0;
    f_SRAM        <= 1'b0;
    mSR_ST        <= 3'b000;
  end
  else
  begin
    if (CMD_Action == READ)
    begin
      mSR_WRn     <= 1'b0;
    end
    else if (CMD_Action == WRITE)
    begin
      mSR_WRn     <= 1'b1;
    end
                
    if (iRXD_Ready && (Pre_Target == SRAM))
    begin
      f_SRAM      <= 1'b1;
    end

    if (f_SRAM)
    begin
      case(mSR_ST)
      3'b000:
      begin
        if ((CMD_MODE  == NORMAL) && (CMD_Target == SRAM))
        begin
          oSR_ADDR  <= CMD_ADDR[17:0];
          oSR_DATA  <= CMD_DATA;
          mSR_Start <= 1'b1;
          mSR_ST    <= 3'b001;
        end
        else
        begin
          mSR_ST    <= 3'b000;
          f_SRAM    <= 1'b0;
        end
      end

      3'b001:
      begin
        if (mSR_WRn == 1'b0)
        begin
          mSR_ST    <= 3'b010;
        end
        else
        begin
          mSR_ST    <= 3'b000;
          f_SRAM    <= 1'b0;                                                      
          mSR_Start <= 1'b0;
        end
      end

      3'b010:
      begin
        oSR_TXD_DATA  <= iSR_DATA[7:0];
        oSR_TXD_Start <= 1'b1;
        mSR_ST        <= 3'b011;
      end

      3'b011:
      begin
        if (iTXD_Done)
        begin
          oSR_TXD_Start <= 1'b0;
          mSR_ST        <= 3'b100;
        end                                                                                     
      end

      3'b100:
      begin
        oSR_TXD_DATA    <= iSR_DATA[15:8];
        oSR_TXD_Start   <= 1'b1;
        mSR_ST          <= 3'b101;
      end

      3'b101:
      begin
        if (iTXD_Done)
        begin
          mSR_Start     <= 1'b0;
          oSR_TXD_Start <= 1'b0;
          mSR_ST        <= 3'b000;
          f_SRAM        <= 1'b0;
        end                             
      end
      endcase
    end
  end
end

assign oSR_OE_N = mSR_WRn;
assign oSR_WE_N = ~(mSR_WRn & mSR_Start);

/////////////////////////////////////////////////////////
////////////////////   VGA Control  /////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
  if (!iRST_n)
  begin
    oCursor_X   <= {10{1'b0}};
    oCursor_Y   <= {10{1'b0}};
    oCursor_R   <= {10{1'b0}};
    oCursor_G   <= {10{1'b0}};
    oCursor_B   <= {10{1'b0}};
    oOSD_CUR_EN <= 2'b00;
    f_VGA       <= 1'b0;
  end
  else
  begin
    if (iRXD_Ready && (Pre_Target == VGA))
    begin
      f_VGA <= 1'b1;
    end

    if (f_VGA)
    begin
      if ((CMD_Action == WRITE) && (CMD_MODE == DISPLAY))
      begin
        case(CMD_ADDR[2:0])
        3'b000: oOSD_CUR_EN <= CMD_DATA[1:0];
        3'b001: oCursor_X   <= CMD_DATA[9:0];
        3'b010: oCursor_Y   <= CMD_DATA[9:0];
        3'b011: oCursor_R   <= CMD_DATA[9:0];  
        3'b100: oCursor_G   <= CMD_DATA[9:0];
        3'b101: oCursor_B   <= CMD_DATA[9:0];
        endcase
      end

      f_VGA <= 1'b0;                       
    end
  end
end
/////////////////////////////////////////////////////////

endmodule