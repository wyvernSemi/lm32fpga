## Generated SDC file "decoder.out.sdc"

## Copyright (C) 1991-2010 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 9.1 Build 304 01/25/2010 Service Pack 1 SJ Web Edition"

## DATE    "Sat Dec  4 14:55:08 2010"

##
## DEVICE  "EP2C20F484C7"
##


#*********************************************************
# Time Information
#*********************************************************

set_time_format -unit ns -decimal_places 3

#*********************************************************
# Create Clocks
#*********************************************************

#
# 50MHz input clock. Over specified (@ 66.67MHz), for adding timing margin.
#
create_clock -name {CLOCK_50} -period 15.000 -waveform { 0.000 7.500 } [get_ports {CLOCK_50}]

#
# TCK up to 18MHz (input pin TCK sampled with 40MHz clock in to regiser mTCK in USB_JTAG)
#
create_clock -name {TCK}  -period 50.000 -waveform { 0.000 25.000 } [get_ports {TCK}]
create_clock -name {mTCK} -period 50.000 -waveform { 0.000 25.000 } [get_registers {u1|u1|mTCK}]

#*********************************************************
# Create Generated Clock
#*********************************************************

#
# 40MHz generated clock
#
create_generated_clock -name {sys_clk}    -source [get_ports {CLOCK_50}] -multiply_by 4 -divide_by 5 -master_clock {CLOCK_50} [get_pins {p1|altpll_component|pll|clk[0]}] 
create_generated_clock -name {sdram_clk}  -source [get_ports {CLOCK_50}] -multiply_by 4 -divide_by 5 -master_clock {CLOCK_50} [get_pins {p1|altpll_component|pll|clk[1]}] 
 
#
# 80MHz generated clock (synchronous to 40MHz, but inverted)
#
create_generated_clock -name {sram_clk} -source [get_ports {CLOCK_50}] -multiply_by 8 -divide_by 5 -phase 180.0 -master_clock {CLOCK_50} [get_pins {p1|altpll_component|pll|clk[2]}] 


#*********************************************************
# Set Clock Latency
#*********************************************************


#*********************************************************
# Set Clock Uncertainty
#*********************************************************

set_clock_uncertainty -rise_from [get_clocks {sys_clk}] -rise_to [get_clocks {sys_clk}] -setup 0.800 
set_clock_uncertainty -rise_from [get_clocks {sys_clk}] -fall_to [get_clocks {sys_clk}] -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {sys_clk}] -rise_to [get_clocks {sys_clk}] -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {sys_clk}] -fall_to [get_clocks {sys_clk}] -setup 0.800

set_clock_uncertainty -rise_from [get_clocks {mTCK}]    -rise_to [get_clocks {mTCK}]    -setup 0.800 
set_clock_uncertainty -rise_from [get_clocks {mTCK}]    -fall_to [get_clocks {mTCK}]    -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {mTCK}]    -rise_to [get_clocks {mTCK}]    -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {mTCK}]    -fall_to [get_clocks {mTCK}]    -setup 0.800 

set_clock_uncertainty -rise_from [get_clocks {TCK}]     -rise_to [get_clocks {TCK}]     -setup 0.800 
set_clock_uncertainty -rise_from [get_clocks {TCK}]     -fall_to [get_clocks {TCK}]     -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {TCK}]     -rise_to [get_clocks {TCK}]     -setup 0.800 
set_clock_uncertainty -fall_from [get_clocks {TCK}]     -fall_to [get_clocks {TCK}]     -setup 0.800 

#*********************************************************
# Set Input Delay
#*********************************************************

# Quartus reports PS2* and AUD_ADCDAT as not matched with ports?

set_input_delay -clock sys_clk -max 0.4 [get_ports {KEY* SW* UART_RXD DRAM_DQ* DRAM_DQ* SRAM_DQ* FL_DQ* SD_DAT* I2C_SDAT TDI TCS TCK AUD_BCLK GPIO*}]
set_input_delay -clock sys_clk -min 0.3 [get_ports {KEY* SW* UART_RXD DRAM_DQ* DRAM_DQ* SRAM_DQ* FL_DQ* SD_DAT* I2C_SDAT TDI TCS TCK AUD_BCLK GPIO*}]

#*********************************************************
# Set Output Delay
#*********************************************************

set_output_delay -clock sys_clk -max 0.4 [get_ports {HEX* LED* UART_TXD DRAM* FL* SD* I2C* TDO VGA* GPIO* AUD*CK AUD_DAC*}]
set_output_delay -clock sys_clk -min 0.3 [get_ports {HEX* LED* UART_TXD DRAM* FL* SD* I2C* TDO VGA* GPIO* AUD*CK AUD_DAC*}]

# Use these constraints if SRAM WE not generated on sram_clk
#set_output_delay -clock sys_clk -max -fall   1.0 [get_ports {SRAM_WE_N}]
#set_output_delay -clock sys_clk -min -fall   0.5 [get_ports {SRAM_WE_N}]
#set_output_delay -clock sys_clk -max -rise  -0.5 [get_ports {SRAM_WE_N}]
#set_output_delay -clock sys_clk -min -rise  -1.0 [get_ports {SRAM_WE_N}]

#set_output_delay -clock sys_clk -max 2.0 [get_ports {SRAM_DQ* SRAM_ADDR* SRAM_UB_N SRAM_LB_N SRAM_CE_N SRAM_OE_N}]
#set_output_delay -clock sys_clk -min 1.5 [get_ports {SRAM_DQ* SRAM_ADDR* SRAM_UB_N SRAM_LB_N SRAM_CE_N SRAM_OE_N}]

#*********************************************************
# Set Clock Groups
#*********************************************************


#*********************************************************
# Set False Path
#*********************************************************

set_false_path -from [get_clocks {sys_clk}]      -to [get_clocks {mTCK}]
set_false_path -from [get_clocks {mTCK}]         -to [get_clocks {sys_clk}]

set_false_path -from [get_clocks {sys_clk}]      -to [get_clocks {TCK}]
set_false_path -from [get_clocks {TCK}]          -to [get_clocks {sys_clk}]

#*********************************************************
# Set Multicycle Path
#*********************************************************


#*********************************************************
# Set Maximum Delay
#*********************************************************


#*********************************************************
# Set Minimum Delay
#*********************************************************


#*********************************************************
# Set Input Transition
#*********************************************************

