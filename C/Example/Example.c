

// The following is a very simple Hello World Program with no external dependencies

#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)
#define UART_TX	0x20000000

void print(char * buf) {
	while(*buf != 0)
		MemoryWrite(UART_TX,*buf++);
}

int main(void) {
	print("Hello World\n");
	while(1) { }
}


/*
#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>

int count = 0;

void InterruptServiceRoutine(int status)
{
	count++;
	MemoryWrite(IRQ_STATUS_CLR,status);
	MemoryWrite(LEDS_OUT, count);
}

int main(void)
{
	int s;
	int len = 0;
	char buffer [64];


	// demonstrate some simple instructions
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	s = MemoryRead(SWITCHES);
	s = s + 1;
	MemoryWrite(LEDS_OUT, s);
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");
	asm("nop");

	
	s = MemoryRead(SWITCHES);
	s = s + 1;
	
	// Example Interrupt setup
	MemoryWrite(IRQ_STATUS,0);	// Clear all interrupts
	MemoryWrite(IRQ_VECTOR, (unsigned int)InterruptServiceRoutine); // interrupt vector to ISR
	MemoryWrite(IRQ_MASK,0xFF);	// Enable specific interrupts.
	OS_AsmInterruptEnable(1);	// Global enable.
	
	MemoryWrite(LEDS_OUT, s);

	print("Hello World ");
	itoa_p(s, buffer, 10);
	printLine(buffer);

	// Expected Output: Hello World NN
	// where NN is the value of the switches.

	while(1)
	{
		s = readChar();
		writeChar(s);
	}
	return 0;
}*/