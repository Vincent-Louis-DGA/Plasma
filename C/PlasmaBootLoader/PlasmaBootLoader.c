/*
	Plasma Core Boot Loader
	To put into UART Boot Loading mode, reset cpu while holding down BTNR.
	To load a .bin file via UART:
	(0. Use UART Baud of 460800, 8 data bits, 0 parity, 1 stop)
	1.	Send 32-bit integer specifying length in bytes of .bin file.
	2.	Send 32-bit address of new boot offset.
	3.	Send the file (pad out to multiple of 4 if needed).
	4.	Boot loader will echo everything.
*/

#include <plasma.h>
#include <plasma_stdio.h>

// $zero = 0, $v0 = 00010, $v1 = 00011, $a0 = 00100, $status = CPR[0,01100,0]

#define BOOT_OFFSET 0x00001000
int StaticProgramLen = 7;
int StaticProgram[] = {	
	0x34020007,	//	ori		$v0,$zero,1		
	0x40826000,	// 	mtc0	$v0,$status		
	0x3c032000,	// 	lui	$v1,0x2000			
	0x34630060,	// 	ori	$v1,$v1,0x60		
	0xac620000,	// 	sw	$v0,0($v1)			
	0x1000fffe,	// 	beq $zero,$zero,-2		
	0x24420001,	// 	addiu	$v0,$v0,1		
 };

void ISR(int status)
{
	MemoryWrite(PMOD_TRIS, 0x00);
	MemoryWrite(PMOD_OUT, 0xFA);
	MemoryWrite(IRQ_STATUS, status);
}

unsigned char rxBuf[4];
int offset;


void UartBootLoad()
{
	int checksum = 0;
	int len = 0;
	int val = 0;
	int i = 0;
	// Set baud rate based on switches
	//MemoryWrite(UART_BAUD_DIV, MemoryRead(SWITCHES));
	// Set baud to 460800
	MemoryWrite(UART_BAUD_DIV, 1);
	MemoryWrite(LEDS_OUT, 0xAA);
	

	// Read 32-bit length
	i = readChar();
	printChar(i);
	len = (len << 8) + i;
	i = readChar();
	printChar(i);
	len = (len << 8) + i;
	i = readChar();
	printChar(i);
	len = (len << 8) + i;
	i = readChar();
	printChar(i);
	len = (len << 8) + i;
	MemoryWrite(LEDS_OUT, len);
	// Read 32-bit boot offset
	i = readChar();
	offset = (offset << 8) + i;
	printChar(i);
	i = readChar();
	offset = (offset << 8) + i;
	printChar(i);
	i = readChar();
	offset = (offset << 8) + i;
	printChar(i);
	i = readChar();
	offset = (offset << 8) + i;
	printChar(i);
	MemoryWrite(LEDS_OUT, offset);

	// Read 'len' bytes, writing out to BOOT_OFFSET
	for(i = 0; i < len; i++)
	{
		val = (val << 8) + readChar();
		printChar(val);
		MemoryWrite(LEDS_OUT, i);
		MemoryWrite(offset+i, val);
		//if((i & 0x3) == 0x3)
		//{
		//	MemoryWrite(offset+i, val);
		//	checksum += val;
		//}
	}
	MemoryWrite(LEDS_OUT, 0xFF);
	readChar();
	//write((char *)&checksum, 4);
	//MemoryWrite(UART_CONTROL, 0x3);
	//while((MemoryRead(UART_STATUS) & 0x10) == 0x10);
}

int main (void)
{

	// If BTNR down, go into UartBootLoad routine.
	if((MemoryRead(BUTTONS) & BUTTON_RIGHT_MASK) > 0)
		UartBootLoad();

	// Load program from ROM


	// Jump to BOOT_OFFSET
	MemoryWrite(LEDS_OUT, 0x55);

	((void (*)(void))offset)();

	MemoryWrite(LEDS_OUT, 0xFF);
	return 0;
}
