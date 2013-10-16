#include <plasma.h>
//#include <plasma_stdio.h>
//#include <plasma_string.h>


#ifndef BUFFER_LEN 
#define BUFFER_LEN (RAM_SDRAM_SIZE/2)
#else
#warning Using user supplied BUFFER_LEN
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

char * buffer;

int main(void)
{
	int value,writeIndex,readIndex;
	int maxLen = (RAM_SDRAM_SIZE / 2);

	buffer = (char*)OS_GetHeap();
	MemoryWrite(0x30000008, 0);

	while(1)
	{
		MemoryWrite(LEDS_OUT, 0x99);
		value = MemoryRead(SWITCHES);
		
		MemoryWrite(0x30000004,0xA800CC11);		// Set the selector
		MemoryWrite(0x30000000, 1);			// Set the sample divider
		MemoryWrite(FIFO_CON, FIFO_CLEAR_MASK);
		writeIndex = 0;
		readIndex = 0;
		while(readIndex < maxLen)
		{
			if(writeIndex > readIndex && UART_TX_RDY)
			{
				value = buffer[readIndex];
				MemoryWrite(UART_TX, value);
				MemoryWrite(LEDS_OUT,readIndex>>10);
				readIndex++;
			}
			while(writeIndex < BUFFER_LEN && FIFO_DOUT_RDY)
			{
				value = MemoryRead(FIFO_DOUT);
				buffer[writeIndex] = value;
				writeIndex ++;
			}
			// Break early if CENTRE button pressed.
			if(BUTTON_CENTRE_DOWN)
				break;
		}
		MemoryWrite(LEDS_OUT,0xCC);
		// Wait for CENTRE button press
		while(!BUTTON_CENTRE_DOWN);
		while(BUTTON_CENTRE_DOWN);
	}

	return 0;
}
