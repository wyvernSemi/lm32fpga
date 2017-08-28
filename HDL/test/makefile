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
# $Id: makefile,v 1.7 2017/08/28 10:31:31 simon Exp $
# $Source: /home/simon/CVS/src/cpu/mico32/HDL/test/makefile,v $
#
###################################################################

# $MODELSIM and $MODEL_TECH environment variables must be set

TOP       = test

REGS_DIR  = ../registers
TESTDIR   = ../../test
VLOGFLAGS = -incr +define+SIM +incdir+${REGS_DIR}

# Define a list of warnings to suppress
#
#  3722 (Missing connection for port)
#  3017 (Too few port connections)
#
NOWARN    = 3017,3722

OSTYPE = $(shell uname)
# Target
ifeq (${OSTYPE}, Linux)
  DE1_PLI         = de1_pli.so
else
  DE1_PLI         = de1_pli.dll
endif

# Setting plusarg flag 'FINISH' to non-zero terminates, rather than stops,
# the simulation, if doing batch runs. Setting the plusarg flag 'DISABLE_GUI'
# to non-zero stops the python GUI from being used.
USRFLAGS  = +FINISH=0 +DISABLE_GUI=0

# Common flags for vsim
VSIMFLAGS = -pli ./pli/lib/${DE1_PLI} ${TOP} -suppress ${NOWARN} ${USRFLAGS}

# Options specific to a non-gui run
NONGUIFLAGS = -c ${VSIMFLAGS} -quiet -do "run -all"

#------------------------------------------------------
# BUILD RULES
#------------------------------------------------------

all: verilog

# Let modelsim decide what's changed in the verilog
.PHONY: verilog
verilog: pli ${REGS_DIR}/regs.vh
	@test -d "./work" ||  vlib work
	@vlog ${VLOGFLAGS} ${VUSRFLAGS} -f test.vc    

.PHONY: pli
pli:
	@make -C pli

.PHONY: ${REGS_DIR}/regs.vh
${REGS_DIR}/regs.vh :
	@make -C ${REGS_DIR}

#------------------------------------------------------
# EXECUTION RULES
#------------------------------------------------------

# Straight forward run, with build update
run: verilog
	@vsim ${NONGUIFLAGS}

# Fire up GUI with build update. Use wave.do if it exists to add wave signals,
# but do not start run.
rungui: verilog
	@if [ -e wave.do ]; then                           \
          vsim -gui -do wave.do ${VSIMFLAGS};          \
    else                                               \
          vsim -gui ${VSIMFLAGS};                      \
    fi

# No-build run
.PHONY:runnb
runnb:
	@vsim ${NONGUIFLAGS}

regression: verilog
	@cd ${TESTDIR};python3 ./runtest.py -s

# Shorthand for rungui
gui: rungui

#------------------------------------------------------
# CLEANING RULES
#------------------------------------------------------

clean:
	@make -C pli clean
	@test ! -d "./work" || vdel -lib work -all
	@rm -rf test_elf.hex

