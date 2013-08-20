/*
	Plasma Core Boot Loader
	To put into UART Boot Loading mode, reset cpu while holding down BTNR.
	To load a .bin file via UART:
	(0. Use UART Baud of 460800, 8 data bits, 0 parity, 1 stop)
	1.	Send 32-bit integer specifying length in bytes of .bin file.
	2.	Send 32-bit address of new boot offset.
	3.	Send the file (pad out to multiple of 4 if needed).
	4.	Boot loader will echo everything.

	TODO: write code to load from Flash ROM. This would be useful...
*/

#include <plasma.h>
#include <plasma_stdio.h>

void ISR(int status)
{
	MemoryWrite(PMOD_TRIS, 0x00);
	MemoryWrite(PMOD_OUT, 0xFA);
	MemoryWrite(IRQ_STATUS, status);
}

unsigned char rxBuf[4];
int offset;

void FlashBootLoad()
{
	// TODO: Load from Flash.
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
	// Set baud to 460800
	MemoryWrite(UART_BAUD_DIV, 1);
	MemoryWrite(LEDS_OUT, 0xAA);
	
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
	offset = 0;
	MemoryWrite(LEDS_OUT, 0x55);
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
