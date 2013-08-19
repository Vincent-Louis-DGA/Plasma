

#ifndef __PLASMA_H__
#define __PLASMA_H__

/*
	Users of plasma.h should implement this function for interrupts.
	At the very least do nothing, or else code won't compile.
*/
int OS_AsmInterruptEnable(int enable);




/*********** Hardware addresses ***********/
#define RAM_INTERNAL_BASE	0x00000000
#define RAM_INTERNAL_SIZE	0x00008000 // 32 kB
#define RAM_EXTERNAL_BASE	0x40000000
#define RAM_EXTERNAL_SIZE	0x00008000 // 32 kB
#define RAM_SDRAM_SIZE		0x08000000 // 128 MB

#define PERIPH_BASE		0x20000000

#define UART_OFFSET		(PERIPH_BASE+	0x00)

#define IRQ_STATUS		(PERIPH_BASE+	0x40)
#define IRQ_STATUS_CLR	(PERIPH_BASE+	0x44)
#define IRQ_VECTOR		(PERIPH_BASE+	0x4C)
#define IRQ_MASK		(PERIPH_BASE+	0x50)
#define IRQ_MASK_SET	(PERIPH_BASE+	0x54)
#define IRQ_MASK_CLR	(PERIPH_BASE+	0x58)

#define LEDS_OFFSET		(PERIPH_BASE+	0x60)
#define PMOD_OFFSET		(PERIPH_BASE+	0x80)

#define SWITCHES		(PERIPH_BASE+	0x70)
// FYI: BUTTONS(4 downto 0) = BTNC & BTNR & BTND & BTNL & BTNU
#define BUTTONS			(PERIPH_BASE+	0x74)
#define BUTTON_UP_MASK		0x01
#define BUTTON_LEFT_MASK	0x02
#define BUTTON_DOWN_MASK	0x04
#define BUTTON_RIGHT_MASK	0x08
#define BUTTON_CENTRE_MASK	0x10

#define RAND_GEN		(PERIPH_BASE+	0x78)

#define LEDS_OUT		(LEDS_OFFSET+0x0)
#define LEDS_SET		(LEDS_OFFSET+0x4)
#define LEDS_CLR		(LEDS_OFFSET+0x8)
#define LEDS_TGL		(LEDS_OFFSET+0xC)

#define PMOD_OUT		(PMOD_OFFSET+0x0)
#define PMOD_SET		(PMOD_OFFSET+0x4)
#define PMOD_CLR		(PMOD_OFFSET+0x8)
#define PMOD_TGL		(PMOD_OFFSET+0xC)
#define PMOD_IN			(PMOD_OFFSET+0x10)
#define PMOD_TRIS		(PMOD_OFFSET+0x14)

#define UART_TX			(UART_OFFSET+0x0)
#define UART_RX			(UART_OFFSET+0x4)
#define UART_STATUS		(UART_OFFSET+0x8)
#define UART_CONTROL	(UART_OFFSET+0xC)
#define UART_BAUD_DIV	(UART_OFFSET+0x10)

#define UART_TX_RDY	((MemoryRead(UART_STATUS)&0x01) == 0)

#define	COUNTER1		(PERIPH_BASE+	0xA0)
#define	COUNTER1_PS		(PERIPH_BASE+	0xA4)
#define	COUNTER1_TS		(PERIPH_BASE+	0xA8)

#define	CACHE_HITCOUNT		(PERIPH_BASE+	0xB0)
#define	CACHE_READCOUNT		(PERIPH_BASE+	0xB4)

#define FLASH_CON			(PERIPH_BASE+	0xC0)
#define FLASH_DATA			(PERIPH_BASE+	0xC4)
#define FLASH_TRIS			(PERIPH_BASE+	0xC8)

#define FIFO_DIN		(PERIPH_BASE+	0xD0)
#define FIFO_DOUT		(PERIPH_BASE+	0xD4)
#define	FIFO_CON		(PERIPH_BASE+	0xD8)
#define FIFO_DOUT_RDY		((MemoryRead(FIFO_CON) & 0x02) == 0x02)

#define LOGIC_AN_CON	0x21000000
#define	LOGIC_AN_BASE	0x22000000
#define LOGIC_AN_LEN	0x2000


#ifdef WIN32
	#include "plasma_W32.c"
	#define MemoryRead(A) (PeriphRead(A-PERIPH_BASE))
	#define MemoryWrite(A,V) (PeriphWrite(A-PERIPH_BASE,V))
#else
	#define PeriphRead(A) (*(volatile unsigned int*)(A+PERIPH_BASE))
	#define PeriphWrite(A,V) *(volatile unsigned int*)(A+PERIPH_BASE)=(V)
	#define MemoryRead(A) (*(volatile unsigned int*)(A))
	#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)
#endif

#endif //__PLASMA_H__

