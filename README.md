# lm32fpga
FPGA development board (DE1) targetted LatticeMico32 based systems design, written in Verilog.

This project is a complementary project with the LatticeMico32 soft CPU Instruction Set Simulator project (https://github.com/wyvernSemi/mico32). In that project an ISS model was constructed based on the Lattice Semiconductor LM32, with UART and Timer peripherals and a test suite. This project is a hardware implementation of that model, including a simulation environment, and the ability to run a subset of the test suite of the ISS.

The project is targetted at a specific platform, the terasIC DE1 development board, based on an Intel/Altera Cyclone II FPGA (2C20). It has a ModelSim based test simulation environment and scripts to synthesise and program the target platform using Quartus II development software.
