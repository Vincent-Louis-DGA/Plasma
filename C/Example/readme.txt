========================================================================
    MAKEFILE PROJECT : Example Project Overview
========================================================================

A simple Plasma 32-bit MIPS makefile project.

Application transmits "Hello World" out of the UART, writes value of switches to LEDS and transmits value of switches out UART.

Upon successful compilation there are two outputs of interest: 
1) Example.bin:		the program binary that would be transmitted to the boot loader via UART, and
2) ram_Example.vhd:	a VHDL file describing block RAM for hard-wiring the design at memory location 0x00.

NB: Main program file Example.c is named as per the project. This is a pattern I use for all the C projects.



Customised project settings for Project Properties > Configuration Properties:

General/Configuration Type: 	Makefile
NMake/Build Command Line:		gmake target Target=$(TargetName) && move /Y test.bin $(TargetName).bin
NMake/Rebuild All Command Line:	gmake target Target=$(TargetName) && move /Y test.bin $(TargetName).bin
Clean Command Line:				del *.o *.map *.lst *.axf *.bin code.txt
Output:							$(TargetName).exe
Preprocessor Definitions:		WIN32;_DEBUG;$(NMakePreprocessorDefinitions)
Include Search Path:			..\..\Tools\lib;c:\program files (x86)\microsoft visual studio 10.0\vc\include
			