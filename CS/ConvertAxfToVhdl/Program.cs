using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace ConvertAxfToVhdl
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                AxfToVhdlConverter converter = new AxfToVhdlConverter(args);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex+"\n");
                AxfToVhdlConverter.PrintUsage();
                Console.WriteLine("\nPress any key to continue...");
                Console.ReadKey();
            }


            
        }

    }
}
