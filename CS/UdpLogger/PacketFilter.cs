using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UdpLogger
{
    public interface PacketFilter
    {
        bool PassesFilter(UdpPacket packet);
    }

    public class BasicPacketFilter : PacketFilter
    {
        public int AcceptableSourcePort { get; set; }
        public int AcceptableDestinationPort { get; set; }

        public virtual bool PassesFilter(UdpPacket packet)
        {
            if (packet.Destination.Port != AcceptableDestinationPort) return false;
            if (packet.Source.Port != AcceptableSourcePort) return false;
            return true;
        }
    }

    /// <summary>
    /// A Packet filter that inspects the first few bytes of the packet to check
    /// they match a 'magic word'
    /// </summary>
    public class MagicNumberPacketFilter : BasicPacketFilter
    {
        public byte[] MagicWord { get; set; }

        public MagicNumberPacketFilter() { MagicWord = new byte[0]; }

        public override bool PassesFilter(UdpPacket packet)
        {
            if (!base.PassesFilter(packet)) return false;
            if(packet.PacketData.Length < MagicWord.Length) return false;
            for (int i = 0; i < MagicWord.Length; i++)
                if (packet.PacketData[i] != MagicWord[i])
                    return false;
            return true;
        }
    }
}
