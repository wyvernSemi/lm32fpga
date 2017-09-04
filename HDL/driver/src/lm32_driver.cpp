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
// $Id: lm32_driver.cpp,v 1.7 2017/09/04 10:40:42 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/src/lm32_driver.cpp,v $
//
//=============================================================

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include <cstdio>
#include <cstdlib>
#include <stdint.h>

#include "lm32_driver_elf.h"
#include "lm32_driver.h"

#if !(defined _WIN32) && !(defined _WIN64)
#include <unistd.h>
#else 
extern "C" {
extern int getopt(int nargc, char** nargv, char* ostr);
extern char* optarg;
extern int optind;
}
#endif

// -------------------------------------------------------------------------
// LOCAL DEFINES
// -------------------------------------------------------------------------

#define STATUS_BYTE_ADDR      0xfffc
#define DONT_CARE             0

// Configuration defaults
#define DEFAULT_PROG_NAME     "test.elf"
#define DEFAULT_DELAY         0

// Test delays in milliseconds
#define USB_TEST_LED_DLY      (100  * USB_TIME_MS)
#define USB_TEST_PAUSE        (1500 * USB_TIME_MS)


// -------------------------------------------------------------------------
// open_device()
// -------------------------------------------------------------------------

void open_device(USB_JTAG* p_usb)
{

  p_usb->Set_Ids(USB_VID, USB_PID);

  int num_dev = p_usb->Number_Of_Device();

  if (num_dev != 1)
  {
    fprintf(stderr, "USB: Unexpected number of devices (got %d, expected 1)\n", num_dev);
    exit(1);
  }

  p_usb->Select_Device(USB_DEFAULT_DEVICE);

  // Reset (and open) device
  USB_RESET_DEVICE(USB_RESET_DLY, p_usb);
}

// -------------------------------------------------------------------------
// get_options()
// -------------------------------------------------------------------------

static void get_options(int argc, char** argv, char** fname, int* delay, int* no_load, bool* no_wait, bool* generate_hex)
{
    int option;

    *fname        = DEFAULT_PROG_NAME;
    *delay        = DEFAULT_DELAY;
    *no_load      = 0;
    *no_wait      = false;
    *generate_hex = false;

    while ((option = getopt(argc, argv, "f:d:nlwHh")) != EOF)
    {
        switch(option)
        {
        case 'f':
            *fname = optarg;
            break;
        case 'd':
            *delay = strtol(optarg, NULL, 0);
            break;
        case 'l':
            *no_load = -1;
            break;
        case 'n':
            *no_load = 1;
            break;
        case 'w':
            *no_wait = true;
            break;
        case 'H':
            *generate_hex = true;
            break;
        case 'h':
        case '?':
        default:
            printf("Usage: lm32_driver [-f <filename>][-d <delay ms>][-n|-l][-w]\n\n"
                "    -f Specify ELF file to load (default %s)\n"
                "    -d Specify delay (in ms) after program signals termination (default 0)\n"
                "    -n No load of program, only execute (default false)\n"
                "    -l Only load program, don't execute (default false)\n"
                "    -w Don't wait for program termination (default wait)\n"
                "    -H Generate HEX output (default off)\n"
                "\n",
                DEFAULT_PROG_NAME);
            exit(1);
        }
    }
}

// -------------------------------------------------------------------------
// main()
// -------------------------------------------------------------------------

int main (int argc, char** argv)
{
  USB_JTAG*     p_usb1;                  // pointer to USB-JTAG access object
  unsigned char buf[USB_CMD_BUF_SIZE];   // Buffer for use in communications
  uint32_t      status;                  // Status word
  char*         fname;
  int           delay;
  int           no_load;
  bool          no_wait;
  bool          generate_hex;

  // Process command line options
  get_options(argc, argv, &fname, &delay, &no_load, &no_wait, &generate_hex);

  // Open and initialise device
  p_usb1 = new USB_JTAG;

  // Open up communications with JTAG over USB
  if (!generate_hex)
  {
    open_device(p_usb1);

    // Select JTAG access to SRAM
    USB_SELECT_SRAM(buf, p_usb1, generate_hex);

    // Load test program to memory
    if (no_load < 1)
    {
      lm32_read_elf (fname, p_usb1);
    }
  }

  if (no_load >= 0)
  {

    // Deselect JTAG SRAM, giving access to CPU
    USB_DESELECT_SRAM(buf, p_usb1, generate_hex);
    
    // Enable processor (resetcpu deasserted)
    USB_WRITE_SRAM(DONT_CARE, (STATUS_BYTE_ADDR >> 1), buf, p_usb1, generate_hex);

    // Select SEG7 for reading
    USB_SELECT_SEG7(buf, p_usb1, generate_hex);

    if (!no_wait)
    {
      // Loop until a non-zero value is written to test location
      do
      {
          // Read the status word from memory
          USB_READ_SEG7(buf, p_usb1, generate_hex);
          status = buf[0] | (buf[1] << 8);
      } while (status == 0 && !generate_hex);
      
      // Wait some time (ms), if specified
      if (delay)
      {
          Sleep(delay);
      }
      
      // Select the SRAM for JTAG access once again
      USB_SELECT_SRAM(buf, p_usb1, generate_hex);
      
      // Disable processor (asserting resetcpu)
      USB_WRITE_SRAM(DONT_CARE, (STATUS_BYTE_ADDR >> 1), buf, p_usb1, generate_hex);
      
      // Read the status word from memory
      USB_READ_SRAM((STATUS_BYTE_ADDR >> 1), buf, p_usb1, generate_hex);
      status = buf[1] | (buf[0] << 8);
      USB_READ_SRAM(((STATUS_BYTE_ADDR+2) >> 1), buf, p_usb1, generate_hex);
      status = (status << 16) | buf[1] | (buf[0] << 8);
      
      // Print out status
      if (!generate_hex)
      {
        printf("RAM 0xfffc = 0x%08x\n", status & 0xffff);
      }
    }
  }

  // Close device
  if (generate_hex)
  {
      // Send termination command
      printf("// Terminate\nff ff ff ff\n");
  }
  else
  {
    USB_CLOSE_DEVICE(p_usb1);
  }

  // Clean up
  delete p_usb1;

  return 0;
}
