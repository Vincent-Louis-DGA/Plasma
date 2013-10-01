#define ELF32_FHDR_LEN 52	// length in bytes of 32-bit ELF file header.
#define ELF32_PHDR_LEN 32	// Length in bytes of 32-bit ELF program header.
#define ELF32_SHDR_LEN 40	// Length in bytes of 32-bit ELF section header.
#define ELF32_MAX_SEGMENTS 32	// Max number of program segments

// Need this much space on the heap
#define ELF32_BUFFER_SIZE (ELF32_MAX_SEGMENTS*ELF32_PHDR_LEN)

#pragma region typedefs

typedef struct  {
	unsigned int magicNumber;
	unsigned char bitFormat;
	unsigned char endianness;
	unsigned short architecture;
} Elf_HeaderId;


typedef struct  {
	unsigned int entryPoint;
	unsigned int programHeaderOffset;
	unsigned int sectionHeaderOffset;
	unsigned short programHeaderSize;
	unsigned short programHeaderNum;
	unsigned short sectionHeaderSize;
	unsigned short sectionHeaderNum;
} Elf32_Fhdr;

typedef struct {
	unsigned int	p_type;
	unsigned int	p_offset;
	unsigned int	p_vaddr;
	unsigned int	p_filesz;
} Elf32_Phdr;

typedef struct {
	unsigned int	sh_offset;
	unsigned int	sh_size;
} Elf32_Shdr;

typedef void (*StreamReadPtr)(char *,int);

#pragma endregion

#pragma region local variables

StreamReadPtr ReadFunctionPtr = 0;
// {0x7f'E''L''F', 32-bit, big endian, MIPS I }
Elf_HeaderId ExpectedMipsHeader = { 0x7F454C46, 1, 2, 8 };
unsigned int ElfProgramOffset = 0;
char buffer [ELF32_BUFFER_SIZE];
Elf32_Phdr progHeaders [ELF32_MAX_SEGMENTS];
//Elf32_Fhdr * fhdr;

#pragma endregion

#define CHAR_TO_INT32(buffer,offset) ((buffer[offset]<<24)+(buffer[offset+1]<<16)+(buffer[offset+2]<<8)+buffer[offset+3])
#define CHAR_TO_INT16(buffer,offset) ((buffer[offset]<<8)+buffer[offset+1])

void ElfSetReadFunctionPtr(StreamReadPtr fn)
{
	ReadFunctionPtr = fn;
}

void ElfReadFileHeader(char * buffer, Elf32_Fhdr * fhdr)
{
	fhdr->entryPoint = CHAR_TO_INT32(buffer,0x18);
	fhdr->programHeaderOffset = CHAR_TO_INT32(buffer, 0x1C);
	fhdr->sectionHeaderOffset = CHAR_TO_INT32(buffer, 0x20);
	fhdr->programHeaderSize = CHAR_TO_INT16(buffer, 0x2A);
	fhdr->programHeaderNum = CHAR_TO_INT16(buffer, 0x2C);
	fhdr->sectionHeaderSize = CHAR_TO_INT16(buffer, 0x2E);
	fhdr->sectionHeaderNum = CHAR_TO_INT16(buffer,0x30);
}

int IsInvalidElfFile(char * buffer)
{
	Elf_HeaderId id;
	id.magicNumber = CHAR_TO_INT32(buffer,0);//(buffer[0]<<24)+(buffer[1]<<16)+(buffer[2]<<8)+buffer[3];
	id.bitFormat = buffer[4];
	id.endianness = buffer[5];
	id.architecture = CHAR_TO_INT16(buffer,0x12);//(buffer[0x12]<<8)+buffer[0x13];
	if(id.magicNumber != ExpectedMipsHeader.magicNumber)
		return 1;
	if(id.bitFormat != ExpectedMipsHeader.bitFormat)
		return 2;
	if(id.endianness != ExpectedMipsHeader.endianness)
		return 3;
	if(id.architecture != ExpectedMipsHeader.architecture)
		return 4;
	return 0;
}

void ReadProgramHeaders(char * buffer, int numHeaders)
{
	int i;
	for(i = 0; i < numHeaders; i++)
	{
		progHeaders[i].p_type = CHAR_TO_INT32(buffer,i*ELF32_PHDR_LEN);
		progHeaders[i].p_offset = CHAR_TO_INT32(buffer,i*ELF32_PHDR_LEN + 4);
		progHeaders[i].p_vaddr = CHAR_TO_INT32(buffer,i*ELF32_PHDR_LEN + 8);
		progHeaders[i].p_filesz = CHAR_TO_INT32(buffer,i*ELF32_PHDR_LEN + 16);
	}
}


int AdvanceToFileOffset(char * buffer, int currentOffset, int len)
{
	int a;
	while(currentOffset < len)
	{
		a = len-currentOffset;
		if(a > ELF32_BUFFER_SIZE) a = ELF32_BUFFER_SIZE;
		ReadFunctionPtr(buffer, a);
		currentOffset += a;
	}
	return currentOffset;
}

int ElfReadFile()
{
	int error = 0;
	int i;
	int r = 0;
	int a,b,c;
	Elf32_Fhdr fhdr;

	// Read ELF header.
	ReadFunctionPtr(buffer, ELF32_FHDR_LEN);
	r += ELF32_FHDR_LEN;
	error = IsInvalidElfFile(buffer);
	if(error)
		return error;
	ElfReadFileHeader(buffer, &fhdr);
	if(fhdr.programHeaderSize != ELF32_PHDR_LEN)
		return 10;
	if(fhdr.programHeaderNum > ELF32_MAX_SEGMENTS)
		return 11;
	if(fhdr.sectionHeaderSize != ELF32_SHDR_LEN)
		return 12;
	if(fhdr.entryPoint < 0x2000)
		return 13;

	// Advance (in chunks of BUFFER_SIZE) to beginning of Program Header
	r = AdvanceToFileOffset(buffer, r, fhdr.programHeaderOffset);

	// Read program header
	i = ELF32_PHDR_LEN * fhdr.programHeaderNum;
	ReadFunctionPtr(buffer, i);
	r += i;
	ReadProgramHeaders(buffer, fhdr.programHeaderNum);
	
	
	
	// Read and copy segments.
	for(i = 0; i < fhdr.programHeaderNum; i++)
	{
		// advance to start of segment, in chunks of buffer size
		r = AdvanceToFileOffset(buffer, r, progHeaders[i].p_offset);

		// read in chunks of buffer size.
		c = 0;
		while(r < progHeaders[i].p_offset + progHeaders[i].p_filesz)
		{
			a = progHeaders[i].p_offset + progHeaders[i].p_filesz - r;
			if(a > ELF32_BUFFER_SIZE) a = ELF32_BUFFER_SIZE;
			ReadFunctionPtr(buffer,a);
			r += a;
			
			// write to final location
			if(progHeaders[i].p_type == 1)
				for(b = 0; b < a; b+=4)
					MemoryWrite(c + b + progHeaders[i].p_vaddr, MemoryRead((int)buffer+b));//CHAR_TO_INT32(buffer,b));
			c += a;
		}
	}

	// Advance (in chunks of BUFFER_SIZE) to beginning of Section Header
	r = AdvanceToFileOffset(buffer, r ,fhdr.sectionHeaderOffset);

	// Read Sections (skipping over them)
	r = AdvanceToFileOffset(buffer, r, r+fhdr.sectionHeaderNum*ELF32_SHDR_LEN);


	// set entry point address.
	ElfProgramOffset = fhdr.entryPoint;

	return 0;
}

int ElfBranch()
{
	return ((int (*)(void))ElfProgramOffset)();
}
