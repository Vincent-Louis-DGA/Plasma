
/*
// The following is a very simple Hello World Program with no external dependencies
#include <plasma.h>
//#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)
//#define MemoryRead(A) (*(volatile unsigned int*)(A))
//#define UART_TX	0x20000000
//#define UART_RX	0x20000004


void print(char * buf) {
	while(*buf != 0)
		MemoryWrite(UART_TX,*buf++);
}


int main(void) {
	int i;
	for(i = 0; i < 32; i+=4)
		MemoryWrite(0x220+i, (int)&test);
	test = (int)&test;
	MemoryWrite(LEDS_OUT,test);
	StackExercise(0);
	MemoryWrite(LEDS_OUT,test>>24);
	print("Hello World\n");
	while(1) { 
	}
}
*/




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


void StackExercise(int g)
{
	MemoryWrite(LEDS_OUT,g);
	if(g > 10000)
		print("\nStacked!\n");
	else
		StackExercise(g+1);
	
}

int * heap;

void HeapExercise()
{
	int s;

	heap = (int*)OS_GetHeap();
	s = (int)heap;
	MemoryWrite(LEDS_OUT,s>>24);
	MemoryWrite(LEDS_OUT,s>>16);
	MemoryWrite(LEDS_OUT,s>>8);
	MemoryWrite(LEDS_OUT,s);
	for(s = 0; s < 100; s++)
		heap[s] = s;
	for(s = 0; s < 100; s++)
		MemoryWrite(LEDS_OUT,s);
}


#include "Ethernet.c"

int main(void)
{
	int s,i;
	char buffer [64];
	
	*(int*)(0x10) = 0x1234567;

	print("Hello World\n");

	EthernetExercise();

	
	HeapExercise();

	StackExercise(0);

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
}
