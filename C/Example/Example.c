#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>

int count = 0;

void InterruptServiceRoutine(int status)
{
	MemoryWrite(IRQ_STATUS_CLR,status);
	count++;
	MemoryWrite(LEDS_OUT,count);

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
	
	MemoryWrite(IRQ_STATUS,0);	// Clear all interrupts
	MemoryWrite(IRQ_VECTOR, (unsigned int)InterruptServiceRoutine); // interrupt vector to ISR
	MemoryWrite(IRQ_MASK,0xFF);	// Enable specific interrupts.
	OS_AsmInterruptEnable(1);	// Global enable.

	print("Hello World ");
	itoa_p(s, buffer, 10);
	printLine(buffer);

	// Expected Output: Hello World NN
	// where NN is the value of the switches.

	while(1)
	{
		s = readChar();
		MemoryWrite(LEDS_OUT,s);
		writeChar(s);
	}
	return 0;
}