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

#define ETHER_TX_BUSY	(MemoryRead(ETHER_TX_CONTROL) & 0x4)


#define MacHigh	0x020A
#define MacMid	0x3544
#define MacLow	0x5441

#define IP_HEADER_LEN		20
#define UDP_HEADER_LEN		8
#define IP_PROTOCOL_ICMP	1
#define IP_PROTOCOL_UDP		17
#define IP_PROTOCOL_TCP		6

// Function signature for processing IP packets in Interrupt Handler
// void RxProcess(char * rxBuffer)
//void (*RxProcess)(char*) = DefaultProcessIpPacket;

typedef struct
{
	unsigned int sourceAddr;
	unsigned int destAddr;
	char protocol;
} IpFilter_t;

typedef struct
{
	unsigned short sourcePort;
	unsigned short destPort;
	unsigned short length;
} UdpFilter_t;


IpFilter_t ipFilter = {1,1,1};
int ipLease = 0;
int transactionId;
unsigned int ownIpAddress = 0;	// 192.168.104.104?

void CreateIpFilter(char * buffer, IpFilter_t* filterOut)
{
	filterOut->destAddr = *(unsigned int*)(buffer+16);
	filterOut->sourceAddr = *(unsigned int*)(buffer+12);
	filterOut->protocol = *(buffer+9);
}

int PassesIpFilter(IpFilter_t* packet, IpFilter_t* filter)
{
	if(filter->sourceAddr != 0)
	{
		if(filter->sourceAddr != packet->sourceAddr)
			return 0;
	}
	if(filter->destAddr != 0)
	{
		if(filter->destAddr != packet->destAddr)
			return 0;
	}
	if(filter->protocol != 0)
	{
		if(filter->protocol != packet->protocol)
			return 0;
	}
	return 1;
}

void ProcessDhcpPacket(char * buffer)
{
	unsigned int u;
	u = *(unsigned int*)(buffer+IP_HEADER_LEN);
	write("DHCPo\n",6);
	write((char*)&u, 4);
	if(((u & 0xFFFF) != 67) || ((u & 0xFFFF0000) != (68 << 16)))
		return;

	write("DHCPp\n",6);

	u = *(unsigned int*)(buffer+IP_HEADER_LEN+UDP_HEADER_LEN+4);
	if(u != transactionId)
		return;
	ownIpAddress = *(unsigned int*)(buffer+IP_HEADER_LEN+UDP_HEADER_LEN+16);
	
	write((char*)&ownIpAddress, 4);
}


void ProcessIcmpPacket(char * buffer)
{
	writeChar('C');
}

void ProcessTcpPacket(char * buffer)
{
	writeChar('T');
}

void ProcessUdpPacket(char * buffer)
{
	unsigned short sourcePort = *(unsigned short*)(buffer + IP_HEADER_LEN);
	unsigned short destPort = *(unsigned short*)(buffer + IP_HEADER_LEN+2);
	//if(destPort == 68)
	//	ProcessDhcpPacket(buffer);
	//else
		writeChar('U');
}

void DefaultProcessIpPacket(char * buffer)
{
	writeChar('I');
}

void ProcessArpPacket(char * buffer, unsigned int bufferSelect)
{
	writeChar('A');
}

inline void ProcessIpPacket(char * buffer)
{
	IpFilter_t* pFilter;

	CreateIpFilter(buffer, pFilter);
	if(PassesIpFilter(pFilter, &ipFilter) == 0)
		return;
	if(pFilter->protocol == IP_PROTOCOL_UDP)
		ProcessUdpPacket(buffer);
	else if(pFilter->protocol == IP_PROTOCOL_ICMP)
		ProcessIcmpPacket(buffer);
	else if(pFilter->protocol == IP_PROTOCOL_TCP)
		ProcessTcpPacket(buffer);
	else
		DefaultProcessIpPacket(buffer);
}


