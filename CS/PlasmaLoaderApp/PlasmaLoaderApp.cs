using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.IO;
using System.IO.Ports;
using System.Text;
using System.Reflection;

namespace PlasmaLoaderApp
{
	public class BootLoaderException : IOException {
		public BootLoaderException(string s) : base(s) { }
	}

	public class PlasmaLoaderApp
	{
		string serialPort = "COM10";
		int baudRate = 460800;
		string sourceFile = null;
        string logFile = null;
        bool silent = false;
        public bool ArgsValid { get; set; }

        public PlasmaLoaderApp(string[] args)
		{
            ArgsValid = true;
			processArgs(args);
		}

		void processArgs(string[] args)
		{
			List<string> argList = new List<string>(args);
			while (argList.Count > 0)
			{
				processArg(argList);
                if (!ArgsValid)
                    return;
			}
		}

		void processArg(List<string> argList)
		{
            if (argList[0].Equals("-?") || argList[0].Equals("-Help"))
            {
                ArgsValid = false;
                argList.RemoveAt(0);
                return;
            }
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
            {
                throw new ArgumentException("Source file does not exist: " + sourceFile);
            }

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
                    Console.WriteLine("Length: " + len + "\nSource: " + sourceFile);
                    int s;
                    byte[] b = new byte[4];
                    byte[] r = new byte[4];
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
                }
                SerialTerminal terminal = new SerialTerminal(sp, new char[0], logFile, silent);

                // Do nothing... control passed to terminal.

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
            Assembly assembly = Assembly.GetExecutingAssembly();
            StreamReader reader = new StreamReader(assembly.GetManifestResourceStream("PlasmaLoaderApp.readme.txt"));
            string readme = reader.ReadToEnd();
            Console.WriteLine(readme);

		}
	}
}
