using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.IO;
using System.Text;

namespace ConvertAxfToVhdl
{
    public class AxfToVhdlConverter
    {
        const string InitDataTemplateString = "<INIT_DATA>";

        string inputFile = null;
        string outputFile = null;
        string templateFile = null;
        int RamWidthInBytes = 4;
        int RamAddressWidth = 13;
        List<byte> vals;

        public AxfToVhdlConverter(string[] args)
        {
            ParseArgs(args);
            ReadInputFile();
            FillTemplate();
            WriteOutputFile();
        }

        private void ParseArgs(string[] args)
        {
            if (args.Length < 1)
                throw new Exception("Input file not specified.");
            List<string> argList = args.ToList();
            while (argList.Count > 0)
            {
                if (argList[0].Equals("-M"))
                    if (argList.Count < 2)
                        throw new ArgumentException("Inufficient number of arguments.");
                    else
                    {
                        RamAddressWidth = int.Parse(argList[1]);
                        argList.RemoveAt(1);
                        argList.RemoveAt(0);
                    }
                else if (argList[0].Equals("-N"))
                    if (argList.Count < 2)
                        throw new ArgumentException("Inufficient number of arguments.");
                    else
                    {
                        RamWidthInBytes = int.Parse(argList[1]);
                        argList.RemoveAt(1);
                        argList.RemoveAt(0);
                    }
                else if (argList[0].Equals("-o"))
                    if (argList.Count < 2)
                        throw new ArgumentException("Inufficient number of arguments.");
                    else
                    {
                        outputFile = argList[1];
                        argList.RemoveAt(1);
                        argList.RemoveAt(0);
                    }
                else if (argList[0].Equals("-i"))
                    if (argList.Count < 2)
                        throw new ArgumentException("Inufficient number of arguments.");
                    else
                    {
                        inputFile = argList[1];
                        argList.RemoveAt(1);
                        argList.RemoveAt(0);
                    }
                else
                {
                    inputFile = argList[0];
                    argList.RemoveAt(0);
                }
            }
            if (string.IsNullOrWhiteSpace(outputFile))
                outputFile = Path.GetDirectoryName(inputFile) + Path.DirectorySeparatorChar + Path.GetFileNameWithoutExtension(inputFile) + ".vhd";
        }

        class ProgramHeader { public int type; public int offset; public int length; public int vaddr;}

        private void ReadInputFile()
        {
            Console.WriteLine("Reading input file '" + inputFile + "'...");
            using (BufferedStream reader = new BufferedStream(new FileStream(inputFile, FileMode.Open)))
            {
                ProgramHeader[] pheader = ReadElfProgramHeader(reader);
                List<byte> inputVals = new List<byte>();
                if (pheader.Length < 1)
                    throw new ArgumentException("ELF file contains no records.");

                int outOffset = pheader[0].vaddr;
                // Round of starting address to align with a quarter of the RamAddressWidth
                outOffset = (outOffset >> (RamAddressWidth-2)) << (RamAddressWidth-2);

                for (int p = 0; p < pheader.Length; p++)
                {
                    // Insert blanks between program segments.
                    for (int i = outOffset; i < pheader[p].vaddr; i ++)
                    {
                        inputVals.Add(0);
                    }
                    outOffset = pheader[p].vaddr;
                    // Only copy text type blocks.
                    if (pheader[p].type == 1)
                    {
                        reader.Seek(pheader[p].offset, SeekOrigin.Begin);
                        for (int i = 0; i < pheader[p].length; i ++)
                        {
                            int b = reader.ReadByte();
                            // If end of file, just write out 0's. This shouldn't happen anyway.
                            if (b == -1)
                                inputVals.Add(0);
                            else
                                inputVals.Add(Convert.ToByte(b));
                            outOffset ++;
                        }
                    }
                }

                vals = inputVals;
            }
        }

