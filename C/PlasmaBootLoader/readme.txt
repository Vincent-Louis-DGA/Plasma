========================================================================
    MAKEFILE PROJECT : PlasmaBootLoader Project Overview
========================================================================

Boot loader code for Plasma 32-bit MIPS Microprocessor.

The purpose of this code is to act as a lightweight application that is run
on system reset.  The application is designed to receive new program code
(.bin file) on the UART port, copy it to local memory and then jump to it.  
By default it will load and execute a program from the Flash RAM.

This code implements the full application boot sequence, that includes 
initialising the stack. See Plasma/Tools/lib/boot_os.s for details.
The code begins at offset 0x00, ie, it runs directly from reset.
It is intended that this code be stored in FPGA Block RAM and hard-wired
into the VHDL design.


User Guide:

With no user intervention, the application will automatically load a program
from Flash RAM offset 0x180000, and will run install/run it from offset
0x40000000.  Maximum size of the program binary is 32 kB.

To load a program via UART do the following:

1) While pressing reset (FPGA system reset) simultaneously press BTNR.
2) Connect via UART at 460.8 kHz baud, 8 data bits, 0 parity, 1 stop bit.
3) Transmit a 32-bit integer specifying length in bytes of .bin file.
4) Send 32-bit integer address of new application offset.
5) Send the .bin file, padding out to a multiple of 4 bytes.
6) Boot loader will echo everything.
7) Transmit one more byte (can be anything) to start the new program.