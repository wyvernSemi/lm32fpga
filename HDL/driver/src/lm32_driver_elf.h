//=============================================================
// 
// Copyright (c) 2017 Simon Southwell. All rights reserved.
//
// Date: 23rd May 2017
//
// Header for the ELF executable reader
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
// $Id: lm32_driver_elf.h,v 1.1 2017/06/10 13:59:52 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/src/lm32_driver_elf.h,v $
//
//=============================================================

#ifndef _LM32_DRIVER_ELF_H_
#define _LM32_DRIVER_ELF_H_

// -------------------------------------------------------------------------
// INCLUDES
// -------------------------------------------------------------------------

#include <cstdio>
#include <cstdlib>
#include <stdint.h>

#include "USB_JTAG.h"

// -------------------------------------------------------------------------
// DEFINES
// -------------------------------------------------------------------------

#if defined( __CYGWIN__) || defined(_WIN32) || defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
#define SWAP(_ARG) (((_ARG >> 24)&0xff) | ((_ARG >> 8)&0xff00) | ((_ARG << 8)&0xff0000) | ((_ARG << 24)&0xff000000))
#define SWAPHALF(_ARG) (uint32_t)(((_ARG>>8)&0xff) | ((_ARG<<8)&0xff00))
#else
#define SWAP(_ARG) _ARG
#define SWAPHALF(_ARG) _ARG
#endif

#define EI_NIDENT                 16
                                  
#define ET_NONE                   0
#define ET_REL                    1
#define ET_EXEC                   2
#define ET_DYN                    3
#define ET_CORE                   4
#define ET_LOPROC                 0xff00
#define ET_HIPROC                 0xffff

#define EM_NONE                   0
#define EM_M32                    1
#define EM_SPARC                  2
#define EM_386                    3
#define EM_68K                    4
#define EM_88K                    5
#define EM_860                    7
#define EM_MIPS                   8

#define EM_LATTICEMICO32_OLD      0x666
#define EM_LATTICEMICO32          138

#define ELF_IDENT                 "\177ELF"

#define ELF_MAX_NUM_PHDR          4

#define PrintPhdr(_P) {\
    fprintf(stderr, " p_type = %x\n p_offset = %x\n p_vaddr = %x\n p_paddr = %x\n p_filesz = %x\n p_memsz = %x\n p_flags = %x\n p_align = %x\n\n", \
                    SWAP(_P->p_type), SWAP(_P->p_offset),  SWAP(_P->p_vaddr), SWAP(_P->p_paddr),  SWAP(_P->p_filesz), SWAP(_P->p_memsz),  SWAP(_P->p_flags), SWAP(_P->p_align)); }

// -------------------------------------------------------------------------
// TYPEDEFS
// -------------------------------------------------------------------------

typedef uint32_t Elf32_Addr;
typedef uint32_t Elf32_Word;
typedef uint32_t Elf32_Sword;
typedef uint32_t Elf32_Off;
typedef uint16_t Elf32_Half;

typedef struct {
    unsigned char e_ident[EI_NIDENT] ;
    Elf32_Half e_type ;        
    Elf32_Half e_machine ;    
    Elf32_Word e_version ;
    Elf32_Addr e_entry ;
    Elf32_Off  e_phoff ;
    Elf32_Off  e_shoff;
    Elf32_Word e_flags ;
    Elf32_Half e_ehsize ;
    Elf32_Half e_phentsize ;
    Elf32_Half e_phnum ;
    Elf32_Half e_shentsize ;
    Elf32_Half e_shnum ;
    Elf32_Half e_shstrndx ;
} Elf32_Ehdr, *pElf32_Ehdr ;

typedef struct {
    Elf32_Word p_type;
    Elf32_Off  p_offset;
    Elf32_Addr p_vaddr;
    Elf32_Addr p_paddr;
    Elf32_Word p_filesz;
    Elf32_Word p_memsz;
    Elf32_Word p_flags;
    Elf32_Word p_align;
} Elf32_Phdr, *pElf32_Phdr;

void lm32_read_elf (const char * const filename, USB_JTAG* p_usb1);


#endif
