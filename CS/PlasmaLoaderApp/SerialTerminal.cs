using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.IO.Ports;

namespace PlasmaLoaderApp
{
	public class SerialTerminal
	{
		SerialPort serialPort;
        System.IO.FileStream log = null;
        bool silent = false;
        int silentChars = 0;
        int prevChars = 0;

        public SerialTerminal(SerialPort serialPort, char[] initialChars, string logFile = null, bool silent = false)
		{
            this.serialPort = serialPort;
            this.silent = silent;
            if (logFile != null)
                OpenLog(logFile);
            Console.WriteLine("\nBegin Terminal... Press CTRL-X to quit\n");
			if (!serialPort.IsOpen)
				serialPort.Open();
            this.serialPort.Encoding = ASCIIEncoding.UTF8;
			this.serialPort.DataReceived += new SerialDataReceivedEventHandler(serialPort_DataReceived);

            for (int i = 0; i < initialChars.Length; i++)
                WriteChar(initialChars[i]);

			while (true)
			{
				ConsoleKeyInfo key = Console.ReadKey(true);
				if (key.Modifiers.HasFlag(ConsoleModifiers.Control) && key.Key == ConsoleKey.X)
					break;
                WriteChar(key.KeyChar);
				if (key.Key == ConsoleKey.Enter)
					serialPort.Write(new char[] { '\n' }, 0, 1);
			}
            CloseLog();
		}

        public void WriteChar(char c)
        {
            char [] ca = {c};
            serialPort.Write(ca, 0, 1);
        }

        

        void OpenLog(string logFile)
        {
            Console.WriteLine("\nLogging to \"" + logFile + "\"");
            log = new System.IO.FileStream(logFile, System.IO.FileMode.Create);
        }

        void CloseLog()
        {
            if (log != null)
            {
                log.Dispose();
                log = null;
            }
        }

        int dots = 0;

		void serialPort_DataReceived(object sender, SerialDataReceivedEventArgs e)
		{
			int bytes = serialPort.BytesToRead;
			byte [] buffer = new byte[bytes];
			serialPort.Read(buffer, 0, bytes);
            if (!silent)
                Console.Write(UTF8Encoding.UTF8.GetString(buffer));
            else
            {
                silentChars += bytes;
                if ((silentChars - prevChars) > 1024)
                {
                    if (dots % 64 == 0)
                        Console.WriteLine();
                    if (dots % 16 == 0)
                        Console.Write(dots.ToString("X"));
                    else
                        Console.Write(".");

                    dots++;

                    prevChars += bytes;
                }
            }
            if (log != null && log.CanWrite)
                log.Write(buffer, 0, buffer.Length);
		}
	}
}
