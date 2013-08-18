#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
//#include <plasma.h>

unsigned char uartRx;
int kb;
int ExRam [RAM_EXTERNAL_SIZE/4];
unsigned char leds;
unsigned char switches = 0x69;
unsigned char buttons = 0x10;
unsigned char pmod_in =  0xFE;
unsigned char pmod_out = 0x00;
unsigned char pmod_tris = 0xFF;
unsigned char baudDiv = 0x07;
unsigned char intEnable = 0;

int PeriphRead(int addr)
{
	addr += PERIPH_BASE;
	if(addr >= RAM_EXTERNAL_BASE && addr < RAM_EXTERNAL_BASE + RAM_EXTERNAL_SIZE)
		return ExRam[addr-RAM_EXTERNAL_BASE];

	switch(addr)
	{
	case UART_STATUS:
		// check for console key press.
		kb = _kbhit();
		if(kb == 0)
			return 0;
		uartRx = _getch();
		return 0x08;

	case UART_RX:
		return uartRx;
	case UART_BAUD_DIV:
		return baudDiv;
	case RAND_GEN:
		return rand() + (rand() << 14) + (rand() << 28);
	case LEDS_OUT:
		return leds;
	case BUTTONS:
		return buttons;
	case SWITCHES:
		return switches;
	case PMOD_OUT:
		return pmod_out;
	case PMOD_IN:
		return (pmod_in & pmod_tris) | (pmod_out & ~pmod_tris) | (pmod_out & pmod_in);
	case PMOD_TRIS:
		return pmod_tris;
	}
	
	return 0;
}

void PeriphWrite(int addr, int value)
{
	addr += PERIPH_BASE;
	if(addr >= RAM_EXTERNAL_BASE && addr < RAM_EXTERNAL_BASE + RAM_EXTERNAL_SIZE)
	{
		ExRam[addr-RAM_EXTERNAL_BASE] = value;
		return;
	}

	switch(addr)
	{
	case UART_TX:
		printf("%c",(char)value);
		return;
	case UART_BAUD_DIV:
		baudDiv = value;
		return;
	case LEDS_OUT:
		leds = value;
		return;
	case LEDS_SET:
		leds |= value;
		return;
	case LEDS_CLR:
		leds &= (~value);
		return;
	case LEDS_TGL:
		leds ^= value;
		return;
	case PMOD_OUT:
		pmod_out = value;
		return;
	case PMOD_TRIS:
		pmod_tris = value;
		return;
	case PMOD_SET:
		pmod_out |= value;
		return;
	case PMOD_CLR:
		pmod_out &= (~value);
		return;
	case PMOD_TGL:
		pmod_out ^= value;
		return;
	}
	
}

int OS_AsmInterruptEnable(int enable)
{
	int v0 = intEnable;
	intEnable = enable;
	return v0;
}