inline void ProcessEthernetPacket(char * buffer, unsigned int bufferSelect, unsigned short packetLen)
{
	unsigned short etherType = MemoryRead(ETHER_RX_TYPE^bufferSelect);
	unsigned int firstWord;
	if(etherType == 0x0800)
		ProcessIpPacket(buffer);
	else if(etherType == 0x0806)
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

unsigned int CharToIp(char * buf)
{
	int i;
	unsigned int ip = 0;
	int start = 0;
	int end;
	i = atoi_p(buf+start, &end);
	start += end;
	ip = (ip<<8) + i;
	i = atoi_p(buf+start, &end);
	start += end;
	ip = (ip<<8) + i;
	i = atoi_p(buf+start, &end);
	start += end;
	ip = (ip<<8) + i;
	i = atoi_p(buf+start, &end);
	start += end;
	ip = (ip<<8) + i;
	return ip;
}

void IpToHex(unsigned int ip, char * buf)
{
	byteToHex((ip>>24)&0xFF, buf);
	buf[2] = '.';
	byteToHex((ip>>16)&0xFF, buf+3);
	buf[5] = '.';
	byteToHex((ip>>8)&0xFF, buf+6);
	buf[8] = '.';
	byteToHex((ip>>0)&0xFF, buf+9);
}


void EthernetInit(unsigned short macHigh, unsigned short macMid, unsigned short macLow)
{
	*(unsigned short*)(ETHER_OWN_MAC_HIGH) = macHigh;
	*(unsigned short*)(ETHER_OWN_MAC_MID) = macMid;
	*(unsigned short*)(ETHER_OWN_MAC_LOW) = macLow;
	//MemoryWrite(ETHER_RX_CONTROL, 1);	// Filter by Dest MAC
	MemoryWrite(ETHER_RX_PACKET_LENGTH, 0);
	MemoryWrite(ETHER_RX_PACKET_LENGTH^ETHER_SELECT_MASK, 0);
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
	*(unsigned short*)(ETHER_TX_DEST_MAC_HIGH) = macHigh;
	*(unsigned short*)(ETHER_TX_DEST_MAC_MID) = macMid;
	*(unsigned short*)(ETHER_TX_DEST_MAC_LOW) = macLow;
}

void FillIpHeader(unsigned short totalLength, char protocol, unsigned int srcAddress, unsigned int destAddress)
{
	unsigned short checksum = 0x0000;

	*(unsigned short*)(ETHER_TXBUF) = 0x4500;			// IPv4, 5 word header, DSCP/ECN
	*(unsigned short*)(ETHER_TXBUF+2) = totalLength;	// Total Length
	*(unsigned int*)(ETHER_TXBUF+4) = 0x6DF30000;		// ID, Flags, Fragment
	*(unsigned short*)(ETHER_TXBUF+8) = (0x8000 + protocol);	// TTL=128, Protocol
	*(unsigned short*)(ETHER_TXBUF+10) = checksum;		// Checksum
	*(unsigned int*)(ETHER_TXBUF+12) = srcAddress;
	*(unsigned int*)(ETHER_TXBUF+16) = destAddress;

	checksum = Checksum16((unsigned short*)ETHER_TXBUF, IP_HEADER_LEN);
	*(unsigned short*)(ETHER_TXBUF+10) = checksum;		// Checksum

}

void CreatePingRequest(unsigned int sourceIp, unsigned int destIp, int txLen, unsigned short seq)
{
	int i;
	char * charP;
	FillIpHeader(txLen, IP_PROTOCOL_ICMP, sourceIp, destIp);

	*(unsigned short*)(ETHER_TXBUF+0x14) = 0x0800;	// Ping Request
	*(unsigned short*)(ETHER_TXBUF+0x16) = 0x0000;	// ICMP Checksum 0
	*(unsigned short*)(ETHER_TXBUF+0x18) = 0x0001;	// Ident
	*(unsigned short*)(ETHER_TXBUF+0x1A) = seq;	// Sequence
	
	
	charP = (char*)(ETHER_TXBUF+0x1C);
	for(i = 0; i < txLen-0x1C; i++)
	{
		*charP = (i&0x0F) + 'a';
		charP++;
	}
	
	*(unsigned short*)(ETHER_TXBUF+IP_HEADER_LEN+2) = Checksum16((unsigned short*)(ETHER_TXBUF+IP_HEADER_LEN), txLen-IP_HEADER_LEN);
}

/*
	Fills the Ethernet TX Buffer with the header for a UDP packet.
	Returns the total length of the IP packet
*/
int CreateUdpPacket(unsigned int sourceIp, unsigned int destIp, unsigned short sourcePort, unsigned short destPort, int payloadLen)
{
	unsigned short* shortP = (unsigned short*)(ETHER_TXBUF+IP_HEADER_LEN);
	FillIpHeader(payloadLen+IP_HEADER_LEN+UDP_HEADER_LEN, IP_PROTOCOL_UDP, sourceIp, destIp);
	*shortP = sourcePort;
	*(shortP+1) = destPort;
	*(shortP+2) = payloadLen+UDP_HEADER_LEN;
	*(shortP+3) = 0;
	return IP_HEADER_LEN + UDP_HEADER_LEN + payloadLen;
}

int CreateDhcpDiscover(unsigned int id)
{
	char* uBuffer;
	int o = 0;
	int i;
	EthernetSetTxMacDest(0xFFFF,0xFFFF,0xFFFF);
	uBuffer = (char*)(ETHER_TXBUF+IP_HEADER_LEN+UDP_HEADER_LEN);
	*(unsigned int*)(uBuffer+o) = 0x01010600; o += 4; 
	*(unsigned int*)(uBuffer+o) = id; o += 4;
	*(unsigned int*)(uBuffer+o) = 0; o += 4;	// secs/flags.
	*(unsigned int*)(uBuffer+o) = 0; o += 4;	// client ip
	*(unsigned int*)(uBuffer+o) = 0; o += 4;	// your ip
	*(unsigned int*)(uBuffer+o) = 0; o += 4;	// server ip
	*(unsigned int*)(uBuffer+o) = 0; o += 4;	// gateway ip
	*(unsigned short*)(uBuffer+o) = MacHigh; o += 2;
	*(unsigned short*)(uBuffer+o) = MacMid; o += 2;
	*(unsigned short*)(uBuffer+o) = MacLow; o += 2;
	
	for(i = 0; i < 202; i++)
	{
		*(uBuffer+o) = 0;
		o++;
	}
	*(unsigned int*)(uBuffer+o) = 0x63825363; o += 4;	// "DHCP"
	*(unsigned short*)(uBuffer+o) = 0x3501; o += 2;		// Option 53
	*(uBuffer+o) = 0x01; o+=1;	// DHCP Discover

	*(uBuffer+o) = 0xFF; o += 1;

	return CreateUdpPacket(0, 0xFFFFFFFF, 68, 67, o);
}


void DoDhcp()
{
	int i,k;
	int repeats;
	char buf [16];
	ownIpAddress = 0;
	ipFilter.destAddr = 0;
	ipFilter.sourceAddr = 0;
	ipFilter.protocol = 0;//IP_PROTOCOL_UDP;
	transactionId = (MacMid<<16) + MacLow;
	for(repeats = 0; repeats < 10 && ownIpAddress == 0; repeats++)
	{
		IpToHex(ownIpAddress, buf);
		write(buf,11); write("\n",1);
		while(ETHER_TX_BUSY != 0);
		i = CreateDhcpDiscover(transactionId++);
		MemoryWrite(ETHER_TX_PACKET_LENGTH, i);
		MemoryWrite(ETHER_TX_CONTROL, 2);
		for(k = 0; k < 100; k++)
		{
			for(i = 0; i < 100000; i++);
			if(ownIpAddress != 0)
				break;
		}
	}
	
		IpToHex(ownIpAddress, buf);
		write(buf,11); write("\n",1);
}


void EthernetExercise(char * buffer)
{
	int i;
	unsigned int s,u;
	char * txP;
	unsigned int destIp;
	int txLen = 42;
	
	EthernetInit(MacHigh, MacMid, MacLow);

	

	DoDhcp();
	
	EthernetSetTxMacDest(0x70f3,0x9500,0x721f);
	destIp = CharToIp("192.168.104.64");
	ipFilter.destAddr = ownIpAddress;
	ipFilter.protocol = 0;
	ipFilter.sourceAddr = 0;

	for(s = 0; s < 32; s++)
	{
		while(ETHER_TX_BUSY != 0);
			
		
		txLen = 16;
		txP = (char*)(ETHER_TXBUF + IP_HEADER_LEN + UDP_HEADER_LEN);
		for(i = 0; i < txLen; i++)
		{
			*txP = i;
			txP++;
		}

		txLen = CreateUdpPacket(ownIpAddress,destIp,0,60000 + s, txLen);

		MemoryWrite(ETHER_TX_PACKET_LENGTH, txLen);
		MemoryWrite(ETHER_TX_CONTROL, 2);
	}

	while(1);
}



#endif
