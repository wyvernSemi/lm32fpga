//=====================================================================
//
// veriuser.h                                          Date: 2017/6/2 
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
// $Id: veriuser.c,v 1.1 2017/06/10 13:59:53 simon Exp $
// $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/pli/veriuser.c,v $
//
//=====================================================================


#if !defined(MODELSIM)
#include "vxl_veriuser.h"
#endif

#include "de1_pli.h"

DllExport char *veriuser_version_str = "DE1 PLI V0.1 Copyright (c) 2017 Simon Southwell.";

DllExport s_tfcell veriusertfs[DE1_TF_TBL_SIZE+1] =
{
    DE1_TF_TBL,
    {0} 
};

DllExport p_tfcell bootstrap ()
{
    return veriusertfs;
}

#ifdef ICARUS
static void veriusertfs_register(void)
{
    veriusertfs_register_table(veriusertfs);
}

void (*vlog_startup_routines[])() = { &veriusertfs_register, 0 };
#endif
