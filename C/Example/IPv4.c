#ifndef __IPV4_C
#define __IPV4_C


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

void IpToChar(unsigned int ip, char * buf)
{
	int o = 0;
	char b = (ip>>24)&0xFF;
	o += itoa_p(b,buf+o,10);
	buf[o++] = '.';
	b = (ip>>16)&0xFF;
	o += itoa_p(b,buf+o,10);
	buf[o++] = '.';
	b = (ip>>8)&0xFF;
	o += itoa_p(b,buf+o,10);
	buf[o++] = '.';
	b = ip&0xFF;
	o += itoa_p(b,buf+o,10);
}

/*
	Fills the Ethernet TX Buffer with the header for an IP packet.
	Returns the total length of the IP packet.
*/
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

#endif