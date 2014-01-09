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


#define MacHigh	0x020A
#define MacMid	0x3544
#define MacLow	0x5441

#define ETHER_TYPE_IPV4		0x0800
#define ETHER_TYPE_ARP		0x0806
#define IP_HEADER_LEN		20
#define UDP_HEADER_LEN		8
#define DHCP_OPTIONS_OFFSET	240
#define IP_PROTOCOL_ICMP	1
#define IP_PROTOCOL_UDP		17
#define IP_PROTOCOL_TCP		6



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

enum IpQueryType { ICMP, ARP, TCP };

typedef struct
{
	IpFilter_t ipInfo;
	int queryInfo [4];
	enum IpQueryType queryType;
} IpQuery_t;

IpFilter_t ipFilter = {1,1,1};
volatile unsigned int ipLease = 0;
volatile int transactionId;
volatile unsigned int ownIpAddress = 0;	// 192.168.104.104?
volatile char DhcpState = 0;
volatile unsigned int dhcpServerIp = 0;

char isrBuf [64];
char mainBuf[64];

#define MAX_IP_QUERIES 4
volatile IpQuery_t IpQueryStack [MAX_IP_QUERIES];
volatile int IpQueryStackIndex = -1;

void CreateIpFilter(char * buffer, IpFilter_t* filterOut)
{
	filterOut->destAddr = *(unsigned int*)(buffer+16);
	filterOut->sourceAddr = *(unsigned int*)(buffer+12);
	filterOut->protocol = *(buffer+9);
}

void CopyIpFilter(IpFilter_t * src, IpFilter_t * dest)
{
	dest->destAddr = src->destAddr;
	dest->sourceAddr = src->sourceAddr;
	dest->protocol = src->protocol;
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
	char * val = (char*)&ip;
	bytesToHex(val, buf,1);
	buf[2] = '.';
	bytesToHex(val+1, buf+3,1);
	buf[5] = '.';
	bytesToHex(val+2, buf+6,1);
	buf[8] = '.';
	bytesToHex(val+3, buf+9,1);
}


void ProcessDhcpPacket(char * buffer)
{
	unsigned int u;
	int i;
	char option;
	char optionLen;

	write("D:",2);
	u = *(unsigned int*)(buffer+IP_HEADER_LEN+UDP_HEADER_LEN+4);
	
	bytesToHex((char*)&u,isrBuf,4);
	write(isrBuf,8); writeChar(';');

	if(u != transactionId)
		return;
	u = *(unsigned int*)(buffer+IP_HEADER_LEN+UDP_HEADER_LEN+16);
	IpToHex(u,isrBuf);
	write(isrBuf,11); writeChar(';');
	if(DhcpState == 0)
		ownIpAddress = u;

	u = *(unsigned int*)(buffer+IP_HEADER_LEN+UDP_HEADER_LEN+20);
	IpToHex(u,isrBuf);
	write(isrBuf,11); writeChar(';');
	if(DhcpState == 0)
		dhcpServerIp = u;

	buffer = buffer + IP_HEADER_LEN + UDP_HEADER_LEN + DHCP_OPTIONS_OFFSET;
	// Process Options
	for(i = 0; i < 10; i++)
	{
		option = buffer[0];
		if(option == 0xFF)
			break;
		optionLen = buffer[1];
		if(optionLen > 31) break;

		if(option == 51 && optionLen == 4)
		{
			if(DhcpState == 1)
			{
				ipLease = (buffer[2]<<24)+(buffer[3]<<16)+(buffer[4]<<8)+(buffer[5]);
			}
		}

		bytesToHex(buffer, isrBuf, optionLen+2);
		write(isrBuf, optionLen*2+4); writeChar(';');
		buffer = buffer + optionLen + 2;
	}

}


void ProcessIcmpPacket(char * buffer, IpFilter_t * pFilter)
{
	write("C:",2);
	bytesToHex(buffer+IP_HEADER_LEN, isrBuf, 2);
	write(isrBuf,4); writeChar(';');
	if(IpQueryStackIndex == (MAX_IP_QUERIES-1))
		return;
	IpQueryStackIndex++;
	CopyIpFilter(pFilter, &(IpQueryStack[IpQueryStackIndex].ipInfo));
	IpQueryStack[IpQueryStackIndex].queryType = ICMP;
}

void ProcessTcpPacket(char * buffer, IpFilter_t * pFilter)
{
	writeChar('T');
	bytesToHex(buffer+IP_HEADER_LEN, isrBuf, 2);
	write(isrBuf,4); writeChar(';');
}

void ProcessUdpPacket(char * buffer, IpFilter_t * pFilter)
{
	unsigned short sourcePort = *(unsigned short*)(buffer + IP_HEADER_LEN);
	unsigned short destPort = *(unsigned short*)(buffer + IP_HEADER_LEN+2);
	write("U:",2);
	bytesToHex((char*)&sourcePort, isrBuf, 2);
	write(isrBuf,4); writeChar(';');
	bytesToHex((char*)&destPort, isrBuf, 2);
	write(isrBuf,4); writeChar(';');
	if(destPort == 68)
		ProcessDhcpPacket(buffer);
	
}

