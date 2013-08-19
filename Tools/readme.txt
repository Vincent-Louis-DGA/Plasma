Plasma/Tools

Contains tools for compiling C code to target MIPS processor.
See Plasma/C/Example for information on how to set up a MS Visual C++ 2010 Express makefile project.

Many of these tools are part of a typical gcc compiler toolchain, eg, as.exe, ld.exe, gcc.exe, objdump.exe.
Customised tools include convert_bin.exe which converts test.axf binary output (ELF file) into a stripped down MIPS binary format (test.bin) and a hex-text version (code.txt).
ram_image.exe inserts the binary code into a Xilinx VHDL block RAM source file.