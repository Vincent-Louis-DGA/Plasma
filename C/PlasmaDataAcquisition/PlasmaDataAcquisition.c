#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>


#ifndef BUFFER_LEN 
#define BUFFER_LEN 0x2000000
char buffer [BUFFER_LEN];
#else
#warning Using user supplied BUFFER_LEN
char * buffer = (char*)0x40000000;
#endif

int countBits(int i)
{
	int r = 0;
	while(i > 0)
	{
		if((i & 1) == 1)
			r++;
		i = i >> 1;
	}
	return r;
}

int main(void)
{
	int i = 0;
	int v;
	int writeIndex;
	int readIndex;
	int maxLen = 0x2000000;

	if(maxLen > BUFFER_LEN)
		maxLen = BUFFER_LEN;

	MemoryWrite(0x30000008, 0);

	while(1)
	{
		MemoryWrite(LEDS_OUT, 0x99);
		v = MemoryRead(SWITCHES);
		
		MemoryWrite(0x30000004,0xA800CC40);					// Set the data mask
		MemoryWrite(0x30000000, countBits(v));	// Set the sample divider
		MemoryWrite(FIFO_CON, FIFO_CLEAR_MASK);				// Clear FIFO
		writeIndex = 0;
		readIndex = 0;
		while(readIndex < maxLen)
		{
			if(writeIndex > readIndex)
			{
				if(UART_TX_RDY)
				{
					v = buffer[readIndex];
					MemoryWrite(UART_TX, v);
					MemoryWrite(LEDS_OUT,readIndex>>10);
					readIndex++;
				}
			}
			while(FIFO_DOUT_RDY)
			{
				v = MemoryRead(FIFO_DOUT);
				if(writeIndex < BUFFER_LEN)
				{
					buffer[writeIndex] = v;
					writeIndex ++;
				}
				i++;
			}
			// Break early if CENTRE button pressed.
			if((MemoryRead(BUTTONS) & BUTTON_CENTRE_MASK) == BUTTON_CENTRE_MASK)
			{
				MemoryWrite(FIFO_CON, FIFO_CLEAR_MASK);				// Clear FIFO
				break;
			}
		}
		MemoryWrite(LEDS_OUT,0xCC);
		// Wait for CENTRE button press
		while((MemoryRead(BUTTONS) & BUTTON_CENTRE_MASK) == 0);
		MemoryWrite(FIFO_CON, FIFO_CLEAR_MASK);				// Clear FIFO
		while((MemoryRead(BUTTONS) & BUTTON_CENTRE_MASK) == BUTTON_CENTRE_MASK);
	}

	return 0;
}
