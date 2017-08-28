//=====================================================================
//
// de1_pli.h                                       Date: 2017/6/2 
//
// Copyright (c) 2017 Simon Southwell.
//
// This file is part of cpumico32.
//
// cpumico32 is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// cpumico32 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with cpumico32. If not, see <http://www.gnu.org/licenses/>.
//
// $Id: de1_pli.h,v 1.3 2017/07/04 12:08:21 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/pli/de1_pli.h,v $
//
//=====================================================================

#ifndef _DE1_PLI_H_
#define _DE1_PLI_H_

#include <veriuser.h>
#include <vpi_user.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#if !defined _WIN32 && !defined _WIN64

#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 

#else
    
#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <Shellapi.h>
#endif

#if !defined _WIN32 && !defined _WIN64
#define DllImport
#define DllExport

// For Linux, map socket access functions to file access functions
#define skt_read(_skt,_buf,_len)  read((_skt),(_buf),(_len))
#define skt_write(_skt,_buf,_len) send((_skt),(_buf),(_len),0)
#define skt_close(_skt)           close(_skt)

#else 
#define DllImport   __declspec( dllimport )
#define DllExport   __declspec( dllexport )

// For windows, map socket access functions to windows socket functions
#define skt_read(_skt,_buf,_len)  recv((_skt),(_buf),(_len),0)
#define skt_write(_skt,_buf,_len) send((_skt),(_buf),(_len),0)
#define skt_close(_skt)           closesocket(_skt)

#endif

//#define DEBUG

#ifdef DEBUG
#define debug_io_printf io_printf
#else
#define debug_io_printf //
#endif

// Command definitions for monitor PLI routines
// These must match the definitions in test.v
#define TCP_CMD_HEX            0
#define TCP_CMD_LEDR           1
#define TCP_CMD_LEDG           2

// Poistions of the $de1update arguments (starts from 1)
#define DE1_PLI_CMD_ARG        1
#define DE1_PLI_VAL_ARG        2

// Size of a PLI command
#define DE1_CMD_SIZE           6

// Default size of buffers
#define BUFSIZE 256

// The PLI task/function table initialisation
#define DE1_TF_TBL \
    {usertask,     0, NULL, 0, DE1Init,     DE1Halt, "$de1init",    1}, \
    {usertask,     0, NULL, 0, DE1Update,   NULL,    "$de1update",  1}, \
    {userfunction, 0, NULL, 0, DE1GetChar,  NULL,    "$de1getchar", 1}, \
    {usertask,     0, NULL, 0, DE1PutChar,  NULL,    "$de1putchar", 1}

#define DE1_TF_TBL_SIZE 4

DllExport int DE1Init    (void);
DllExport int DE1Halt    (int, int);
DllExport int DE1Update  (void);
DllExport int DE1GetChar (void);
DllExport int DE1PutChar (void);
#endif
