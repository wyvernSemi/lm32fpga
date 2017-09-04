//=============================================================
// 
// Copyright (c) 2016 Simon Southwell. All rights reserved.
//
// Date: 9th November 2016
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
// $Id: lm32_driver.h,v 1.4 2017/09/04 10:40:42 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/src/lm32_driver.h,v $
//
//=============================================================

#ifndef _LM32_DRIVER_H_
#define _LM32_DRIVER_H_

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include "USB_JTAG.h"

// -------------------------------------------------------------------------
// DEFINES
// -------------------------------------------------------------------------

#define USB_CMD_BUF_SIZE   8

// Command Action
#define SETUP              0x61;
#define ERASE              0x72;
#define WRITE              0x83;
#define READ               0x94;
#define LCD_DAT            0xA5;
#define LCD_CMD            0xB6;

// Command Target
#define LED                0xF0;
#define SEG7               0xE1;
#define PS2                0xD2;
#define FLASH              0xC3;
#define SDRAM              0xB4;
#define SRAM               0xA5;
#define LCD                0x96;
#define VGA                0x87;
#define SDRSEL             0x1F;
#define FLSEL              0x2E;
#define EXTIO              0x3D;
#define SET_REG            0x4C;
#define SRSEL              0x5B;

// Command Mode
#define OUTSEL             0x33;
#define NORMAL             0xAA;
#define DISPLAY            0xCC;
#define BURST              0xFF;

#define USB_LEDR_9         0x00020000
#define USB_LEDR_8         0x00010000
#define USB_LEDR_7         0x00008000
#define USB_LEDR_6         0x00004000
#define USB_LEDR_5         0x00002000
#define USB_LEDR_4         0x00001000
#define USB_LEDR_3         0x00000800
#define USB_LEDR_2         0x00000400
#define USB_LEDR_1         0x00000200
#define USB_LEDR_0         0x00000100

#define USB_LEDG_7         0x00000080
#define USB_LEDG_6         0x00000040
#define USB_LEDG_5         0x00000020
#define USB_LEDG_4         0x00000010
#define USB_LEDG_3         0x00000008
#define USB_LEDG_2         0x00000004
#define USB_LEDG_1         0x00000002
#define USB_LEDG_0         0x00000001

#define USB_NUM_GREEN_LEDS 8
#define USB_NUM_RED_LEDS   10
#define USB_NUM_LEDS       (USB_NUM_RED_LEDS + USB_NUM_GREEN_LEDS)

// Definitions for alternative 7 segment display values
// Bit 8 is mask bit to select alternative decode
#define USB_SEG7_OFF       0x110
#define USB_SEG7_H         0x111
#define USB_SEG7_h         0x112
#define USB_SEG7_o         0x113
#define USB_SEG7_L         0x114
#define USB_SEG7_P         0x115
#define USB_SEG7_t         0x116
#define USB_SEG7_u         0x117
#define USB_SEG7_y         0x118
#define USB_SEG7_dash      0x119
#define USB_SEG7_a         0x11a
#define USB_SEG7_deg       0x11b
#define USB_SEG7_c         0x11c
#define USB_SEG7_n         0x11d
#define USB_SEG7_e         0x11e
#define USB_SEG7_r         0x11f

// Mapping of normal hex values as substitute characters
#define USB_SEG7_I         0x001
#define USB_SEG7_O         0x000
#define USB_SEG7_S         0x005
#define USB_SEG7_G         0x009

// For completeness, define the hex digits as USB_SEG7 definitions
#define USB_SEG7_0         0x000
#define USB_SEG7_1         0x001
#define USB_SEG7_2         0x002
#define USB_SEG7_3         0x003
#define USB_SEG7_4         0x004
#define USB_SEG7_5         0x005
#define USB_SEG7_6         0x006
#define USB_SEG7_7         0x007
#define USB_SEG7_8         0x008
#define USB_SEG7_9         0x009
#define USB_SEG7_A         0x00a
#define USB_SEG7_B         0x00b
#define USB_SEG7_C         0x00c
#define USB_SEG7_D         0x00d
#define USB_SEG7_E         0x00e
#define USB_SEG7_F         0x00f

#define USB_RESET_DLY      0

