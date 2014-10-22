#include <plasma_stdio.h>
#include <plasma.h>

// Prints a null-terminated string to STDOUT (does not write terminating null).
void print(char * buf)
{
	while(*buf != 0)
		printChar(*buf++);
}
// Prints a null-terminated string to STDOUT, and terminates with a newline.
void printLine(char * buf)
{
	print(buf);
	print("\n\r");
}
/* Blocking write to STDIN */
int write(char * buf, int len)
{
	int i;
	for(i = 0; i < len; i++)
		writeChar(buf[i]);
	return len;
}
/* Non-blocking read from STDIN. len parameter is max number of bytes to read.
	If less than this is available, function will quit early and return actual
	number of bytes read		*/
int read (char * buf, int len)
{
	int ret = 0;
	while(ret < len && (MemoryRead(UART_STATUS) & UART_RX_DV_MASK) == UART_RX_DV_MASK)
	{
		buf[ret++] = MemoryRead(UART_RX);
	}
	return ret;
}
/* Blocking read from STDIN */
unsigned char readChar()
{
	while((MemoryRead(UART_STATUS) & UART_RX_DV_MASK) == 0);
	return (unsigned char)MemoryRead(UART_RX);
}

/* Blocking readLine from STDIN */
int readLine(char * buf, int maxChars, int echo)
{
	int n;
	for(n = 0; n < maxChars; n++)
	{
		buf[n] = readChar();
		if(echo)
			writeChar(buf[n]);
		if(buf[n] == '\b')
			n-=2;
		if(buf[n] == '\n')
		{
			n--;
			break;
		}
	}
	buf[n] = 0;
	return n;
}

/* Blocking write to STDIN */
void writeChar(unsigned char c)
{
	while((MemoryRead(UART_STATUS) & UART_TX_FULL_MASK) > 0);
	printChar(c);
}

/*
	A blocking delay of approximate milliseconds.
*/
void Sleep(unsigned int milliseconds)
{
	int m;
	unsigned int start;
	for(m = 0; m < milliseconds; m++)
	{
		start = MemoryRead(COUNTER2);
		while((MemoryRead(COUNTER2) - start) < 10000);
	}
}
