using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net;

namespace UdpLogger
{
    public class UdpPacket
    {
        public IPEndPoint Source { get; set; }
        public IPEndPoint Destination { get; set; }
        public byte[] PacketData { get; set; }

        public UdpPacket()
        {
            Source = new IPEndPoint(IPAddress.Any, 0);
            Destination = new IPEndPoint(IPAddress.Any, 0);
            PacketData = new byte[0];
        }
    }
}
