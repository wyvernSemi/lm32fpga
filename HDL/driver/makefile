##########################################################
# 
# Copyright (c) 2017 Simon Southwell. All rights reserved.
#
# Date: 7th July 2017  
#
# The code is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this code. If not, see <http://www.gnu.org/licenses/>.
#
# $Id: makefile,v 1.2 2017/08/28 14:05:48 simon Exp $
# $Source: /home/simon/CVS/src/cpu/mico32/HDL/driver/makefile,v $
# 
##########################################################

##########################################################
# Definitions
##########################################################

TARGET   = lm32_driver

OSTYPE_S =$(shell uname -s)

SRCDIR   = src
LIBS     = lib/libftd2xx.a
OBJDIR   = obj

SRC      = lm32_driver.cpp lm32_driver_elf.cpp
HDRS     = lm32_driver.h lm32_driver_elf.h USB_JTAG.h
OBJS     = ${SRC:%.cpp=%.o}

CC       = g++
LD       = g++
CFLAGS   = -g -c -Wno-write-strings
LDFLAGS  = -ldl -lpthread

.SILENT:

##########################################################
# Build rules
##########################################################

ifneq ($(OSTYPE_S),Linux)
${TARGET}:
	..\..\runmsbuild.bat ${TARGET}
else
${OBJDIR}/%.o : ${SRCDIR}/%.cpp ${HDRS:%=${SRCDIR}/%}
	mkdir -p ${OBJDIR}
	$(CC) $(CFLAGS) $< -o $@

${TARGET} : ${OBJS:%=${OBJDIR}/%}
	$(LD) $^ ${LIBS} ${LDFLAGS} -o ${TARGET}
endif

##########################################################
# Clean up
##########################################################

clean:
	rm -rf ${OBJDIR}/*.o ${TARGET}
