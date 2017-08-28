//=====================================================================
//
// de1_pli.c                                          Date: 2017/6/2 
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
// $Id: de1_pli.c,v 1.5 2017/07/04 12:08:46 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/pli/de1_pli.c,v $
//
//=====================================================================

#if defined _WIN32 || defined _WIN64
#include <conio.h>
#else
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#endif

#include "de1_pli.h"

#define VER_MAJOR                   2
#define VER_MINOR                   2

#define STR_BUF_SIZE                1024
#define DE1_PORT_NUM                0xc001
#define DE1_CLOSE_MSG               "close;"
#define DE1_RESET_MSG               "reset;"
#define DE1_FINISH_PAUSE            1000

#if defined (_WIN32) || defined (_WIN64) 
#define DE1_SLEEP_MSEC(_t)          Sleep(_t)
#else
#define DE1_SLEEP_MSEC(_t)          usleep((_t)*1000)
#endif

#define LM32_INPUT_RDY_TTY          _kbhit
#define LM32_GET_INPUT_TTY          _getch

static int  sockfd                  = -1;
static int  seen_error              = 0;
static char buffer[DE1_CMD_SIZE+1];

static int  gui_initialised         = 0;

// -------------------------------------------------------------------------
// error()
//
// Error function that prints a message, and then sets an error flag
//
// -------------------------------------------------------------------------

void error(char *msg)
{
    io_printf(msg);
    seen_error = 1;
}

// -------------------------------------------------------------------------
// convert_to_char()
//
// Converts 7 bit hex code to character equivalent
//
// -------------------------------------------------------------------------

unsigned convert_to_char(unsigned code)
{
    unsigned byte;
    
    switch (code)
    {
        case 0x40 :  byte = '0'; break;
        case 0x79 :  byte = '1'; break;
        case 0x24 :  byte = '2'; break;
        case 0x30 :  byte = '3'; break;
        case 0x19 :  byte = '4'; break;
        case 0x12 :  byte = '5'; break;
        case 0x02 :  byte = '6'; break;
        case 0x78 :  byte = '7'; break;
        case 0x00 :  byte = '8'; break;
        case 0x10 :  byte = '9'; break;
        case 0x08 :  byte = 'A'; break;
        case 0x46 :  byte = 'C'; break;
        case 0x06 :  byte = 'E'; break;
        case 0x0e :  byte = 'F'; break;
        case 0x20 :  byte = 'a'; break;
        case 0x03 :  byte = 'b'; break;
        case 0x27 :  byte = 'c'; break;
        case 0x21 :  byte = 'd'; break;
        case 0x04 :  byte = 'e'; break;
        case 0x09 :  byte = 'H'; break;
        case 0x0b :  byte = 'h'; break;
        case 0x23 :  byte = 'o'; break;
        case 0x47 :  byte = 'L'; break;
        case 0x07 :  byte = 't'; break;
        case 0x63 :  byte = 'u'; break;
        case 0x11 :  byte = 'y'; break;
        case 0x3f :  byte = '-'; break;
        case 0x1c :  byte = '*'; break;
        case 0x2b :  byte = 'n'; break;
        case 0x2f :  byte = 'r'; break;
        case 0x0c :  byte = 'P'; break;
        case 0xff :  byte = ' '; break;
        default   :  byte = ' '; break;   
    } 

    return byte;
}

// -------------------------------------------------------------------------
// hex_to_char()
//
// Convert a hex nibble to a character equivalent
//
// -------------------------------------------------------------------------

unsigned hex_to_char(unsigned val)
{
    
    if (val >= 0 && val <= 9)
    {
        return '0' + val;
    }
    else
    {
        return 'A' + val;
    }
}

// -------------------------------------------------------------------------
// DE1Init()
//
// Main routine called whenever $de1init task invoked from
// initial block of test module. No arguments expected in $de1init call.
//
// -------------------------------------------------------------------------

