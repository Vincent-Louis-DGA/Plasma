-------------------------------------------------------------------------------
-- Writes to a binary file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity BinaryFileWriter is
  
  generic (
    FileName      : string    := "default.bin";
    EchoToConsole : std_logic := '0');

  port (
    clk    : in std_logic;
    enable : in std_logic;
    din    : in std_logic_vector(7 downto 0));

end BinaryFileWriter;

architecture testbench of BinaryFileWriter is

  type data_file_t is file of character;
  
begin  -- testbench

  DO_WRITE : process (clk)
    file theFile          : data_file_t open write_mode is FileName;
    variable c            : character;
    variable console_line : line;
    variable line_length  : natural := 0;
  begin  -- process DO_WRITE
    if rising_edge(clk) then            -- rising clock edge
      if enable = '1' then
        c := character'val(conv_integer(unsigned(din)));
        write(theFile, c);

        if EchoToConsole = '1' then
          if din /= X"0A" and din /= X"0D" then
            write(console_line, c);
            line_length := line_length + 1;
          end if;
          if din = X"0A" or line_length >= 72 then
            writeline(output, console_line);
            line_length := 0;
          end if;
        end if;
        
      end if;
    end if;
  end process DO_WRITE;

end testbench;