#define USB_DEFAULT_DEVICE DEFAULT_DEVICE 

// These values are for the USB blaster of the DE1 development board.
// Use "dmesg | grep usb" to find the Altera board and get these values.
#define USB_VID            0x09fb
#define USB_PID            0x6001

#define USB_TIME_MS        (1    * USB_TIMESCALE)
#define USB_TIME_SEC       (1000 * USB_TIMESCALE)

// -------------------------------------------------------------------------
// MACROS
// -------------------------------------------------------------------------

#define USB_PRINT_HEX(_x, _l, _c) {                         \
   {                                                        \
     printf("// %s\n", (_c));                               \
     printf("00 00 00 10\n");                               \
     printf("%02x\n", (_l));                                \
     for (int i = 0; i < (_l); i++)                         \
       printf ("%02x ", (_x)[i]);                           \
     printf("\n\n");                                        \
   }                                                        \
}                                                           
                                                            
#define USB_SET_SEG7_MASK(_val, _mask, _x, _usb, _p) {      \
    (_x)[0] = WRITE;                                        \
    (_x)[1] = SEG7;                                         \
    (_x)[2] = 0x00;                                         \
    (_x)[3] = 0x00;                                         \
    (_x)[4] = (_mask);                                      \
    (_x)[5] = (char)((_val) >> 8);                          \
    (_x)[6] = (char)(_val);                                 \
    (_x)[7] = DISPLAY;                                      \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "set SEG7")                      \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
}

#define USB_SET_SEG7_ALT(_v3, _v2, _v1, _v0, _x, _usb, _p) {\
    USB_SET_SEG7_MASK((((_v3) & 0xf) << 12) |               \
                      (((_v2) & 0xf) << 8)  |               \
                      (((_v1) & 0xf) << 4)  |               \
                      ((_v0)  & 0xf),                       \
                      (((_v3) & 0x100) >> 5) |              \
                      (((_v2) & 0x100) >> 6) |              \
                      (((_v1) & 0x100) >> 7) |              \
                      (((_v0) & 0x100) >> 8),               \
                      _x, _usb, _p);                        \
}                                                           
                                                            
#define USB_SET_SEG7_HEX(_val, _x, _usb, _p) {              \
    USB_SET_SEG7_MASK(_val, 0, _x, _usb, _p);               \
}                                                           
                                                            
#define USB_SET_SEG7_DEC(_val, _x, _usb, _p) {              \
    USB_SET_SEG7_HEX(USB_DEC_TO_HEX(_val), _x, _usb, _p);   \
}

#define USB_SELECT_SEG7(_x, _usb, _p) {                     \
    (_x)[0] = SETUP;                                        \
    (_x)[1] = SET_REG;                                      \
    (_x)[2] = 0x12;                                         \
    (_x)[3] = 0x34;                                         \
    (_x)[4] = 0x56;                                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = SEG7;                                         \
    (_x)[7] = OUTSEL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Select SEG7")                   \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
}                                                           
                                                            
#define USB_READ_SEG7( _x, _usb, _p) {                      \
    (_x)[0] = READ;                                         \
    (_x)[1] = SEG7;                                         \
    (_x)[2] = 0x12;                                         \
    (_x)[3] = 0x34;                                         \
    (_x)[4] = 0x56;                                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = 0x00;                                         \
    (_x)[7] = NORMAL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Read SEG7")                     \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 2, true);                 \
    Sleep(10);                                              \
    if (_p){                                                \
      (_x)[0] = (_x)[1] = 0;                                \
      USB_PRINT_HEX(_x, 2, "Read bytes")}                   \
    else                                                    \
      (_usb)->Read_Data((_x), 2);                           \
}                                                           
                                                            
#define USB_DEC_TO_HEX(_val)                                \
    (((_val)%10)               |                            \
    ((((_val)/10)%10) << 4)    |                            \
    ((((_val)/100)%10) << 8)   |                            \
    ((((_val)/1000)%10) << 12))                             \
                                                            
                                                            
