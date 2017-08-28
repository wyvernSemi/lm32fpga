//=============================================================
// 
// Copyright (c) 2017 Simon Southwell
//
// Date: 23rd May 2017
//
// ELF executable reader
//
// This file is part of the cpumico32 instruction set simulator.
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
// $Id: lm32_driver_elf.cpp,v 1.2 2017/07/14 12:25:05 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/src/lm32_driver_elf.cpp,v $
//
//=============================================================

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include <cstdio>
#include <stdint.h>

#define USB_JTAG_HDR_ONLY

#include "lm32_driver_elf.h"
#include "lm32_driver.h"

#define MAX_PROG_SIZE (512*1024)
#define BLK_SIZE      32

static unsigned char ubuf [8];
static uint16_t      fbuf [64*1024];

void lm32_read_elf (const char * const filename, USB_JTAG* p_usb1)
{
    int         i, c;
    uint32_t    pcount, bytecount = 0;
    pElf32_Ehdr h;
    pElf32_Phdr h2[ELF_MAX_NUM_PHDR];
    char        buf[sizeof(Elf32_Ehdr)];
    char        buf2[sizeof(Elf32_Phdr)*ELF_MAX_NUM_PHDR];
    const char* ptr;
    FILE*       elf_fp;


    // Open program file ready for loading
    if ((elf_fp = fopen(filename, "rb")) == NULL)
    {
        fprintf(stderr, "*** ReadElf(): Unable to open file %s for reading\n", filename);
        exit(1);
    } 

    // Read elf header
    h = (pElf32_Ehdr) buf;
    for (i = 0; i < sizeof(Elf32_Ehdr); i++)
    {
        buf[i] = fgetc(elf_fp);
        bytecount++;
        if (buf[i] == EOF) 
        {
            fprintf(stderr, "*** ReadElf(): unexpected EOF\n");
            exit(1);
        } 
    }

    //LCOV_EXCL_START
    // Check some things
    ptr= ELF_IDENT;
    for (i = 0; i < 4; i++) 
    {
        if (h->e_ident[i] != ptr[i])
        {
            fprintf(stderr, "*** ReadElf(): not an ELF file\n");
            exit(1);
        }
    }

    if (SWAPHALF(h->e_type) != ET_EXEC)
    {
        fprintf(stderr, "*** ReadElf(): not an executable ELF file\n");
        exit(1);
    }

    if (SWAPHALF(h->e_machine) != EM_LATTICEMICO32 && SWAPHALF(h->e_machine) != EM_LATTICEMICO32_OLD)
    {
        fprintf(stderr, "*** ReadElf(): not a Mico32 ELF file\n");
        exit(1);
    }

    if (SWAPHALF(h->e_phnum) > ELF_MAX_NUM_PHDR)
    {
        fprintf(stderr, "*** ReadElf(): Number of Phdr (%d) exceeds maximum supported (%d)\n", SWAPHALF(h->e_phnum), ELF_MAX_NUM_PHDR);
        exit(1);
    }

    // Read program headers
    for (pcount=0 ; pcount < SWAPHALF(h->e_phnum); pcount++)
    {
        for (i = 0; i < sizeof(Elf32_Phdr); i++)
        {
            c = fgetc(elf_fp);
            if (c == EOF)
            {
                fprintf(stderr, "*** ReadElf(): unexpected EOF\n");
                exit(1);
            } 
            buf2[i+(pcount * sizeof(Elf32_Phdr))] = c;
            bytecount++;
        }
    }

    // Load text/data segments
    for (pcount=0 ; pcount < SWAPHALF(h->e_phnum); pcount++)
    {
        h2[pcount] = (pElf32_Phdr) &buf2[pcount * sizeof(Elf32_Phdr)];

        // Gobble bytes until section start
        for (; bytecount < SWAP(h2[pcount]->p_offset); bytecount++)
        {
            c = fgetc(elf_fp);
            if (c == EOF) {
                fprintf(stderr, "*** ReadElf(): unexpected EOF\n");
                exit(1);
            }
        }

        // Check we can load the segment to memory
        if ((SWAP(h2[pcount]->p_vaddr) + SWAP(h2[pcount]->p_memsz)) >= MAX_PROG_SIZE)
        {
            fprintf(stderr, "*** ReadElf(): segment memory footprint outside of internal memory range\n");
            exit(1);
        }
        
        unsigned endaddr = (SWAP(h2[pcount]->p_offset) + SWAP(h2[pcount]->p_filesz));
        unsigned hwaddr  =  SWAP(h2[pcount]->p_vaddr) >> 1;
        int      sec_len = endaddr - bytecount;

        // Read the bytes from the file into a buffer
        fread(fbuf, 1, sec_len, elf_fp);

        for (i = 0; i < sec_len/2; i++, hwaddr++)
        {
          USB_WRITE_SRAM(fbuf[i], hwaddr, ubuf, p_usb1);
        }

        bytecount += sec_len;
    }

    // Ensure all the bytes are flushed before exiting. (This badly named
    // function closes the device, and then re-opens and initialises it.)
    p_usb1->Reset_Device(0);
}

