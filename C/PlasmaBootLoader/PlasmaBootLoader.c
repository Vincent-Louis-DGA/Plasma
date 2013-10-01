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
#include "ElfReader.c"

#define FLASH_OFFSET		0x180000		// Byte offset in FlashRAM to read from

int FlashReadPosition = 0;

void InitFlash()
{
	FlashReadPosition = FLASH_OFFSET;
	FlashInit();
}

void ReadFlash(char * buffer, int len)
{
	FlashReadMemory(FlashReadPosition, buffer, len);
	FlashReadPosition += len;
}

void ReadAndEchoUart(char * buffer, int len)
{
	int i;
	for(i = 0; i < len; i++)
	{
		buffer[i] = readChar();
		MemoryWrite(UART_TX,buffer[i]);
	}
}

int main (void)
{
	int error = 0;
	int i = 0;
	
	// Set baud to 460800
	MemoryWrite(UART_BAUD_DIV, 1);
	MemoryWrite(LEDS_OUT, 0x54);

	// If BTNR down, Use Uart Read function.
	if((MemoryRead(BUTTONS) & BUTTON_RIGHT_MASK) > 0)
	{
		MemoryWrite(LEDS_OUT, 0x66);
		ElfSetReadFunctionPtr(ReadAndEchoUart);
	}
	else
	{
		InitFlash();
		ElfSetReadFunctionPtr(ReadFlash);
	}


	error = ElfReadFile();
	if(!error) 
	{
		MemoryWrite(LEDS_OUT, 0xFF);
		error = ElfBranch();
	}
	while(1)
	{
		MemoryWrite(LEDS_OUT,error);
		for(i = 0; i < 2000000; i++);
		MemoryWrite(LEDS_OUT,0);
		for(i = 0; i < 2000000; i++);
	}
}
