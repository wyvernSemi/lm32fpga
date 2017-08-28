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
// $Id: USB_JTAG.h,v 1.1 2017/06/10 13:59:52 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/src/USB_JTAG.h,v $
//
//=============================================================

#ifndef _USB_JTAG_H_
#define _USB_JTAG_H_

#include <queue>
#include "ftd2xx.h"

#ifndef _WIN32
#include <unistd.h>

// In windows Sleep() uses millisecond, in Linux usleep uses microseconds
#define Sleep usleep
#define USB_TIMESCALE              1000
#else
#define USB_TIMESCALE              1

#endif

using namespace std;

#define   DEFAULT_DEVICE           0
#define   INIT_CMD_SIZE            5
#define   MAX_TXD_PACKET           256
#define   MAX_RXD_PACKET           100
#define   ALMOST_FULL_SIZE         20
#define   MAX_TOTAL_PACKET         (MAX_TXD_PACKET-ALMOST_FULL_SIZE)

class USB_JTAG
{
public:
     USB_JTAG();
     ~USB_JTAG();

     FT_STATUS            Get_Status();
     void                 Select_Device        (int Number);
     int                  Number_Of_Device     ();
     int                  Number_Of_Queue_Data ();
     bool                 Open_Device          ();
     bool                 Close_Device         ();
     bool                 Reset_Device         (int sleep_time);
     bool                 Write_Data           (unsigned char* Source, int Size, int WithRead, bool Immediate);
     bool                 Read_Data            (unsigned char* Dest,   int Size);
     bool                 Set_Ids              (unsigned long VID,     unsigned long PID);
                          
private:                  
     bool                 Initial_JTAG         ();

     FT_HANDLE            FT_Handle;
     FT_STATUS            FT_Status;
     int                  DeviceNumber;
     DWORD                NumOfWritten;
     DWORD                NumOfRead;
     unsigned char        Init_CMD   [INIT_CMD_SIZE];
     unsigned char        Close_CMD;
     unsigned char        TXD_Buffer [MAX_TXD_PACKET];
     queue<unsigned char> Buffer;
};

#ifndef USB_JTAG_HDR_ONLY

USB_JTAG::USB_JTAG()
{
     Init_CMD[0]    = 0x26;
     Init_CMD[1]    = 0x27;
     Init_CMD[2]    = 0x26;
     Init_CMD[3]    = 0x81;
     Init_CMD[4]    = 0x00;
     Close_CMD      = 0x1F;
     DeviceNumber   = DEFAULT_DEVICE;
     FT_Status      = FT_OK;
}

FT_STATUS USB_JTAG::Get_Status()
{
  return FT_Status;
}

void USB_JTAG::Select_Device(int Number)
{
  DeviceNumber = Number;
}

int USB_JTAG::Number_Of_Device()
{
  unsigned long numDevs=0;

  FT_Status = FT_ListDevices(&numDevs, NULL, FT_LIST_NUMBER_ONLY);

  return numDevs;
}

int USB_JTAG::Number_Of_Queue_Data()
{
  DWORD numData = 0;

  FT_Status = FT_GetQueueStatus(FT_Handle, &numData);

  return numData;
}


bool USB_JTAG::Open_Device()
{
  FT_Status = FT_Open(DeviceNumber,&FT_Handle);

  if (FT_Status == FT_OK) 
  {
    FT_SetLatencyTimer(FT_Handle, 0x02);
    return true;
  }

  return false;

}

bool USB_JTAG::Close_Device()
{
  FT_Status = FT_Write(FT_Handle, &Close_CMD, 1, &NumOfWritten);

  if (FT_Status == FT_OK)
  {
    FT_Status = FT_Close(FT_Handle);

    if (FT_Status == FT_OK)
    {
      return true;
    }
  }

  return false; 
}

bool USB_JTAG::Reset_Device(int sleep_time)
{
  Close_Device();
  Sleep(sleep_time * USB_TIMESCALE);
  Open_Device();
  Initial_JTAG();

  if (FT_Status == FT_OK)
  {
    return true;
  }

  return false;
}

bool USB_JTAG::Initial_JTAG()
{
  FT_Status = FT_Write(FT_Handle, Init_CMD, 5, &NumOfWritten);

  if (FT_Status == FT_OK)
  {
    return true;
  }

  return false;
}

bool USB_JTAG::Write_Data(unsigned char* Source, int Size, int WithRead, bool Immediate)
{
  int i;

  if (Size != 0)
  {
     // Insert Write Command
     Buffer.push((unsigned char)Size | 0x80);

     for(i = 0; i < Size; i++)
     {
       Buffer.push(Source[i]);
     }
  }

  if (WithRead != 0)
  {
     // Insert Read Command
     Buffer.push((unsigned char)WithRead | 0xC0);

     for (i = 0; i < WithRead; i++)
     {
       Buffer.push(0x00);
     }
  }
  // Transfer Queue To Array
  int Trans_Size = Buffer.size();

  if (Immediate || Trans_Size > (MAX_TXD_PACKET-ALMOST_FULL_SIZE))
  {
     for(i = 0; i < Trans_Size; i++)
     {
       TXD_Buffer[i] = Buffer.front();
       Buffer.pop();
     }
     FT_Status = FT_Write(FT_Handle, TXD_Buffer, Trans_Size, &NumOfWritten);
  }

  if (FT_Status == FT_OK)
  {
    return true;
  }

  return false;
}

bool  USB_JTAG::Read_Data(unsigned char* Dest, int Size)
{
  FT_Status = FT_Read(FT_Handle, Dest,Size, &NumOfRead);

  if (FT_Status == FT_OK)
  {
    return true;
  }

  return false;
}

bool USB_JTAG::Set_Ids(unsigned long VID, unsigned long PID)
{
#ifndef _WIN32
  // If not windows, must program the vendor and product IDs explicitly,
  // using a non-windows API call
  FT_Status = FT_SetVIDPID(VID, PID);

  if (FT_Status == FT_OK)
  {
    return true;
  }
  else
  {
    return false;
  }
#else
  return true;
#endif
}

USB_JTAG::~USB_JTAG()
{
  Close_Device();
}
#endif
#endif
