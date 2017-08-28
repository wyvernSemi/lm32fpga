###################################################################
#
# Copyright (c) 2017 Simon Southwell.
#
# This file is part of cpumico32.
#
# This code is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this code. If not, see <http://www.gnu.org/licenses/>.
#
# $Id: makefile,v 1.1 2017/06/25 06:30:01 simon Exp $
# $Source: /home/simon/CVS/src/cpu/mico32/HDL/registers/makefile,v $
#
###################################################################

OUTPUTS  = regs.h regs.vh regs.s
SRC      = registers.xlsx
PY_DIR   = ../../python

all : ${OUTPUTS}

regs.% : ${SRC}
	@python3 ${PY_DIR}/reg_gen.py ${SRC}
	
clean:
	@rm -rf ${OUTPUTS}
	