int DE1Init ()
{

#if defined (_WIN32) || defined (_WIN64)    
    WSADATA             wsaData;
    STARTUPINFO         si;
	PROCESS_INFORMATION pi;
#endif    
    
    struct hostent*    server;
    struct sockaddr_in serv_addr;
    
    int                portno = DE1_PORT_NUM;
    int                status;
    
    char               sbuf[STR_BUF_SIZE];
    
    debug_io_printf("DE1Init()\n");
    
    // Only process if not seen a previous error, and not a GUI already running
    if(!seen_error)
    {
#if defined (_WIN32) || defined (_WIN64)
        // Clear the startup information structure, and set the cb
        // field (size of structure in bytes), as this is all that's
        // needed        
        memset( &si, 0, sizeof(si));
        si.cb = sizeof(si);
        
        // Spawn a new process for running the de1.pyw script. 
        CreateProcess(NULL , 
                      "python3.exe ../../python/de1.pyw", 
                      NULL,
                      NULL,
                      FALSE,
                      0, 
                      NULL,
                      NULL,
                      &si,
                      &pi);
        
        // Initialize Winsock (windows only). Use windows socket spec. verions up to 2.2.
        if (status = WSAStartup(MAKEWORD(VER_MAJOR, VER_MINOR), &wsaData))
        {
            sprintf(sbuf, "WSAStartup failed with error: %d\n", status);
            error (sbuf);
            return 1;
        }

#else
	// Fire up the GUI
	system("../../python/de1.pyw &");

	// Give it a chance to be there and initialise
	sleep(1);
#endif        
        // Create a socket
        if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
        {
            error((char *)"ERROR opening socket");
        }
        
        // Get hostname from command line 
        gethostname(sbuf, sizeof(sbuf));
        debug_io_printf("DE1Init: %s\n", sbuf);
        
        server = gethostbyname("localhost" /*sbuf*/);
        
        if (server == NULL)
        {
            error((char *)"ERROR, no such host\n");
            return 1;
        }
        
        // Zero the server address structure
        memset((char *) &serv_addr, 0, sizeof(serv_addr));
        
        // Initialise the server address structure
        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port   = htons(portno);
        memcpy((char *)&serv_addr.sin_addr.s_addr, (char *)server->h_addr, server->h_length);
       
        // Connect to socket
        if ((status = connect(sockfd,(struct sockaddr *) &serv_addr, sizeof(serv_addr))) < 0)
        {
            error((char *)"ERROR connecting");
            return 1;
        }
    }

    gui_initialised = !seen_error;
    
    return (seen_error ? 1 : 0);
}

// -------------------------------------------------------------------------
// DE1Halt
//
// Called for a 'reason'. Procedure to catch 'finish' or restart events
// to tidy up old GUI process.
//
// -------------------------------------------------------------------------

int DE1Halt (int data, int reason)
{
    int n;
    
    debug_io_printf("DE1Halt(): data = %d reason = %d\n", data, reason);

    if (reason == reason_endofcompile)
    {
    }
    else if (reason == reason_finish || reason == reason_restart || reason == reason_reset)
    {
        int finish = reason == reason_finish;
        
        if (gui_initialised && !seen_error)
        {
            // If simulation finishing, or restarting (reset), close the running
            // GUI window by sending 'Close;' message, as a new one will be
            // started.
            sprintf(buffer, DE1_CLOSE_MSG);

            // Send message over the socket
            if ((n = skt_write(sockfd, buffer, DE1_CMD_SIZE)) < 0)
            {
                error((char *)"ERROR writing to socket");
            }

            // Wait for a bit, as the process could be killed before
            // this is sent when finishing.
            if (finish)
            {
                DE1_SLEEP_MSEC(DE1_FINISH_PAUSE);
            }
        }
    }
    else if (reason == reason_startofsave)
    {
    }
    else if (reason == reason_save)
    {
    }
    else if (reason != reason_finish)
    {
        debug_io_printf("DE1Halt(): not called for a halt reason (%d)\n", reason);
    }
    
    return 0;
}

