/*
	Plasma Core Boot Loader
	To put into UART Boot Loading mode, reset cpu while holding down BTNR.
	To load a .bin file via UART:
	(0. Use UART Baud of 460800, 8 data bits, 0 parity, 1 stop)
	1.	Send 32-bit integer specifying length in bytes of .bin file.
	2.	Send 32-bit address of new boot offset.
	3.	Send the file (pad out to multiple of 4 if needed).
	4.	Boot loader will echo everything.

*/

#include <plasma.h>
#include <plasma_stdio.h>
#include "FlashRam.c"

#define FLASH_OFFSET		0x180000		// Byte offset in FlashRAM to read from
#define DEFAULT_BOOT_OFFSET	0x40000000		// Default offset to load FlashRAM to
#define PROGRAM_LEN			0x8000			// Default (aka max) program length in FlashRAM

int offset;

void FlashBootLoad()
{
	int len;
	char * offsetPointer;
	FlashInit();
	offset = DEFAULT_BOOT_OFFSET;
	len = PROGRAM_LEN;
	offsetPointer = (char*)offset;
	MemoryWrite(LEDS_OUT, 0x3C);
	FlashReadMemory(FLASH_OFFSET, offsetPointer, len);
	
	MemoryWrite(LEDS_OUT, 0xC3);
}

int UartReadInt()
{
	int i,r = 0;
	for(i = 0; i < 4; i++)
	{
		r = (r << 8) + readChar();
		printChar(r);
	}
	return r;
}

void UartBootLoad()
{
	int checksum = 0;
	int len = 0;
	int val = 0;
	int i = 0;
	MemoryWrite(UART_CONTROL, 0x03);
	MemoryWrite(LEDS_OUT, 0x2A);
	
	// Read 32-bit length
	len = UartReadInt();
	MemoryWrite(LEDS_OUT, len);
	// Read 32-bit boot offset
	offset = UartReadInt();
	MemoryWrite(LEDS_OUT, offset);

	// Read 'len' bytes, writing out to BOOT_OFFSET
	for(i = 0; i < len; i+=4)
	{
		val = UartReadInt();
		MemoryWrite(LEDS_OUT, i);
		MemoryWrite(offset+i, val);
	}
	MemoryWrite(LEDS_OUT, 0xFF);
	readChar();
}

int main (void)
{
	// Set baud to 460800
	MemoryWrite(UART_BAUD_DIV, 1);
	offset = 0;
	MemoryWrite(LEDS_OUT, 0x54);
	while(offset == 0)
	{
		// If BTNR down, go into UartBootLoad routine.
		if((MemoryRead(BUTTONS) & BUTTON_RIGHT_MASK) > 0)
			UartBootLoad();
		else	// Load program from ROM
			FlashBootLoad();
	}
	
	MemoryWrite(LEDS_OUT, 0xFF);
	
	// Jump to BOOT_OFFSET
	((void (*)(void))offset)();

	return 0;
}
