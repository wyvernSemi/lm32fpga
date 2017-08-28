

[Setup]
AppName                 = HDLMICO32
AppVerName              = HDLMICO32_3_16
DefaultDirName          = {pf}\mico32
DisableProgramGroupPage = yes
OutputBaseFilename      = setup_hdlmico32_3_16

[Files]
; This inno file
Source: "hdlmico32.iss";                                DestDir: "{app}"
Source: "LICENCE.txt";                                  DestDir: "{app}"
Source: "runmsbuild.bat";                               DestDir: "{app}"

; Documentation
Source: "doc\HW_README.pdf";                            DestDir: "{app}\doc"; Flags: isreadme

; Driver MSVC files (Express 10)
Source: "HDL\driver\msvc\lm32_driver.sln";              DestDir: "{app}\HDL\driver\msvc"
Source: "HDL\driver\msvc\lm32_driver.vcxproj";          DestDir: "{app}\HDL\driver\msvc"
Source: "HDL\driver\msvc\lm32_driver.vcxproj.filters";  DestDir: "{app}\HDL\driver\msvc"
Source: "HDL\driver\msvc\lm32_driver.vcxproj.user";     DestDir: "{app}\HDL\driver\msvc"

; Driver code libraries from Future Technology Devices International (FTDI)
Source: "HDL\driver\lib\ftd2xx.dll";                    DestDir: "{app}\HDL\driver\lib"
Source: "HDL\driver\lib\FTD2XX.lib";                    DestDir: "{app}\HDL\driver\lib"
Source: "HDL\driver\lib\libftd2xx.a";                   DestDir: "{app}\HDL\driver\lib"
Source: "HDL\driver\lib\libftd2xx.so.1.3.6";            DestDir: "{app}\HDL\driver\lib"
Source: "HDL\driver\lib\libftd2xx32.a";                 DestDir: "{app}\HDL\driver\lib"
Source: "HDL\driver\lib\libftd2xx32.so.1.3.6";          DestDir: "{app}\HDL\driver\lib"

Source: "HDL\driver\makefile";                          DestDir: "{app}\HDL\driver"

; FTDI headers
Source: "HDL\driver\src\ftd2xx.h";                      DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\USB_JTAG.h";                    DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\WinTypes.h";                    DestDir: "{app}\HDL\driver\src"

; Driver source code
Source: "HDL\driver\src\lm32_driver.cpp";               DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\lm32_driver.h";                 DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\lm32_driver_elf.cpp";           DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\lm32_driver_elf.h";             DestDir: "{app}\HDL\driver\src"
Source: "HDL\driver\src\getopt.c";                      DestDir: "{app}\HDL\driver\src"

; Register definitions
Source: "HDL\registers\registers.xlsx";                 DestDir: "{app}\HDL\registers"
Source: "HDL\registers\makefile";                       DestDir: "{app}\HDL\registers"

; Test harness
Source: "HDL\test\de1_top.vc";                          DestDir: "{app}\HDL\test"
Source: "HDL\test\lm32.vc";                             DestDir: "{app}\HDL\test"
Source: "HDL\test\test.vc";                             DestDir: "{app}\HDL\test"
Source: "HDL\test\test_harness.vc";                     DestDir: "{app}\HDL\test"
Source: "HDL\test\makefile";                            DestDir: "{app}\HDL\test"
Source: "HDL\test\test.hex";                            DestDir: "{app}\HDL\test"
Source: "HDL\test\bss.hex";                             DestDir: "{app}\HDL\test"
Source: "HDL\test\radix.do";                            DestDir: "{app}\HDL\test"

Source: "HDL\test\verilog\test.v";                      DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\test_defs.vh";                DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\sram.v";                      DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\sdram.v";                     DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\monitor.v";                   DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\jtag_drv.v";                  DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\uart_drv.v";                  DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\i2c_drv.v";                   DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\PLL1_sim.v";                  DestDir: "{app}\HDL\test\verilog"
Source: "HDL\test\verilog\CLK_LOCK_sim.v";              DestDir: "{app}\HDL\test\verilog"

Source: "HDL\test\pli\de1_pli.c";                       DestDir: "{app}\HDL\test\pli"
Source: "HDL\test\pli\de1_pli.h";                       DestDir: "{app}\HDL\test\pli"
Source: "HDL\test\pli\veriuser.c";                      DestDir: "{app}\HDL\test\pli"
Source: "HDL\test\pli\makefile";                        DestDir: "{app}\HDL\test\pli"

