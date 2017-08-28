###################################################################
#
# de1_pli.c                                          Date: 2017/6/2 
#
# Copyright (c) 2017 Simon Southwell.
#
# This file is part of cpumico32.
#
# cpumico32 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# cpumico32 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with cpumico32. If not, see <http://www.gnu.org/licenses/>.
#
# $Id: makefile,v 1.3 2017/07/04 12:07:02 simon Exp $
# $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/pli/makefile,v $
#
###################################################################
#
# This is a makefile script for use in cygwin, but using the MSVC
# toolchain to build a non-cygwin DLL.
#
# $MODELSIM and $MODEL_TECH environment variables must be set as 
# windows style paths for use by the MSVC tools. 
#
# Other paths that need setting are INCLUDE and LIB, and the PATH 
# updated for the MSVC tool chain. In windows, these are usually set
# by calling <path to msvc>\vcvarsall.bat. The INCLUDE and LIB
# variables need to be windows style paths, and as a minumum (for
# this build) include the appropriate MSVC and Microsoft SDK paths.
# E.g.
#
# LIB='C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\LIB; \
#      C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\lib'
#
# INCLUDE='C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\include; \
#          C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include'
#
# The PATH variable needs updating to contain the IDE directory as a 
# minumum. E.g.
#
# PATH=${PATH}:/cygdrive/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 10.0/Common7/IDE
#
###################################################################

OSTYPE = $(shell uname)

# Get OS type
ifeq ($(OS), Windows_NT)
  DRIVEROOT = C:
else
  ifeq (${OSTYPE}, Linux)
    DRIVEROOT = /
  else
    DRIVEROOT = /cygdrive/c
  endif
endif 

# Modify this variable, if necessary, to point to local MSVC home 
# folder (as seen by cygwin). Quotes necessary due to spaces and
# parenthesis in windows style path---don't delete.
MSVC_ROOT         = '${DRIVEROOT}\Program Files (x86)\Microsoft Visual Studio 10.0'

# C source code
DE1_C             = de1_pli.c veriuser.c

DE1_SRCDIR        = ./
DE1_OUTDIR        = ./lib
DE1_OBJDIR        = ./obj
DE1_OBJS          = ${DE1_C:%.c=${DE1_OBJDIR}/%.obj}


# Compile and link common flag definitions
LDOPTS            =
CFLAGS            = -I${MODELSIM}/include -I. -DMODELSIM 

# Define OS specific variable settings
ifeq (${OSTYPE}, Linux)
  CC              = gcc
  LD              = ${CC} 
  DE1_PLI         = de1_pli.so
  ARCH_OPTS       = -m32
  CFLAGS         += ${ARCH_OPTS} -fPIC -o $@
  LDOPTS         += ${ARCH_OPTS} -shared -L${MODEL_TECH} -lmtipli -o $@ $^
else
  # Set tools as absolute paths to avoid name clashes with
  # cygwin programs
  CC              = ${MSVC_ROOT}/VC/bin/cl.exe
  LD              = ${MSVC_ROOT}/VC/bin/link.exe
  DE1_PLI         = de1_pli.dll
  CFLAGS         += -Fo$@
  LDOPTS         += -dll $^ ${MODEL_TECH}/mtipli.lib Ws2_32.lib Shell32.lib -out:$@
endif

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: ${DE1_OUTDIR}/${DE1_PLI}

${DE1_OBJDIR}/%.obj: ${DE1_SRCDIR}/%.c ${DE1_SRCDIR}/de1_pli.h
	@mkdir -p ${DE1_OBJDIR}
	@${CC} -c ${CFLAGS} $< 

${DE1_OUTDIR}/${DE1_PLI}: ${DE1_OBJS} 
	@mkdir -p ${DE1_OUTDIR}
	@${LD} ${LDOPTS}

clean:
	@rm -rf ${DE1_OBJDIR} ${DE1_OUTDIR}




