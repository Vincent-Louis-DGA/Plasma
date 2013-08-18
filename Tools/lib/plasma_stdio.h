/*
	A subset of stdio functions.
	Only the real basic ones. Sadly, doesn't include printf or other variadic print functions.
*/
#ifndef __MIPS_STDIO_H
#define __MIPS_STDIO_H

#define STDOUT	UART_TX			// STDOUT is UART
#define STDIN	UART_RX			// STDINT is also UART
#define	STDERR	UART_TX			// STDERR is also UART
#define UART_RX_DV_MASK		0x08	// Mask to single out RX Data Available bit.
#define UART_TX_FULL_MASK	0x01	// TX Not Full bit

#define printChar(C) (MemoryWrite(STDOUT,C))	// Prints a character to STDOUT

// Prints a null-terminated string to STDOUT.
void print(char * buf);	
// Prints a null-terminated string to STDOUT, and terminates with a newline.
void printLine(char * buf);	
/* Blocking write to STDIN */
int write(char * buf, int len);	
/* Non-blocking read from STDIN. len parameter is max number of bytes to read.
	If less than this is available, function will quit early and return actual
	number of bytes read		*/
int read(char * buf, int len);
/* Blocking read from STDIN */
unsigned char readChar();
/* Blocking write to STDIN */
void writeChar(unsigned char c);



#include <plasma_stdio.c>

#endif

