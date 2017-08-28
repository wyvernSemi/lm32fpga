##############################################################
# 
# Copyright (c) 2017 Simon Southwell
# All rights reserved.
# 
# Date: 22nd May 2017
# 
# This file is part of alt_lm32.
#
# This code is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this code. If not, see <http://www.gnu.org/licenses/>.
#
# $Id: makefile,v 1.4 2017/07/08 06:06:35 simon Exp $
# $Source: /home/simon/CVS/src/cpu/mico32/HDL/synth/altera/makefile,v $
# 
##############################################################
# Make file for synthesising alt_lm32 for terasIC DE1 Cyclone II 
# development board
##############################################################

#
# Define the project name (assumes $PROJECT.qpf exists locally)
#
PROJECT  = alt_lm32

SYNDIR   = ./
TESTDIR  = ../../../test
REGSDIR  = ../../registers
REGSSRC  = registers.xlsx
REGSFILE = regs.vh
CABLE    = USB-Blaster

##########################################################
# Dependencies on user targets
##########################################################

all : ${SYNDIR}/${PROJECT}.sta.rpt

map: ${SYNDIR}/${PROJECT}.map.rpt
fit: ${SYNDIR}/${PROJECT}.fit.rpt
asm: ${SYNDIR}/${PROJECT}.asm.rpt
sta: ${SYNDIR}/${PROJECT}.sta.rpt

##########################################################
# Rules for all steps: map, fit, assembly and STA
##########################################################

${PROJECT}.map.rpt: ${PROJECT}.qpf ${PROJECT}.qsf ${PROJECT}.sdc ${REGSDIR}/${REGSFILE}
	@quartus_map ${PROJECT}.qpf --write_settings_files=off

${PROJECT}.fit.rpt: ${SYNDIR}/${PROJECT}.map.rpt
	@quartus_fit ${PROJECT}.qpf --write_settings_files=off

${PROJECT}.asm.rpt: ${SYNDIR}/${PROJECT}.fit.rpt
	@quartus_asm ${PROJECT}.qpf --write_settings_files=off
    
${PROJECT}.sta.rpt: ${SYNDIR}/${PROJECT}.asm.rpt
	@quartus_sta ${PROJECT}.qpf --sdc=${PROJECT}.sdc

${REGSDIR}/${REGSFILE} : ${REGSDIR}/${REGSSRC}
	@make -C ${REGSDIR}
    
##########################################################
# Device programming rule
##########################################################

# Program the platform (with build)
prog: ${SYNDIR}/${PROJECT}.sta.rpt prognb

# Program the platform (with no build)
.PHONY: prognb
prognb:
	@quartus_pgm -c ${CABLE} -m JTAG -o "P;${PROJECT}.sof@1"

##########################################################
# Executions rules
##########################################################

regression: prog
	@make -C ../../driver
	@cd ${TESTDIR};python3 ./runtest.py -H

##########################################################
# Clean
##########################################################

clean:
	@rm -rf db incremental_db *.rpt *.smsg *.summary *.pin *.pof *.sof *.done *.jdi *.qws
