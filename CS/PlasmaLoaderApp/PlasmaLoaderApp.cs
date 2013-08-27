using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.IO;
using System.IO.Ports;
using System.Text;

namespace PlasmaLoaderApp
{
	public class BootLoaderException : IOException {
		public BootLoaderException(string s) : base(s) { }
	}

	public class PlasmaLoaderApp
	{
		string serialPort = "COM1";
		int baudRate = 921600;
		int bootOffset = 0x00000800;
		string sourceFile = null;
        string logFile = null;
        bool silent = false;

        public PlasmaLoaderApp(string[] args)
		{
			processArgs(args);
		}

		void processArgs(string[] args)
		{
			List<string> argList = new List<string>(args);
			while (argList.Count > 0)
			{
				processArg(argList);
			}
		}

		void processArg(List<string> argList)
		{
			if (argList[0].Equals("-b") && argList.Count >= 2)
			{
				int br = baudRate;
				if (!int.TryParse(argList[1], out br))
					throw new ArgumentException("Baud rate argument not an integer: "+argList[1]);
				baudRate = br;
				argList.RemoveAt(1);
				argList.RemoveAt(0);
				return;
			}
			if (argList[0].Equals("-c") && argList.Count >= 2)
			{
				if (!SerialPortExists(argList[1]))
					throw new ArgumentException("Invalid Serial Port: " + argList[1]);
				serialPort = argList[1];
				argList.RemoveAt(1);
				argList.RemoveAt(0);
				return;
			}
			if (argList[0].Equals("-o") && argList.Count >= 2)
			{
				int bo = bootOffset;
				try { bo = parsePossibleHex(argList[1]); }
				catch (Exception) { throw new ArgumentException("Could not parse bootOffset: " + argList[1]); } 
				bootOffset = bo;
				argList.RemoveAt(1);
				argList.RemoveAt(0);
				return;
            }
            if (argList[0].Equals("-l") && argList.Count >= 2)
            {
                logFile = argList[1];
                argList.RemoveAt(1);
                argList.RemoveAt(0);
                return;
            }
            if (argList[0].Equals("-s"))
            {
                silent = true;
                argList.RemoveAt(0);
                return;
            }
            if (argList.Count > 0)
            {
                sourceFile = argList[0];
                argList.RemoveAt(0);
            }
		}

		int parsePossibleHex(string hex)
		{
			if (hex.Length > 2 && hex.Substring(0, 2).Equals("0x"))
				return Int32.Parse(hex.Substring(2), System.Globalization.NumberStyles.HexNumber);
			return Int32.Parse(hex);
		}

		public void Load()
		{
            bool loadSource = !string.IsNullOrWhiteSpace(sourceFile);
			if (loadSource && !File.Exists(sourceFile))
				throw new ArgumentException("Source file does not exist: " + sourceFile);

            char[] bootChars = new char[0];
			using (SerialPort sp = new SerialPort(serialPort, baudRate))
			{
				sp.ReadBufferSize = 0x100000;
				sp.WriteBufferSize = 0x100000;
				sp.ReadTimeout = 1000;
				sp.Open();
				sp.DiscardInBuffer();
				sp.DiscardOutBuffer();

				Console.WriteLine("Port: " + serialPort + ", Baud: " + baudRate);

                if (loadSource)
                {
                    int len = (int)(new FileInfo(sourceFile)).Length;
                    int len50th = (len / 50);
                    Console.WriteLine("Offset: 0x" + bootOffset.ToString("X") + ", Length: " + len + "\nSource: " + sourceFile);
                    byte[] b = BitConverter.GetBytes(len).Reverse().ToArray();
                    byte[] r = new byte[4];
                    sp.Write(b, 0, 4);
                    System.Threading.Thread.Sleep(20);
                    int s = sp.Read(r, 0, 4);
                    if (!ArraysEqual(b, r))
                        throw new BootLoaderException("Echo response incorrect. " + s + "," + r[0] + "," + r[1] + "," + r[2] + "," + r[3] + "," + len);
                    b = BitConverter.GetBytes(bootOffset).Reverse().ToArray();
                    sp.Write(b, 0, 4);
                    System.Threading.Thread.Sleep(20);
                    s = sp.Read(r, 0, 4);
                    if (!ArraysEqual(b, r))
                        throw new BootLoaderException("Echo response incorrect.");
                    using (FileStream stream = new FileStream(sourceFile, FileMode.Open))
                    {
                        for (int i = 0; i < len; i++)
                        {
                            stream.Read(b, 0, 1);
                            sp.Write(b, 0, 1);
                            System.Threading.Thread.Sleep(0);
                            s = sp.Read(r, 0, 1);
                            if (!ArraysEqual(b, r))
                                throw new BootLoaderException("Echo response incorrect: Byte " + i + " / " + len);
                            if (i % len50th == 0)
                                Console.Write(".");
                        }
                    }
                    bootChars = new char[] { '0' };
                }
                SerialTerminal terminal = new SerialTerminal(sp, bootChars, logFile, silent);
                

				sp.Close();
			}
		}


		bool ArraysEqual(byte[] b1, byte[] b2)
		{
			if (b1 == null || b2 == null || b1.Length != b2.Length)
				return false;
			for (int i = 0; i < b1.Length; i++)
				if (b1[i] != b2[i])
					return false;
			return true;
		}

		void SendInt(SerialPort sp, int i)
		{
			byte[] b = BitConverter.GetBytes(i);
			b = b.Reverse().ToArray();
			sp.Write(b, 0, b.Length);
		}
		

		bool SerialPortExists(string name)
		{
			return true;
		}

		public static void PrintUsage()
		{
			Console.WriteLine("Usage: PlasmaBootLoader [options] <sourceFile>");
			Console.WriteLine("Options: -b <baudRate>\n\t -c <comPort>\n\t -o <bootOffset>\n");
			Console.WriteLine("Example: PlasmaBootLoader -b 115200 -c COM9 -o 0x800 test.bin\n");
		}
	}
}
