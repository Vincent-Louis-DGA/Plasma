using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Net;
using System.Net.Sockets;
using System.Threading;

namespace UdpLogger
{
    public partial class UdpLoggerForm : Form
    {
        static Color StoppedColour = Color.Lime;
        static Color GoingColour = Color.Yellow;
        const string StoppedString = "Start";
        const string GoingString = "Stop";

        UdpClient udpClient = null;
        IPEndPoint destination;
        Thread listenThread = null;
        volatile bool serverRunning = false;
        //byte[] magicWord = new byte[] { 123, 34, 104, 111, 115, 116, 95, 105, 110, 116 };
        byte[] magicWord = new byte[] { 0x7F,(byte)'D',(byte)'T',(byte)'A' };
        int packetNum = 0;
        int discardedPackets = 0;

        PacketFilter filter;
        List<PacketHandler> handlers = new List<PacketHandler>();
        PacketLogWriter logHandler;
        PacketHandler consoleHandler;

        public UdpLoggerForm()
        {
            InitializeComponent();
            consoleHandler = new PacketConsoleWriter();
        }

        private void startButton_Click(object sender, EventArgs e)
        {
            if (startButton.BackColor == StoppedColour)
                Start();
            else
                Stop();
        }

        private void Start()
        {
            discardedBox.Text = "0 / 0";
            //Start listening.
            listenThread = new Thread(new ThreadStart(Listening));
            listenThread.Start();
            //Change state to indicate the server starts.

            startButton.BackColor = GoingColour;
            startButton.Text = GoingString;
        }

        private void Stop()
        {
            try
            {
                //Stop listening.
                serverRunning = false;
                listenThread.Join();
                Console.WriteLine("Listener stopped.");
                udpClient.Close();
                startButton.Text = StoppedString;
                startButton.BackColor = StoppedColour;
            }
            catch (Exception ex)
            {
                Console.WriteLine("" + ex);
            }

        }

        private void Listening()
        {
            discardedPackets = 0;
            packetNum = 0;
            serverRunning = true;
            destination = new IPEndPoint(IPAddress.Any, (int)destPortBox.Value);
            // Set up the checker/filter
            if (discardCheckBox.Checked)
                filter = new MagicNumberPacketFilter()
                {
                    MagicWord = magicWord,
                    AcceptableDestinationPort = (int)destPortBox.Value,
                    AcceptableSourcePort = (int)srcPortBox.Value
                };
            else
                filter = null;

            // Choose the handler.
            try { logHandler = new PacketLogWriter(logFileBox.Text) { HeaderBytesToRemove = 8 }; }
            catch { logHandler = null; }
            handlers.Clear();
            if (logHandler != null)
                handlers.Add(logHandler);
            else
                handlers.Add(consoleHandler);


            //Create the server.
            udpClient = new UdpClient(destination);
            Console.WriteLine("listening on "+destination+"...");
            //Listening loop.
            udpClient.BeginReceive(new AsyncCallback(ReceiveCallback), udpClient);
            while (serverRunning)
            {
                //Sleep for UI to work.
                Thread.Sleep(500);
            }
            if (logHandler != null)
                logHandler.Dispose();
            logHandler = null;
        }


        void ReceiveCallback(IAsyncResult ar)
        {
            try
            {
                IPEndPoint src = new IPEndPoint(IPAddress.Any, (int)destPortBox.Value);
                

                byte[] receiveBytes = udpClient.EndReceive(ar, ref src);
                UdpPacket packet = new UdpPacket();
                packet.PacketData = receiveBytes;
                packet.Source = src;
                packet.Destination = destination;

                if (filter == null)
                    HandlePacket(packet);
                else if (filter.PassesFilter(packet))
                    HandlePacket(packet);
                else
                    discardedPackets++;

                udpClient.BeginReceive(new AsyncCallback(ReceiveCallback), udpClient);

                packetNum++;
                this.BeginInvoke((MethodInvoker)delegate { discardedBox.Text = "" + discardedPackets + "/" + packetNum; });
                
            }
            catch (ObjectDisposedException) { }
            catch (Exception ex)
            {
                Console.WriteLine("" + ex);
            }
        }

        private void HandlePacket(UdpPacket packet)
        {
            foreach(PacketHandler handler in handlers)
             handler.HandlePacket(packet);
        }


        private void UdpLoggerForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            Stop();
        }

        private void fileButton_Click(object sender, EventArgs e)
        {
            SaveFileDialog sfd = new SaveFileDialog();
            sfd.Filter = "Binary data files (*.dat)|*.dat|All files (*.*)|*.*";
            if (sfd.ShowDialog() == System.Windows.Forms.DialogResult.OK)
                logFileBox.Text = sfd.FileName;
        }
    }
}
