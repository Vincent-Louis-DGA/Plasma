#ifndef __ETHERNET_C
#define __ETHERNET_C


#include <plasma.h>
#include <plasma_stdio.h>
#include <plasma_string.h>


#define ETHER_OFFSET	0x20010000
#define ETHER_IRQ_MASK	0x4

#define ETHER_OWN_MAC_HIGH	(ETHER_OFFSET+0x0024)
#define ETHER_OWN_MAC_MID	(ETHER_OFFSET+0x0028)
#define ETHER_OWN_MAC_LOW	(ETHER_OFFSET+0x002C)

#define ETHER_RXBUF			(ETHER_OFFSET+0x4000)
#define ETHER_RX_CONTROL	(ETHER_OFFSET+0x5000)
#define ETHER_RX_PACKET_LENGTH	(ETHER_OFFSET+0x5020)
#define ETHER_RX_DEST_MAC_HIGH	(ETHER_OFFSET+0x5024)
#define ETHER_RX_DEST_MAC_MID	(ETHER_OFFSET+0x5028)
#define ETHER_RX_DEST_MAC_LOW	(ETHER_OFFSET+0x502C)
#define ETHER_RX_SRC_MAC_HIGH	(ETHER_OFFSET+0x5034)
#define ETHER_RX_SRC_MAC_MID	(ETHER_OFFSET+0x5038)
#define ETHER_RX_SRC_MAC_LOW	(ETHER_OFFSET+0x503C)
#define ETHER_RX_TYPE			(ETHER_OFFSET+0x5030)
#define ETHER_RX_CRC_ACTUAL		(ETHER_OFFSET+0x5040)
#define ETHER_RX_CRC_EXPECTED	(ETHER_OFFSET+0x5044)
#define ETHER_SELECT_MASK	0x0800

#define ETHER_TXBUF				(ETHER_OFFSET+0x2000)
#define ETHER_TX_CONTROL		(ETHER_OFFSET+0x3000)
#define ETHER_TX_PACKET_LENGTH	(ETHER_OFFSET+0x3020)
#define ETHER_TX_DEST_MAC_HIGH	(ETHER_OFFSET+0x3024)
#define ETHER_TX_DEST_MAC_MID	(ETHER_OFFSET+0x3028)
#define ETHER_TX_DEST_MAC_LOW	(ETHER_OFFSET+0x302C)
#define ETHER_TX_TYPE			(ETHER_OFFSET+0x3030)

#define ETHER_TX_BUSY	(MemoryRead(ETHER_TX_CONTROL) & 0x4)

#define ETHER_TYPE_IPV4		0x0800
#define ETHER_TYPE_ARP		0x0806

#define MacHigh	0x020A
#define MacMid	0x3544
#define MacLow	0x5441





char isrBuf [64];
char mainBuf[64];





void ProcessArpPacket(char * buffer, unsigned int bufferSelect);
void ProcessIpPacket(char * buffer);

inline void ProcessEthernetPacket(char * buffer, unsigned int bufferSelect, unsigned short packetLen)
{
	unsigned short etherType = MemoryRead(ETHER_RX_TYPE^bufferSelect);
	unsigned int firstWord;
	if(etherType == ETHER_TYPE_IPV4)
		ProcessIpPacket(buffer);
	else if(etherType == ETHER_TYPE_ARP)
		ProcessArpPacket(buffer, bufferSelect);
	else if(etherType < 0x0600)
	{
		firstWord = *(unsigned int*)(buffer);
		if((firstWord & 0xF0000000) == 0x40000000)
			ProcessIpPacket(buffer);
		else if(firstWord == 0x00010800)
			ProcessArpPacket(buffer, bufferSelect);
	}
}


void EthernetInterruptHandler(int irqStatus)
{
	unsigned int bufferSelect;
	unsigned short packetLen;
	char * buffer;
	
	// Check 2 buffers
	for(bufferSelect = 0; bufferSelect <= ETHER_SELECT_MASK; bufferSelect+=ETHER_SELECT_MASK)
	{
		packetLen = MemoryRead(ETHER_RX_PACKET_LENGTH ^ bufferSelect);
		if(packetLen != 0)
		{
			buffer = (char*)(ETHER_RXBUF^bufferSelect);
			ProcessEthernetPacket(buffer, bufferSelect, packetLen);
		}
		MemoryWrite(ETHER_RX_PACKET_LENGTH^bufferSelect, 0);
	}
	*IrqStatusClrReg = irqStatus;	// Not actually necessary for Ethernet IRQ, but still good practice.
}



void EthernetInit(unsigned short macHigh, unsigned short macMid, unsigned short macLow)
{
	MemoryWrite(ETHER_OWN_MAC_HIGH, macHigh);
	MemoryWrite(ETHER_OWN_MAC_MID, macMid);
	MemoryWrite(ETHER_OWN_MAC_LOW, macLow);
	MemoryWrite(ETHER_RX_PACKET_LENGTH, 0);
	MemoryWrite(ETHER_RX_PACKET_LENGTH^ETHER_SELECT_MASK, 0);
}

void EthernetInitIrq()
{
	*IrqVectorReg = (unsigned int)EthernetInterruptHandler;
	*IrqMaskReg = ETHER_IRQ_MASK;
	*IrqStatusReg = 0;
	OS_AsmInterruptEnable(1);
}

unsigned short Checksum16(unsigned short * startAddress, unsigned short len)
{
	unsigned int checksum = 0;
	unsigned short i;
	for(i = 0; i < len; i+=2)
	{
		checksum += *startAddress;
		startAddress++;
	}
	checksum = (checksum & 0xffff) + (checksum >> 16);
	return (unsigned short)~checksum;	// Checksum
}

void EthernetSetTxMacDest(unsigned short macHigh, unsigned short macMid, unsigned short macLow)
{
	MemoryWrite(ETHER_TX_DEST_MAC_HIGH, macHigh);
	MemoryWrite(ETHER_TX_DEST_MAC_MID, macMid);
	MemoryWrite(ETHER_TX_DEST_MAC_LOW, macLow);
}


void WaitForTxToFinish() { while(ETHER_TX_BUSY != 0); }

/* 
	Function to send the packet currently in TX memory.
	Blocking.
*/
void SendBufferedPacket(int txLen)
{
	while(ETHER_TX_BUSY != 0);
	MemoryWrite(ETHER_TX_PACKET_LENGTH, txLen);
	MemoryWrite(ETHER_TX_CONTROL, 2);
}



#endif