; Top level RTL
Source: "HDL\rtl\alt_lm32.vc";                          DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\alt_lm32.v";                           DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\lm32_config.v";                        DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\address_decode.v";                     DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\controller.v";                         DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\usb_jtag_cmd.v";                       DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\wb_mux.v";                             DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\lm32_wrap.v";                          DestDir: "{app}\HDL\rtl"

; Top level modified files from DE1 examples
Source: "HDL\rtl\CMD_Decode.v";                         DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\USB_JTAG.v";                           DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\Flash_Command.vh";                     DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\RS232_Command.vh";                     DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\SEG7_LUT.v";                           DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\SEG7_LUT_4.v";                         DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\I2C_Controller.v";                     DestDir: "{app}\HDL\rtl"

Source: "HDL\rtl\Sdram_Controller\Sdram_Controller.v";  DestDir: "{app}\HDL\rtl\Sdram_Controller"
Source: "HDL\rtl\Sdram_Controller\command.v";           DestDir: "{app}\HDL\rtl\Sdram_Controller"
Source: "HDL\rtl\Sdram_Controller\control_interface.v"; DestDir: "{app}\HDL\rtl\Sdram_Controller"
Source: "HDL\rtl\Sdram_Controller\sdr_data_path.v";     DestDir: "{app}\HDL\rtl\Sdram_Controller"
Source: "HDL\rtl\Sdram_Controller\Sdram_params.h";      DestDir: "{app}\HDL\rtl\Sdram_Controller"

; Altera Quartus II generated files
Source: "HDL\rtl\PLL1.v";                               DestDir: "{app}\HDL\rtl"
Source: "HDL\rtl\CLK_LOCK.v";                           DestDir: "{app}\HDL\rtl"

; Python support code
Source: "python\de1.pyw";                               DestDir: "{app}\python"
Source: "python\de1.gif";                               DestDir: "{app}\python"
Source: "python\reg_gen.py";                            DestDir: "{app}\python"
Source: "python\xlrd\*";                                DestDir: "{app}\python\xlrd"

; Altera synthesis files
Source: "HDL\synth\altera\alt_lm32.qpf";                DestDir: "{app}\HDL\synth\altera"
Source: "HDL\synth\altera\alt_lm32.qsf";                DestDir: "{app}\HDL\synth\altera"
Source: "HDL\synth\altera\alt_lm32.sdc";                DestDir: "{app}\HDL\synth\altera"
Source: "HDL\synth\altera\alt_lm32.srf";                DestDir: "{app}\HDL\synth\altera"
Source: "HDL\synth\altera\makefile";                    DestDir: "{app}\HDL\synth\altera"
Source: "HDL\synth\altera\synth_file_paths.tcl";        DestDir: "{app}\HDL\synth\altera"

; Test source code
Source: "test\exceptions\instruction\test.s";          DestDir: "{app}\test\exceptions\instruction"
Source: "test\instructions\add\test.s";                DestDir: "{app}\test\instructions\add"
Source: "test\instructions\and\test.s";                DestDir: "{app}\test\instructions\and"
Source: "test\instructions\branch_cond\test.s";        DestDir: "{app}\test\instructions\branch_cond"
Source: "test\instructions\branch_uncond\test.s";      DestDir: "{app}\test\instructions\branch_uncond"
Source: "test\instructions\cmp_e_ne\test.s";           DestDir: "{app}\test\instructions\cmp_e_ne"
Source: "test\instructions\cmpg\test.s";               DestDir: "{app}\test\instructions\cmpg"
Source: "test\instructions\cmpge\test.s";              DestDir: "{app}\test\instructions\cmpge"
Source: "test\instructions\div\test.s";                DestDir: "{app}\test\instructions\div"
Source: "test\instructions\load\test.s";               DestDir: "{app}\test\instructions\load"
Source: "test\instructions\mul\test.s";                DestDir: "{app}\test\instructions\mul"
Source: "test\instructions\or\test.s";                 DestDir: "{app}\test\instructions\or"
Source: "test\instructions\sext\test.s";               DestDir: "{app}\test\instructions\sext"
Source: "test\instructions\sl\test.s";                 DestDir: "{app}\test\instructions\sl"
Source: "test\instructions\sr\test.s";                 DestDir: "{app}\test\instructions\sr"
Source: "test\instructions\store\test.s";              DestDir: "{app}\test\instructions\store"
Source: "test\instructions\sub\test.s";                DestDir: "{app}\test\instructions\sub"
Source: "test\instructions\template\test.s";           DestDir: "{app}\test\instructions\template"
Source: "test\instructions\xor\test.s";                DestDir: "{app}\test\instructions\xor"
Source: "test\mmu\tlb\test.s";                         DestDir: "{app}\test\mmu\tlb"
Source: "test\runtest.py";                             DestDir: "{app}\test"