#define USB_SET_LEDS(_val, _led, _x, _usb, _p) {            \
    (_led) |= (_val);                                       \
    (_x)[0] = WRITE;                                        \
    (_x)[1] = LED;                                          \
    (_x)[2] = 0x00;                                         \
    (_x)[3] = (char)((_led) >> 16);                         \
    (_x)[4] = (char)((_led) >>  8);                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = (char)(_led);                                 \
    (_x)[7] = DISPLAY;                                      \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Set LEDs")                      \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
}                                                           
                                                            
                                                            
#define USB_CLR_LEDS(_val, _led, _x, _usb, _p) {            \
    (_led) &= ~(_val);                                      \
    USB_SET_LEDS(0, (_led), (_x), (_usb), (_p));            \
}                                                           
                                                            
#define USB_FAIL(_func_str) {                               \
    fprintf(stderr, "USB: %s() failed\n", (_func_str));     \
    exit(1);                                                \
}                                                           
                                                            
#define USB_SELECT_SRAM(_x, _usb, _p) {                     \
    (_x)[0] = SETUP;                                        \
    (_x)[1] = SET_REG;                                      \
    (_x)[2] = 0x12;                                         \
    (_x)[3] = 0x34;                                         \
    (_x)[4] = 0x56;                                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = SRAM;                                         \
    (_x)[7] = OUTSEL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Setup SRAM")                    \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
    (_x)[0] = SETUP;                                        \
    (_x)[1] = SRSEL;                                        \
    (_x)[6] = 0xff;                                         \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Select SRAM")                   \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
}                                                           
                                                            
#define USB_DESELECT_SRAM(_x, _usb, _p) {                   \
    (_x)[0] = SETUP;                                        \
    (_x)[1] = SRSEL;                                        \
    (_x)[2] = 0x12;                                         \
    (_x)[3] = 0x34;                                         \
    (_x)[4] = 0x56;                                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = 0x00;                                         \
    (_x)[7] = OUTSEL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Deselect SRAM")                 \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
}

#define USB_WRITE_SRAM_BLK(_len,_addr,_dt,_x,_usb,_fl,_p) { \
    (_x)[0] = WRITE;                                        \
    (_x)[1] = SRAM;                                         \
    (_x)[2] = (char)((_addr) >> 16);                        \
    (_x)[3] = (char)((_addr) >> 8);                         \
    (_x)[4] = (char)((_addr) >> 0);                         \
    (_x)[5] = (char)((_len) >> 8);                          \
    (_x)[6] = (char)((_len) >> 0);                          \
    (_x)[7] = BURST;                                        \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Write SRAM block")              \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, true);                 \
    if (_p)                                                 \
      USB_PRINT_HEX(_dt, _len, "Write SRAM block data")     \
    else                                                    \
      (_usb)->Write_Data((_dt), (_len), 0, _fl);            \
}                                                           
                                                            
#define USB_WRITE_SRAM(_val, _addr, _x, _usb, _p) {         \
    (_x)[0] = WRITE;                                        \
    (_x)[1] = SRAM;                                         \
    (_x)[2] = (char)((_addr) >> 16);                        \
    (_x)[3] = (char)((_addr) >> 8);                         \
    (_x)[4] = (char)((_addr) >> 0);                         \
    (_x)[5] = (char)((_val) >> 8);                          \
    (_x)[6] = (char)((_val) >> 0);                          \
    (_x)[7] = NORMAL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Write SRAM")                    \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 0, false);                \
}                                                           
                                                            
#define USB_READ_SRAM(_addr, _x, _usb, _p) {                \
    (_x)[0] = READ;                                         \
    (_x)[1] = SRAM;                                         \
    (_x)[2] = (char)((_addr) >> 16);                        \
    (_x)[3] = (char)((_addr) >> 8);                         \
    (_x)[4] = (char)((_addr) >> 0);                         \
    (_x)[5] = 0x00;                                         \
    (_x)[6] = 0x00;                                         \
    (_x)[7] = NORMAL;                                       \
    if (_p)                                                 \
      USB_PRINT_HEX(_x, 8, "Read SRAM")                     \
    else                                                    \
      (_usb)->Write_Data((_x), 8, 2, true);                 \
    Sleep(10);                                              \
    if (_p){                                                \
      (_x)[0] = (_x)[1] = 0;                                \
      USB_PRINT_HEX(_x, 2, "Read data") }                   \
    else                                                    \
      (_usb)->Read_Data((_x), 2);                           \
}                                                           
                                                            
