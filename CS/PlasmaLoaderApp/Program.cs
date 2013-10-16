using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace PlasmaLoaderApp

{
	class Program
	{


		static void Main(string[] args)
		{
			try
			{
                PlasmaLoaderApp loader = new PlasmaLoaderApp(args);
                if (!loader.ArgsValid)
                    PlasmaLoaderApp.PrintUsage();
                else
    				loader.Load();
			}

            catch (ArgumentException ex) { Console.WriteLine("Error: " + ex.Message + "\n"); PlasmaLoaderApp.PrintUsage(); }
			catch (TimeoutException tx) { Console.WriteLine("Error: " + tx.Message + "\n"); }
			catch (UnauthorizedAccessException ux) { Console.WriteLine("Error: " + ux.Message + "\n"); }
			catch (BootLoaderException bx) { Console.WriteLine("Error: " + bx + "\n"); }
            catch (System.IO.IOException ix) { Console.WriteLine("Error: " + ix + "\n"); PlasmaLoaderApp.PrintUsage(); }

			Console.WriteLine("Press any key to exit...");
			Console.ReadKey();
		}
	}
}
