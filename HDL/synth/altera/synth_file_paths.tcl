# =============================================================
#  
#  Copyright (c) 2017 Simon Southwell. All rights reserved.
# 
#  Date: 29th May 2017
# 
#  This code is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
# 
#  The code is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this code. If not, see <http://www.gnu.org/licenses/>.
# 
#  $Id: synth_file_paths.tcl,v 1.4 2017/08/22 09:17:32 simon Exp $
#  $Source: /home/simon/CVS/src/cpu/mico32/HDL/synth/altera/synth_file_paths.tcl,v $
# 
# =============================================================
#
# This TCL file defines the paths and RTL files used to contruct the alt_lm32
# system. It is targetted *specifically* towards the terasIC DE1 development
# board, which uses an Altera Cyclone II EP2C20 series FPGA, and relies on the
# specific memory and I/O configuration of that platform. The commands below
# are Quartus II .qsf file specific, and this file is meant to be sourced via
# a "set_global_assignment -name SOURCE_TCL_SCRIPT_FILE synth_file_paths.tcl"
# command in the .qsf file.
#
# More information on the DE1 platform can be found on the terasIC website:
#
#    https://www.terasic.com.tw/
#
# Details about the Quartus II software, Quartus settings file (.qsf) commands, 
# and Cyclone FPGAs can be found on the Intel-Altera website:
#
#    https://www.altera.com/
#
# The Lattice Semiconductor Diamond development suite, and the micosystem software,
# including the open licenced peripheral RTL, can be found on their website:
#
#    http://www.latticesemi.com
#
# The open source LatticeMico32, with MMU, by M-Labs can be found on GitHub
#
#    https://github.com/m-labs/lm32
#
# =============================================================

# Directory locations for third party RTL files. Modify to local system paths. 
# If possible, make relative paths to avoid Windows/Linux compatibility issues.
set LATTICE_MICO_COMPONENTS_ROOT         ../../../third_party/lscc/micosystem/components
set LM32_MMU_ROOT                        ../../../third_party/m-labs/lm32/rtl

# Directory location of top level RTL
set TOP_LEVEL_RTL_ROOT                   ../../rtl

# Directry for register definitions
set REGS_ROOT                            ../../registers

# Set up the search path for the major RTL directories
set_global_assignment -name SEARCH_PATH  $LATTICE_MICO_COMPONENTS_ROOT
set_global_assignment -name SEARCH_PATH  $LM32_MMU_ROOT
set_global_assignment -name SEARCH_PATH  $TOP_LEVEL_RTL_ROOT
set_global_assignment -name SEARCH_PATH  $TOP_LEVEL_RTL_ROOT/Sdram_Controller
set_global_assignment -name SEARCH_PATH  $REGS_ROOT

# Top level files (hierarchical RTL)
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/alt_lm32.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/controller.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/address_decode.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/usb_jtag_cmd.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/wb_mux.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/lm32_wrap.v

# terasIC Altera DE1 development board example files (modified)
# (specific to this platform)
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/CMD_Decode.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/SEG7_LUT.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/SEG7_LUT_4.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/USB_JTAG.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/I2C_Controller.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/Sdram_Controller/command.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/Sdram_Controller/control_interface.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/Sdram_Controller/sdr_data_path.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/Sdram_Controller/Sdram_Controller.v

# Altera Quartus II wizard generated files (clock generation components
# specific to the Altera Cyclone II devices)
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/PLL1.v
set_global_assignment -name VERILOG_FILE $TOP_LEVEL_RTL_ROOT/CLK_LOCK.v

# LM32 CPU (Modified LatticeMico32 with MMU, by M-Labs)
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_adder.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_addsub.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_cpu.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_dcache.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_debug.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_decoder.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_dp_ram.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_icache.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_instruction_unit.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_interrupt.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_jtag.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_load_store_unit.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_logic_op.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_mc_arithmetic.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_multiplier.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_ram.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_shifter.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_itlb.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_dtlb.v
set_global_assignment -name VERILOG_FILE $LM32_MMU_ROOT/lm32_top.v

# Lattice Semiconductor Mico system peripheral components
set_global_assignment -name VERILOG_FILE $LATTICE_MICO_COMPONENTS_ROOT/uart_core/rtl/uart_core.v
set_global_assignment -name VERILOG_FILE $LATTICE_MICO_COMPONENTS_ROOT/timer/rtl/timer.v