        ProgramHeader[] ReadElfProgramHeader(BufferedStream elfFileReader)
        {
            elfFileReader.Seek(0, SeekOrigin.Begin);
            int elf = ReadNextBigEndianInt(elfFileReader);
            if (elf != 0x7f454c46)
                throw new ArgumentException("Input file is not an ELF file.");
            elfFileReader.Seek(0x1C, SeekOrigin.Begin);
            int po = ReadNextBigEndianInt(elfFileReader);
            elfFileReader.Seek(11, SeekOrigin.Current);
            int plen = elfFileReader.ReadByte();
            elfFileReader.Seek(1, SeekOrigin.Current);
            int pnum = elfFileReader.ReadByte();
            elfFileReader.Seek(po, SeekOrigin.Begin);
            ProgramHeader[] ret = new ProgramHeader[pnum];
            for (int i = 0; i < pnum; i++)
            {
                ret[i] = new ProgramHeader();
                ret[i].type = ReadNextBigEndianInt(elfFileReader);
                ret[i].offset = ReadNextBigEndianInt(elfFileReader);
                ret[i].vaddr = ReadNextBigEndianInt(elfFileReader);
                elfFileReader.Seek(4, SeekOrigin.Current);
                ret[i].length = ReadNextBigEndianInt(elfFileReader);
                elfFileReader.Seek(12, SeekOrigin.Current);
            }
            return ret;
        }

        byte[] integerBytes = new byte[4];
        int ReadNextBigEndianInt(BufferedStream reader)
        {
            int len = reader.Read(integerBytes, 0, 4);
            for (int i = len; i < 4; i++)
                integerBytes[len] = 0;

            return BitConverter.ToInt32(integerBytes.Reverse().ToArray(),0);
        }

        private void WriteOutputFile()
        {
            Console.WriteLine("Writing output file '" + outputFile + "'...");
            using (StreamWriter writer = new StreamWriter(outputFile))
            {
                writer.Write(templateFile);
            }
        }

        private void FillTemplate()
        {
            Console.WriteLine("Filling template: N = " + RamWidthInBytes + ", M = " + RamAddressWidth + "...");
            templateFile = ConvertAxfToVhdl.Resource.dualRamTemplate;
            templateFile = templateFile.Replace("0009", RamAddressWidth.ToString());
            templateFile = templateFile.Replace("0004", RamWidthInBytes.ToString());

            string vhdlEntity = Path.GetFileNameWithoutExtension(outputFile);
            templateFile = templateFile.Replace("dualRamTemplate", vhdlEntity);


            StringBuilder sb = new StringBuilder(InitDataTemplateString);
            int line = 0;
            while ((vals.Count & 0x03) != 0)
                vals.Add(0);
            while (vals.Count >= RamWidthInBytes)
            {
                if ((line&0x03) == 0)
                    sb.Append("\n");
                sb.Append(line.ToString() + " => X\"");
                sb.Append(ByteString(vals.Take(RamWidthInBytes)) + "\",");
                vals.RemoveRange(0, RamWidthInBytes);
                line++;
            }

            templateFile = templateFile.Replace(InitDataTemplateString, sb.ToString());
            templateFile = templateFile.Replace("\r\n", "\n");
        }

        private string ByteString(IEnumerable<byte> bytes)
        {
            string s = "";
            foreach(byte b in bytes)
                s += b.ToString("X2");
            return s;
        }

        public static void PrintUsage()
        {
            Console.WriteLine("Usage: AxfToVhdlConverter.exe [option] <AxfFile>");
            Console.WriteLine("eg, AxfToVhdlConverter.exe Example.axf");
            Console.WriteLine("Options:");
            Console.WriteLine("  -o <OutputFilename>\tSpecify non-standard output filename.");
            Console.WriteLine("  -i <InputFilename>\tSpecifically state which argument is input filename.");
            Console.WriteLine("  -M <RamAddressWidth>\tRAM Address width in bits.");
            Console.WriteLine("  -N <RamWidthInBytes>\tRAM data width in bytes.");
        }
    }
}
