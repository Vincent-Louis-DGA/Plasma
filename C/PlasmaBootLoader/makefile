BIN_MIPS = ..\..\Tools
PLASMA_LIB = $(BIN_MIPS)\lib
export CPATH = $(PLASMA_LIB)
PATH = %PATH%;$(BIN_MIPS)


CFLAGS = -O2 -Wall -c -s
CFLAGS += -fno-pic -mips1 -mno-abicalls

target:
	as.exe $(PLASMA_LIB)\boot_os.s -o boot_os.o --defsym StackLoc=0x8000
	gcc.exe $(CFLAGS) $(Target).c 
	ld.exe -Ttext 0x00000000 -e entry -Map $(Target).map -s -N \
		boot_os.o	$(Target).o -o test.axf
	objdump.bat test.axf $(Target).lst
	convert_bin.exe	# Creates test.bin and code.txt from test.axf
	ram_image.exe ram_xilinx.vhd \
		code.txt ram_$(Target).vhd
