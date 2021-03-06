# Boot offset is where the first instruction will reside in memory.
# For applications that run from reset set this to 0x0 and use boot_os.s for BOOT_FILE.
# For applications loaded by BootLoader, this can be any location in memory, eg, 0x40000000 for external RAM.
BOOT_OFFSET = 0x40000000

# boot.s does not initialize any kind of stack, and presupposes that this is done previously, eg, by BootLoader.
# boot_os.s initializes the stack, etc.  Use this if you wish the program to run from reset, as opposed to loaded 
# by Bootloader, eg, run it within a VHDL simulation.

BIN_MIPS = ..\..\Tools
PLASMA_LIB = $(BIN_MIPS)\lib
export CPATH = $(PLASMA_LIB)
PATH = %PATH%;$(BIN_MIPS)

CFLAGS = -O2 -Wall -c -s
CFLAGS += -fno-pic -mips1 -mno-abicalls

target:
	as.exe $(PLASMA_LIB)\boot_os.s -o boot_os.o
	gcc.exe $(CFLAGS) $(Target).c 
	ld.exe -Ttext 0x00000000 -e entry -Map $(Target)_boot.map -s -N \
		boot_os.o $(Target).o -o $(Target)_boot.axf
	objdump.bat $(Target)_boot.axf $(Target)_boot.lst
	ConvertAxfToVhdl.exe -i $(Target)_boot.axf -o Ram_Program.vhd
	ld.exe -Ttext $(BOOT_OFFSET) -e entry -Map $(Target).map -s -N \
		boot_os.o $(Target).o -o $(Target).axf
	objdump.bat $(Target).axf $(Target).lst
