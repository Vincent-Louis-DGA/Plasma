#ifndef __IPV4STACK_C
#define __IPV4STACK_C

#include "Ethernet.c"
#include "IPv4.c"




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
#define MAX_IP_QUERIES 4
volatile IpQuery_t IpQueryStack [MAX_IP_QUERIES];
volatile int IpQueryStackIndex = -1;






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


void IPv4StackExercise()
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