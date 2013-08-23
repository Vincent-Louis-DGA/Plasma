#include <plasma_string.h>

// Compares two strings. Zero result is equal.
int strncmp_p( const char * s1, const char * s2, int maxLen)
{
	int i;
    for(i = 0; i < maxLen; i++)
	{
        if(s1[i] != s2[i] || s1[i] == 0 || s2[i] == 0)
            break;
	}
	if(i == maxLen) return 0;
	return (unsigned char)s1[i] - (unsigned char)s2[i];
}

// Copies a null-terminated string into a buffer.  Returns length of source
int append(char * buf, char * source)
{
	int ret = 0;
	while(source[ret] != 0)
	{
		buf[ret] = source[ret];
		ret++;
	}
	buf[ret] = 0;
	return ret;
}

// Convert hex string to int. Assume 0x has already been stripped.
int xtoi(char * string, int strlen)
{
	int r = 0;
	int i;
	//print("xtoi");
	//write(string,strlen);
	//printLine("");
	for(i = 0; i < strlen; i++)
	{
		if(string[i] <= '9')
			r = (r << 4) + (string[i] - '0');
		else
			r = (r << 4) + (string[i] - 'A' + 10);
	}
	return r;
}

// Convert binary string to int. Assume 0b has already been stripped.
int btoi(char * string, int strlen)
{
	int r = 0;
	int i;
	for(i = 0; i < strlen; i++)
	{
		r = (r << 1) + (string[i] - '0');

	}
	return r;
}

// Convert decimal string to int.
int dtoi(char * string, int strlen)
{
	int r = 0;
	int i;
	for(i = 0; i < strlen; i++)
	{
			r = (r * 10) + (string[i] - '0');
	}
	return r;
}

// Convert string to integer
int atoi_p(char * string, int * endOffset)
{
	int len = 0;
	char id = 'd';
	*endOffset = 0;
	// Skip non-numerical characters.
	while((*string) != 0)
	{
		if(*string >= '0' && *string <= '9')
			break;
		(*endOffset)++;
		string++;
	}
	if(*string == 0)
	{
		*endOffset = 0;
		return 0;
	}
	// Find length and number type
	while(string[len] != 0)
	{
		len++;
		if(len == 1 && string[len] == 'x')
			id = 'x';
		else if(len == 1 && string[len] == 'b')
			id = 'b';
		else if(string[len] < '0' || (string[len] > '9' && string[len] < 'A') || string[len] > 'F')
			break;
	}
	(*endOffset)+= len;
	if(id == 'x')
		return xtoi(string+2, len-2);
	if(id == 'b')
		return btoi(string+2, len-2);
	return dtoi(string, len);
}



int itoa_p(int value, char* result, int base) {

	char* ptr1 = result;
	char* ptr = result;
	char tmp_char;
	int tmp_value;
	int ret = 0;

	// check that the base if valid
	if (base < 2 || base > 36) { *result = '\0'; return ret; }

	do {
		tmp_value = value;
		value /= base;
		*ptr++ = "ZYXWVUTSRQPONMLKJIHGFEDCBA9876543210123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" [35 + (tmp_value - value * base)];
		ret++;
	} while ( value );

	// Apply negative sign
	if (tmp_value < 0) { *ptr++ = '-'; ret++;}
	*ptr-- = '\0';
	// Reverse
	while(ptr1 < ptr) {
		tmp_char = *ptr;
		*ptr--= *ptr1;
		*ptr1++ = tmp_char;
	}
	return ret;
}


// Convert integer to hex string
int itox(unsigned int value, char* result)
{
	int m;
	unsigned char v;
	int ret = 0;
	result[ret++] = '0';
	result[ret++] = 'x';
	for(m = 28; m >= 0; m-=4)
	{
		v = ((value & (0xF << m)) >> m);
		result[ret++] = "0123456789ABCDEF"[(unsigned int)v];
	}
	result[ret] = 0;
	return ret;
}

