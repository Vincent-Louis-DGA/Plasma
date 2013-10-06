/*
	A sort of 'brute force' SPI implementation specific to the Numonyx Flash RAM present on the Digilent
	ATLYS board.
	Ideally, this stuff would be built in to the FPGA firmware but this route is simpler for testing.
*/

#include <plasma.h>
#include <plasma_stdio.h>
//#include <plasma_string.h>

#define RDID_LEN 20
#define FLASH_INSTR_RDVECR 0x65

// lineCode 0 = 1 line, lineCode 1 = 2 lines, lineCode 3 = 4 lines.
int FLASH_LINES [] = {0, 0, 1, 0, 2};
char FLASH_CODE_LINES [] = {1,2,4};
char FLASH_CODE_TRIS [] = {0x0E,0x0C,0x00};
char FLASH_CODE_CNT [] = {0x07, 0x03, 0x01};
char FLASH_CODE_RSHIFT [] = {7, 6, 4};
char FLASH_CODE_STEPS [] = {8, 4, 2};

typedef struct {
	char VolatileEnhancedConfigurationRegister;
	char VolatileConfigurationRegister;
	char NumLines;
} t_FlashStatus;

t_FlashStatus FlashStatus = {0xFF,0xFF,1};

void FlashSpiStart(char lines)
{
	int i;
	MemoryWrite(FLASH_CON, 0x02);	// Set CLK low, CS High.
	for(i=0; i < 2; i++);
	MemoryWrite(FLASH_CON, 0x00);	// Set CS low
}


void FlashSpiWriteBuffer(char * writeBuffer, int writeLen, int lineCode)
{
	int i,k;
	int ri = 0;
	char c = 0;
	MemoryWrite(FLASH_TRIS, FLASH_CODE_TRIS[lineCode]);
	for(i = 0; i < (writeLen*8) >> lineCode; i++)
	{
		if((i & FLASH_CODE_CNT[lineCode]) == 0x00)
		{
			c = writeBuffer[ri];
			ri++;
		}
		MemoryWrite(FLASH_DATA, c >> FLASH_CODE_RSHIFT[lineCode]);
		MemoryWrite(FLASH_CON, 0x01);
		c = c << FLASH_CODE_LINES[lineCode];
		for(k = 0; k < 2; k++);
		MemoryWrite(FLASH_CON, 0x00);
	}
}

void FlashSpiCommand(char instr, int lineCode)
{
	char wb [1];
	wb[0] = instr;
	FlashSpiWriteBuffer(wb, 1, lineCode);
}

void FlashSpiAddress(int address, int lineCode)
{
	char wb [3];
	wb[0] = address >> 16;
	wb[1] = address >> 8;
	wb[2] = address;
	FlashSpiWriteBuffer(wb, 3, lineCode);
}


void FlashSpiReadBuffer(char * readBuffer, int readLen, char lines)
{
	int i,k;
	char temp, c = 0;
	for(i = 0; i < readLen*8; i++)
	{
		MemoryWrite(FLASH_TRIS, 0x0F);
		MemoryWrite(FLASH_CON, 0x01);
		for(k = 0; k < 2; k++);
		temp = MemoryRead(FLASH_DATA);
		temp = (temp >> 1) & 0x01;
		MemoryWrite(FLASH_CON, 0x00);
		c = (c << 1) + temp;
		if((i & 0x07) == 0x07)
		{
			readBuffer[i>>3] = c;
			c = 0;
		}
	}
}

void FlashSpiEnd()
{
	MemoryWrite(FLASH_CON, 0x02);	// Set CLK low, CS High.
}

/*
	A single Extended SPI/DIO/QIO protocol transaction.
	instr = instruction command, eg, 0x03 for READ
	address = address if applicable
	addressLen = number of bytes for address. Set to 0 if address N/A
	writeBuffer = buffer holding write data
	writeLen = number of bytes for write buffer. Set to 0 if write N/A
	readBuffer = buffer holding read data
	readLen = number of bytes for read buffer. Set to 0 if read N/A
	lines = 2 for DIO, 4 for QIO, all other values use single.
*/
void FlashSpiTransaction(char instr, int address, int addressLen, char * writeBuffer, int writeLen, char * readBuffer, int readLen, int lineCode)
{
	FlashSpiStart(lineCode);
	FlashSpiCommand(instr,lineCode);
	if(addressLen > 0)
		FlashSpiAddress(address, lineCode);
	if(writeLen > 0)
		FlashSpiWriteBuffer(writeBuffer,writeLen,lineCode);
	if(readLen > 0)
		FlashSpiReadBuffer(readBuffer, readLen, lineCode);
	FlashSpiEnd();
	

}
void FlashSpiRead(char instr, int address, int addressLen, char * readBuffer, int readLen)
{
	FlashSpiTransaction(instr, address, addressLen, (char*)0,0,readBuffer,readLen,0);
}

void FlashSpiWrite(char instr, int address, int addressLen, char * writeBuffer, int writeLen)
{
	FlashSpiTransaction(instr, address, addressLen,writeBuffer,writeLen,(char*)0,0,0);
}

void FlashReadMemory(int address, char * readBuffer, int readLen)
{
	FlashSpiRead(0x03, address, 3, readBuffer, readLen);
}

/*
	Enables Flash Write, INST 0x06.
*/
void WriteEnable()
{
	FlashSpiWrite(0x06, 0, 0, (char*)0, 0);
}

/*
	Disables Flash Write, INSTR 0x04
*/
void WriteDisable()
{
	FlashSpiWrite(0x04, 0,0,(char*)0, 0);
}


