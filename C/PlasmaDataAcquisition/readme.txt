========================================================================
    MAKEFILE PROJECT : PlasmaDataAcquisition Project Overview
========================================================================

Plasma/C/PlasmaDataAcquisition

This application demonstrates use of the general purpose FIFOs of the Plasma cpu
to buffer sampled digital data in RAM and transmit to the PC over UART.

It is designed to work with the PlasmaDataAcquisition.vhd ISE project, ie, it
expects the FIFOs to be filled using external logic. The ExBus is used to set
the sample rate and which channels to record. 

Sample rate is set by a divider mapped to register address 0x30000000. To
calculate use:  Fs = 2e6 / (1+divider).
Maximum data rate across all channels is 2 MB/s, ie, 4 channels, sample rate
must be no more than 500 kHz, or divider = 3.

To select which channels to record use the data mask register at 0x30000004.
Select channels by writing a '1' in the corresponding bit position.
b0	:	PMOD
b1	:	Switches
b2	:	buttons
b3	:	nonsense (ASCII characters 0-7)
b4	:	2 MHz counter bits(7 downto 0)
b5	:	2 MHz counter bits(15 downto 8)
b6	:	2 MHz counter bits(23 downto 8)
b7	:	2 MHz counter bits(31 downto 24)