// -------------------------------------------------------------------------
// DE1Update()
//
// Function called whenever $de1update task invoked. Expecting the verilog
// to call task with two 32 bit arguments: $de1update(<cmd>, <value>)
//
// -------------------------------------------------------------------------

int DE1Update ()
{
    int  n;
    int  bidx = 0;
    
    // Extract the arguments from the verilog call to $de1update
    unsigned cmd = tf_getp(DE1_PLI_CMD_ARG);
    unsigned val = tf_getp(DE1_PLI_VAL_ARG);

    debug_io_printf("DE1Update() : %d 0x%08x\n", cmd, val);
    
    // Only process if not seen a previous error
    if (!seen_error)
    {
        // If seven seg diplay update...
        switch (cmd)
        {
        case TCP_CMD_HEX:  
        
            buffer[bidx++] = 'S'; 
            
            // Decode each 7 bit HEX values to characters for command buffer
            buffer[bidx++] = convert_to_char((val >> 21) & 0x7f);
            buffer[bidx++] = convert_to_char((val >> 14) & 0x7f);
            buffer[bidx++] = convert_to_char((val >>  7) & 0x7f);
            buffer[bidx++] = convert_to_char((val >>  0) & 0x7f);
            break;
            
        case TCP_CMD_LEDR:
        
            buffer[bidx++] = 'R';
            buffer[bidx++] = hex_to_char((val >> 12) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  8) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  4) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  0) & 0xf);            
            break;
            
        case TCP_CMD_LEDG:

            buffer[bidx++] = 'G';
            buffer[bidx++] = hex_to_char((val >> 12) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  8) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  4) & 0xf);
            buffer[bidx++] = hex_to_char((val >>  0) & 0xf);
            break;
            
        default: 
            error((char *)"DE1Update: Error in command argument");
            return 1;
        }
            
        // Terminate the command string with a delimiter
        buffer[bidx++] = ';';
        
        // Add a string terminator character to make printing for debug easier.
        buffer[bidx++] = '\0';
        
        debug_io_printf("DE1Update() : sending %s\n", buffer);
        
        // Send message over the socket
        if ((n = skt_write(sockfd, buffer, DE1_CMD_SIZE)) < 0)
        {
            error((char *)"ERROR writing to socket");
        }
    }

    return (seen_error ? 1 : 0);
}

#if !(defined _WIN32) && !defined(_WIN64)
// -------------------------------------------------------------------------
// Keyboard input LINUX/CYGWIN emulation functions
// -------------------------------------------------------------------------

// Implement _kbhit() locally for non-windows platforms
static int _kbhit(void)
{
  struct termios oldt, newt;
  int ch;
  int oldf;
 
  tcgetattr(STDIN_FILENO, &oldt);
  newt           = oldt;
  newt.c_lflag &= ~(ICANON | ECHO);

  tcsetattr(STDIN_FILENO, TCSANOW, &newt);
  oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
  fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
 
  ch = getchar();
 
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  fcntl(STDIN_FILENO, F_SETFL, oldf);
 
  if(ch != EOF)
  {
      ungetc(ch, stdin);
      return 1;
  }
 
  return 0;
}

// getchar() is okay for _getch() on non-windows platforms
#define _getch getchar

#endif

// -------------------------------------------------------------------------
// PLI routine to get input character from keyboard (non-blocking), and
// return it to the simulation function call.
// -------------------------------------------------------------------------

DllExport int DE1GetChar (void)
{
    int status = -1;
    
    if (LM32_INPUT_RDY_TTY())
    {
        status = LM32_GET_INPUT_TTY() & 0xff;
    }

    // Return the byte as output of the verilog function.
    tf_putp(0, status);
    
    return 0;
}

// -------------------------------------------------------------------------
// PLI routine to put character to stderr.
// -------------------------------------------------------------------------

DllExport int DE1PutChar (void)
{
    unsigned byte = tf_getp(1);

    // Print character to stderr (rather than stdout), as the simulator 
    // redirects stdout to its own console output, and even flushing does
    // not force displaying the character, until a newline is output.
    fprintf(stderr, "%c", byte);
    
    return 0;
}
    