void DefaultProcessIpPacket(char * buffer, IpFilter_t * pFilter)
{
	write("I:",2);
	bytesToHex(buffer+IP_HEADER_LEN, isrBuf, 2);
	write(isrBuf,4); writeChar(';');
}

void ProcessArpPacket(char * buffer, unsigned int bufferSelect)
{
	write("\nA",2);
	if(IpQueryStackIndex == (MAX_IP_QUERIES-1))
		return;
	IpQueryStackIndex++;
	IpQueryStack[IpQueryStackIndex].queryType = ARP;
	IpQueryStack[IpQueryStackIndex].queryInfo[0] = MemoryRead(ETHER_RX_SRC_MAC_HIGH ^ bufferSelect);
	IpQueryStack[IpQueryStackIndex].queryInfo[1] = MemoryRead(ETHER_RX_SRC_MAC_MID ^ bufferSelect);
	IpQueryStack[IpQueryStackIndex].queryInfo[2] = MemoryRead(ETHER_RX_SRC_MAC_LOW ^ bufferSelect);
}


inline void ProcessIpPacket(char * buffer)
{
	IpFilter_t pFilter;
	
	CreateIpFilter(buffer, &pFilter);

	write("\nI:",3);
	isrBuf[11] = ';';
	IpToHex(pFilter.sourceAddr, isrBuf);
	write(isrBuf,12);
	IpToHex(pFilter.destAddr, isrBuf);
	write(isrBuf,12);
	bytesToHex((char*)&pFilter.protocol,isrBuf,1);
	write(isrBuf,2); writeChar(';');
	
	if(PassesIpFilter(&pFilter, &ipFilter) == 0)
		return;

	if(pFilter.protocol == IP_PROTOCOL_UDP)
		ProcessUdpPacket(buffer, &pFilter);
	else if(pFilter.protocol == IP_PROTOCOL_ICMP)
		ProcessIcmpPacket(buffer, &pFilter);
	else if(pFilter.protocol == IP_PROTOCOL_TCP)
		ProcessTcpPacket(buffer, &pFilter);
	else
		DefaultProcessIpPacket(buffer, &pFilter);
}


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
	
	for(i = 0; i < 192+10; i++)
	{
		*(uBuffer+o) = 0;
		o++;
	}
	o = DHCP_OPTIONS_OFFSET-4;
	*(unsigned int*)(uBuffer+o) = 0x63825363; o += 4;	// "DHCP"
	*(unsigned short*)(uBuffer+o) = 0x3501; o += 2;		// Option 53
	*(uBuffer+o) = 0x01; o+=1;	// DHCP Discover

	*(uBuffer+o) = 0xFF; o += 1;

	return CreateUdpPacket(0, 0xFFFFFFFF, 68, 67, o);
}

int ChangeToDhcpRequest()
{
	char* uBuffer = (char*)(ETHER_TXBUF+IP_HEADER_LEN+UDP_HEADER_LEN);
	int o;

	o = 20;
	*(unsigned int*)(uBuffer+o) = dhcpServerIp;	// server ip

	o = DHCP_OPTIONS_OFFSET;
	uBuffer = (char*)(ETHER_TXBUF+IP_HEADER_LEN+UDP_HEADER_LEN);
	*(unsigned int*)(uBuffer+o) = 0x35010300; o+=4;	// Option 53, DHCP Req.
	*(unsigned short*)(uBuffer+o) = 0x3204; o+=2;	// Option 50.
	*(unsigned short*)(uBuffer+o) = (ownIpAddress>>16) & 0xFFFF; o+=2;
	*(unsigned short*)(uBuffer+o) = (ownIpAddress) & 0xFFFF; o+=2;
	*(uBuffer+o) = 0xFF; o+= 1;
	return CreateUdpPacket(0, 0xFFFFFFFF, 68, 67, o);
}


void DoDhcp()
{
	int i,k;
	int repeats, dhcpAttempts;
	ipFilter.destAddr = 0;
	ipFilter.sourceAddr = 0;
	ipFilter.protocol = IP_PROTOCOL_UDP;
	transactionId = (MacMid<<16) + MacLow;
	for(dhcpAttempts = 0; dhcpAttempts < 10; dhcpAttempts++)
	{
		for(repeats = 0; repeats < 10 && ownIpAddress == 0; repeats++)
		{
			ownIpAddress = 0;
			DhcpState = 0;
			ipLease = 0;
		
			while(ETHER_TX_BUSY != 0);
			i = CreateDhcpDiscover(++transactionId);
			MemoryWrite(ETHER_TX_PACKET_LENGTH, i);
			MemoryWrite(ETHER_TX_CONTROL, 2);
			while(ETHER_TX_BUSY != 0);
			for(k = 0; k < 1000; k++)
			{
				for(i = 0; i < 10000; i++); // wait
				if(ownIpAddress != 0)
					break;
			}
		}
		DhcpState = 1;
		while(ETHER_TX_BUSY != 0);
		i = ChangeToDhcpRequest();
		MemoryWrite(ETHER_TX_PACKET_LENGTH, i);
		MemoryWrite(ETHER_TX_CONTROL, 2);
		while(ETHER_TX_BUSY != 0);
		for(k = 0; k < 1000; k++)
		{
			for(i = 0; i < 10000; i++);	// wait
			if(ipLease != 0)
			{
				DhcpState = 2;
				return;
			}
		}
	}
	
}