int ReadVolatileConfigurationRegister()
{
	char readBuffer [4];
	FlashSpiRead(0x85, 0,0, readBuffer, 2);
	FlashSpiRead(0x65, 0,0, readBuffer+2, 2);
	return (readBuffer[0] << 24) +(readBuffer[1] << 16) +(readBuffer[2] << 8) + readBuffer[3];
}

int ReadNonVolatileConfigurationRegister()
{
	char readBuffer [2];
	FlashSpiRead(0xB5, 0,0,readBuffer, 2);
	return (readBuffer[0] << 8) + readBuffer[1];
}
/*
void PrintReadBuffer(int address, char * r, int readLen)
{
	int i = 0;
	char TxBuffer[64];
	int len = 0;
	print("Read ");
	itoa_p(address, TxBuffer, 16);
	print(TxBuffer);
	print(" : ");
	for(i = 0; i < readLen; i++)
	{
		len = itoa_p(r[i], TxBuffer,16);
		if(len < 2)
			print("0");
		print(TxBuffer);

		if((i & 0x1) == 1)
			print(" ");
	}
	printLine("");
}

void ReadAndPrintFlash(int address)
{
	char r [20];
	int i;
	for(i = 0 ; i < 20; i++) r[i] = 0;
	FlashSpiRead(0x03, address, 3, r, 20);
	PrintReadBuffer(address, r, 20);
}
*/


char ReadSpiVecr()
{
	char rb [1];
	FlashSpiStart(FLASH_LINES[1]);
	FlashSpiCommand(FLASH_INSTR_RDVECR, FLASH_LINES[1]);
	FlashSpiReadBuffer(rb, 1, FLASH_LINES[1]);
	FlashSpiEnd();
	return rb[0];
}

char ReadDioVecr()
{
	char rb [1];
	FlashSpiStart(FLASH_LINES[2]);
	FlashSpiCommand(FLASH_INSTR_RDVECR, FLASH_LINES[2]);
	FlashSpiReadBuffer(rb, 1, FLASH_LINES[2]);
	FlashSpiEnd();
	return rb[0];
}
char ReadQioVecr()
{
	char rb [1];
	FlashSpiStart(FLASH_LINES[4]);
	FlashSpiCommand(FLASH_INSTR_RDVECR, FLASH_LINES[4]);
	FlashSpiReadBuffer(rb, 1, FLASH_LINES[4]);
	FlashSpiEnd();
	return rb[0];
}

char ReadVecr()
{
	char vecr = ReadSpiVecr();
	if((vecr & 0xC0) == 0xC0)
		return vecr;
	vecr = ReadDioVecr();
	if((vecr & 0xC0) == 0x80)
		return vecr;
	return ReadSpiVecr();
}

/*
	Configures Flash for Extended SPI mode.
	VECR = 0xFF for Extended SPI
	VECR = 0x7F for QIO-SPI
	VECR = 0xBF for DIO-SPI
*/
void FlashInit()
{
	char wb [1];
	char r = ReadVecr();
	FlashStatus.VolatileEnhancedConfigurationRegister = r;
	if((r & 0xE0) == 0x40 || (r & 0xE0) == 0x00)
		FlashStatus.NumLines = 4;
	else if((r & 0xE0) == 0x80)
		FlashStatus.NumLines = 2;
	else
		FlashStatus.NumLines = 1;
	wb[0] = 0xFF;
	FlashSpiTransaction(0x06, 0, 0, (char*)0, 0,(char*)0, 0,FLASH_LINES[(int)FlashStatus.NumLines]);  //enable writing
	FlashSpiTransaction(0x61, 0,0, wb,1,(char*)0, 0,FLASH_LINES[(int)FlashStatus.NumLines]);  //write to VECR
	r = ReadVecr();
	FlashStatus.VolatileEnhancedConfigurationRegister = r;
	if((r & 0xE0) == 0x40 || (r & 0xE0) == 0x00)
		FlashStatus.NumLines = 4;
	else if((r & 0xE0) == 0x80)
		FlashStatus.NumLines = 2;
	else
		FlashStatus.NumLines = 1;
}
/*
void ReadAndPrintRegisters()
{
	int r;
	char TxBuffer[64];
	r = ReadSpiVecr();
	print("1VECR  : ");
	itox(r, TxBuffer);
	printLine(TxBuffer);
	r = ReadDioVecr();
	print("2VECR  : ");
	itox(r, TxBuffer);
	printLine(TxBuffer);
	r = ReadQioVecr();
	print("4VECR  : ");
	itox(r, TxBuffer);
	printLine(TxBuffer);
	r = ReadVolatileConfigurationRegister();
	print("VCR  : ");
	itox(r, TxBuffer);
	printLine(TxBuffer);
	r = ReadNonVolatileConfigurationRegister();
	print("NVCR : ");
	itox(r, TxBuffer);
	printLine(TxBuffer);
}

char ReadAndPrintFlashId()
{
	int i = 0;
	int len = 0;
	char r [RDID_LEN];
	char TxBuffer[64];
	print("Lines : ");
	len = itoa_p(FlashStatus.NumLines, TxBuffer, 10);
	printLine(TxBuffer);
	FlashSpiRead(0x9F, 0, 0, r, RDID_LEN);
	PrintReadBuffer(0x1D000000, r, RDID_LEN);
	return 1;
}

void TestFlashRam()
{
	FlashInit();
	
	ReadAndPrintFlashId();
	ReadAndPrintRegisters();
	ReadAndPrintFlash(0x180000);
	ReadAndPrintFlash(0x180010);
	ReadAndPrintFlash(0x180100);
	ReadAndPrintFlash(0x200000);
}
*/