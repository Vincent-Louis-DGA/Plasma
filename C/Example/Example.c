#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>



int main(void)
{
	int s;
	int len = 0;
	char buffer [64];
	s = MemoryRead(SWITCHES);
	print("Hello World ");
	MemoryWrite(LEDS_OUT, s);
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