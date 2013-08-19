#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>

char buffer [64];

int main(void)
{
	int s;
	s = MemoryRead(SWITCHES);
	print("Hello World ");
	MemoryWrite(LEDS_OUT, s);
	itoa_p(s, buffer, 10);
	printLine(buffer);

	// Expected Output:   Hello World NN
	// where NN is the value of the switches.

	return 0;
}