
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
	MemoryWrite(LEDS_OUT,0x77);
	nothing(0);
	print("Hello World\n");
	while(1) { 
	}
}*/



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

void StackExercise(int g)
{
	MemoryWrite(LEDS_OUT,g);
	if(g > 100)
		print("\nStacked!\n");
	else
		StackExercise(g+1);
}

#define ETHER_WRITE 0x20010000
#define ETHER_RD_AD 0x20010004
#define ETHER_READ	0x20010008
#define ETHER_STATUS 0x2001000C
#define ETHER_TX_PRD 0x20010010
#define ETHER_RX_PRD 0x20010014
#define ETHER_RXD	0x20010020

void EthernetExercise(char * buffer)
{
	int i, s, len;

	buffer[0] = ' ';
	buffer[1] = ' ';
	buffer[2] = ' ';

	for(i = 0; i < 2; i++)
	{

	while((MemoryRead(ETHER_STATUS) & 1) == 0);
	MemoryWrite(ETHER_RD_AD, i << 24);
	while((MemoryRead(ETHER_STATUS) & 1) == 0);
	s = MemoryRead(ETHER_READ);
	
	len = itoa_p(i, buffer, 16);
	buffer[len] = ' ';
	itoa_p(s, buffer+3, 16);
	printLine(buffer);
	
	}

	s = MemoryRead(ETHER_TX_PRD);
	itoa_p((s*625)>>5, buffer, 10);
	print("TxPrd ");
	printLine(buffer);
	s = MemoryRead(ETHER_RX_PRD);
	itoa_p((s*625)>>5, buffer, 10);
	print("RxPrd ");
	printLine(buffer);

	MemoryWrite(ETHER_STATUS, 0x8); // RxFifoClear
	while(UART_TX_RDY)
	{
		while((MemoryRead(ETHER_STATUS) & 2) != 0);
		s = MemoryRead(ETHER_RXD);
		writeChar(s);
	}
}


int main(void)
{
	int s,i;
	int len = 0;
	char buffer [64];
	
	EthernetExercise(buffer);

	
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