void WaitForTxToFinish() { while(ETHER_TX_BUSY != 0); }

void SendBufferedPacket(int txLen)
{
	while(ETHER_TX_BUSY != 0);
	MemoryWrite(ETHER_TX_PACKET_LENGTH, txLen);
	MemoryWrite(ETHER_TX_CONTROL, 2);
}

void SendArpReply(unsigned short macDestHi, unsigned short macDestMid, unsigned short macDestLow, unsigned int destIp)
{
	unsigned short s;
	unsigned short * buffer;
	if(ownIpAddress == 0)
		return;
	
	WaitForTxToFinish();
	EthernetSetTxMacDest(macDestHi,macDestMid,macDestLow);
	MemoryWrite(ETHER_TX_TYPE, ETHER_TYPE_ARP);
	buffer = (unsigned short*)(ETHER_TXBUF);
	*buffer++ = 0x0001;	// Ethernet
	*buffer++ = 0x0800;	// IPv4
	*buffer++ = 0x0604;	// 6 > 4
	*buffer++ = 0x0002;	// Reply
	s = MemoryRead(ETHER_OWN_MAC_HIGH);
	*buffer++ = s;
	s = MemoryRead(ETHER_OWN_MAC_MID);
	*buffer++ = s;
	s = MemoryRead(ETHER_OWN_MAC_LOW);
	*buffer++ = s;
	s = (ownIpAddress>>16)&0xFFFF;
	*buffer++ = s;
	s = ownIpAddress&0xFFFF;
	*buffer++ = s;
	s = 0;
	*buffer++ = s;
	*buffer++ = s;
	*buffer++ = s;
	s = (destIp>>16)&0xFFFF;
	*buffer++ = s;
	s = destIp&0xFFFF;
	*buffer++ = s;
	SendBufferedPacket(46);
	MemoryWrite(ETHER_TX_TYPE, ETHER_TYPE_IPV4);
}

void ServiceIpQueryStack()
{
	int index = IpQueryStackIndex;
	unsigned short pmh, pmm, pml;
	IpQueryStackIndex = MAX_IP_QUERIES;	// 'Locks' the stack.
	if(index < 0)
	{
		IpQueryStackIndex = -1;
		return;
	}
	if(IpQueryStack[index].queryType == ARP)
		write("a",1);
	else if(IpQueryStack[index].queryType == ICMP)
		write("c",1);
	writeChar('0'+index);
	writeChar('\n');
	pmh = MemoryRead(ETHER_TX_DEST_MAC_HIGH);
	pmm = MemoryRead(ETHER_TX_DEST_MAC_MID);
	pml = MemoryRead(ETHER_TX_DEST_MAC_LOW);
	SendArpReply(IpQueryStack[index].queryInfo[0],IpQueryStack[index].queryInfo[1],IpQueryStack[index].queryInfo[2],IpQueryStack[index].queryInfo[3]);
	
	EthernetSetTxMacDest(pmh,pmm,pml);
	IpQueryStackIndex = index-1;
}

void EthernetExercise()
{
	int i ;
	unsigned int s,u;
	char * txP;
	unsigned int destIp;
	int txLen = 42;
	
	
	EthernetInit(MacHigh, MacMid, MacLow);


	DoDhcp();
	
	write("\nIP Address: ",13);
	IpToHex(ownIpAddress, mainBuf);
	write(mainBuf,11); write(";",1);
	write("Lease: ",7);
	bytesToHex((char*)&ipLease, mainBuf, 4);
	write(mainBuf,8); writeChar('\n');
	
	SendArpReply(0xFFFF,0xFFFF,0xFFFF, ownIpAddress);
	
	EthernetSetTxMacDest(0x70f3,0x9500,0x721f);
	destIp = CharToIp("192.168.104.64");
	ipFilter.destAddr = ownIpAddress;
	ipFilter.protocol = 0;
	ipFilter.sourceAddr = 0;
	
	for(s = 0; s < 32; s++)
	{
		ServiceIpQueryStack();
		txLen = 1024;
		txP = (char*)(ETHER_TXBUF + IP_HEADER_LEN + UDP_HEADER_LEN);
		WaitForTxToFinish();
		for(i = 0; i < txLen; i++)
		{
			*txP = i;
			txP++;
		}

		txLen = CreateUdpPacket(ownIpAddress,destIp,0,60000 + s, txLen);
		
		SendBufferedPacket(txLen);
	}

	while(1)
		ServiceIpQueryStack();
}



#endif
