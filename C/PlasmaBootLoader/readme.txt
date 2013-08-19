========================================================================
    MAKEFILE PROJECT : PlasmaBootLoader Project Overview
========================================================================

Boot loader code for Plasma 32-bit MIPS Microprocessor.

The purpose of this code is to act as a lightweight application that is run
on system reset.  The application is designed to receive new program code
(.bin file) on the UART port, copy it to local memory and then jump to it.  
In the future I would also like to add the default option of reading program 
code from Flash ROM.

This code implements the full application boot sequence, that includes 
initialising the stack. See Plasma/Tools/lib/boot_os.s for details.
The code begins at offset 0x00, ie, it runs directly from reset.
It is intended that this code be stored in FPGA Block RAM and hard-wired
into the VHDL design.


User Guide:


1) While pressing reset (FPGA system reset) simultaneously press BTNR.
2) Connect via UART at 460.8 kHz baud, 8 data bits, 0 parity, 1 stop bit.
3) Transmit a 32-bit integer specifying length in bytes of .bin file.
4) Send 32-bit integer address of new application offset.
5) Send the .bin file, padding out to a multiple of 4 bytes.
6) Boot loader will echo everything, and immediately begin the new program.