#define USB_OPEN_DEVICE(_usb) {                             \
    if (!(_usb)->Open_Device())                             \
    {                                                       \
      USB_FAIL("Open_Device");                              \
    }                                                       \
}                                                           
                                                            
#define USB_RESET_DEVICE(_x, _usb) {                        \
    if (!(_usb)->Reset_Device(_x))                          \
    {                                                       \
      USB_FAIL("Reset_Device");                             \
    }                                                       \
}                                                           
                                                            
#define USB_CLOSE_DEVICE(_usb) {                            \
    if (!(_usb)->Close_Device())                            \
    {                                                       \
      USB_FAIL("Close_Device");                             \
    }                                                       \
}

// Handy predefined messages for 7 segment display
#define USB_SEG7_ALL_OFF(_x, _usb) {USB_SET_SEG7_ALT(USB_SEG7_OFF, USB_SEG7_OFF, USB_SEG7_OFF, USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_ALL_ON(_x, _usb)  {USB_SET_SEG7_ALT(USB_SEG7_8,   USB_SEG7_8,   USB_SEG7_8,   USB_SEG7_8,   (_x), (_usb), (_p));}
#define USB_SEG7_PASS(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_P,   USB_SEG7_A,   USB_SEG7_S,   USB_SEG7_S,   (_x), (_usb), (_p));}
#define USB_SEG7_FAIL(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_F,   USB_SEG7_A,   USB_SEG7_I,   USB_SEG7_L,   (_x), (_usb), (_p));}
#define USB_SEG7_ERR(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_E,   USB_SEG7_r,   USB_SEG7_r,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_END(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_E,   USB_SEG7_n,   USB_SEG7_D,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_STOP(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_S,   USB_SEG7_t,   USB_SEG7_o,   USB_SEG7_P,   (_x), (_usb), (_p));}
#define USB_SEG7_HALT(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_H,   USB_SEG7_a,   USB_SEG7_l,   USB_SEG7_t,   (_x), (_usb), (_p));}
#define USB_SEG7_DONE(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_D,   USB_SEG7_o,   USB_SEG7_n,   USB_SEG7_e,   (_x), (_usb), (_p));}
#define USB_SEG7_RUN(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_r,   USB_SEG7_u,   USB_SEG7_n,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_CODE(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_C,   USB_SEG7_o,   USB_SEG7_d,   USB_SEG7_e,   (_x), (_usb), (_p));}
#define USB_SEG7_INIT(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_I,   USB_SEG7_n,   USB_SEG7_I,   USB_SEG7_t,   (_x), (_usb), (_p));}
#define USB_SEG7_LOAD(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_L,   USB_SEG7_o,   USB_SEG7_a,   USB_SEG7_d,   (_x), (_usb), (_p));}
#define USB_SEG7_HELP(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_H,   USB_SEG7_E,   USB_SEG7_L,   USB_SEG7_P,   (_x), (_usb), (_p));}
#define USB_SEG7_INFO(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_I,   USB_SEG7_n,   USB_SEG7_F,   USB_SEG7_O,   (_x), (_usb), (_p));}
#define USB_SEG7_GET(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_g,   USB_SEG7_e,   USB_SEG7_t,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_PUT(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_P,   USB_SEG7_u,   USB_SEG7_t,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_PUSH(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_P,   USB_SEG7_u,   USB_SEG7_S,   USB_SEG7_H,   (_x), (_usb), (_p));}
#define USB_SEG7_POP(_x, _usb)     {USB_SET_SEG7_ALT(USB_SEG7_P,   USB_SEG7_O,   USB_SEG7_P,   USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_GO(_x, _usb)      {USB_SET_SEG7_ALT(USB_SEG7_g,   USB_SEG7_o,   USB_SEG7_OFF, USB_SEG7_OFF, (_x), (_usb), (_p));}
#define USB_SEG7_BUSY(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_b,   USB_SEG7_u,   USB_SEG7_S,   USB_SEG7_y,   (_x), (_usb), (_p));}
#define USB_SEG7_GONE(_x, _usb)    {USB_SET_SEG7_ALT(USB_SEG7_g,   USB_SEG7_o,   USB_SEG7_n,   USB_SEG7_e,   (_x), (_usb), (_p));}
#endif