using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace UdpLogger
{
    public interface PacketHandler
    {
        void HandlePacket(UdpPacket packet);
    }
    public class PacketConsoleWriter : PacketHandler
    {
        int packetNum = 0;

        public void HandlePacket(UdpPacket packet)
        {
            packetNum++;
            string receiveString = Encoding.ASCII.GetString(packet.PacketData);
            Console.WriteLine("{0} Received: {1} {2} {3}", packetNum, packet.Source, packet.Destination, receiveString);
            Console.WriteLine();
        }
    }

    public class PacketLogWriter : PacketHandler, IDisposable
    {
        public int HeaderBytesToRemove { get; set; }
        Stream stream;

        public PacketLogWriter(string path)
        {
            stream = new FileStream(path, FileMode.Create);
        }

        public void HandlePacket(UdpPacket packet)
        {
            if(packet.PacketData.Length > HeaderBytesToRemove)
                stream.Write(packet.PacketData, HeaderBytesToRemove, packet.PacketData.Length - HeaderBytesToRemove);
        }

        protected bool disposed = false;
        public void Dispose()
        {
            if (!disposed)
            {
                if (stream != null)
                {
                    stream.Dispose();
                    stream = null;
                }
                disposed = true;
            }
        }
    }
}
