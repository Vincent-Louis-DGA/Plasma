Plasma 32-bit MIPS Microprocessor

Plasma is a 32-bit MIPS compatible microprocessor core for FPGAs. This project includes VHDL code for the core, C code for example designs and a C# BootLoader project.

This design is an extension of work by Steve Rhoades at http://opencores.org/project,plasma

I have modified the design to target the Digilent ATLYS Spartan-6 FPGA Development Board, http://www.digilentinc.com/Products/Detail.cfm?Prod=ATLYS

Development environment is MS Windows 7, Xilinx ISE v13.3, MS Visual C++ Express 2010, MS Visual C# Express 2010.




Disclaimer:

MIPS(R) is a registered trademark and MIPS I(TM) is a trademark of MIPS Technologies, Inc. in the United States and other countries. MIPS Technologies, Inc. does not endorse and is not associated with this project. OpenCores, Steve Rhoads and Adrian Jongenelen are not affiliated in any way with MIPS Technologies, Inc.

The Plasma CPU project has been placed into the public domain by its original author and is free for commercial and non-commercial use. 

This software is provided "as is" and any express or implied warranties, including, but not limited to, the implied warranties of merchantability and fitness for a particular purpose are disclaimed.




Project Structure:

vhdl	:	VHDL code for FPGA and example Xilinx ISE v13.3 projects for the ATLYS board.
c	:	C code for example microprocessor code and MS Visual C++ 2010 Express Makefile projects.
cs	:	C# code for a boot loader application and MS Visual C# 2010 Express project.
Tools	:	Collection of executables for C code MIPS compilation and C library files.