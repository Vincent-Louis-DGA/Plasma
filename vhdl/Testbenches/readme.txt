Plasma/vhdl/Testbenches

The testbenches for the Plasma microprocessor have some unusual optimisations.
First of all, simulating the actual DDR RAM interface makes the design very
large, such that when using the Xilinx ISE Webpack version the simulation is
derated and progresses super slowly.  Also, simulating the PLL of the block
RAM design is also quite slow.  Therefore, the design has a generic parameter
called 'simulation', whereby setting it to '1' will use logic to generate the
clocks and the DDR RAM also uses a block RAM simulation that behaves fairly
similarly, ie, page reads, caching, etc.

Another optimisation is for the UART.  Normally it takes 24 us to transmit/
receive a byte. Simulated designs can use the uart_bypassXXX signals to inject
/read data directly into/from the UART Fifo buffers.