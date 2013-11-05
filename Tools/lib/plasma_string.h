#ifndef __MIPS_STRING_H
#define __MIPS_STRING_H
// Calculates length of null-terminated string.
//int strlen(char * string);
/* Copies a null-terminated string into a buffer.  Returns length of source,
	ie, lengths that buf has been extended by. */
int append(char * buf, char * source);
// Compares two strings. Zero result is equal.
int strncmp_p( const char * str1, const char * str2, int maxLen);


/* Convert string to integer
	Correctly interprets string starting with 0x as hex, and 0b as bits. 
	endOffset reference parameter returns the offset of end of number string.*/
int atoi_p(char * string, int * endOffset);	
// Convert integer to string of given base. Returns number of bytes, not including NULL.
int itoa_p(int value, char * result, int base);	
/* Convert integer to hex string. Returns number of bytes, not including NULL.
	Expect it to be faster than itoa, since it uses bit masks and shifts instead of division */
int itox(unsigned int value, char * result);	
int btox(char value, char* result);
void byteToHex(char value, char * result);

#include <plasma_string.c>

#endif
