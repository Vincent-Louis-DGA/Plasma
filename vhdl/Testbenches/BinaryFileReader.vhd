-------------------------------------------------------------------------------
-- Reads a binary file within a testbench.
-- Reads 1 byte each clock cycle that enable is high.
-- NB - Not appropriate for Synthesis!
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity BinaryFileReader is
  
  generic (
    FileName : string);

  port (
    clk        : in  std_logic;
    enable     : in  std_logic;
    dout       : out std_logic_vector(7 downto 0);
    dv         : out std_logic;
    FileLength : out std_logic_vector(31 downto 0);
    EndOfFile  : out std_logic := '0');

end BinaryFileReader;

architecture testbench of BinaryFileReader is

  type data_file_t is file of character;
  
begin  -- testbench

  MEASURE_LENGTH : process
    file theFile   : data_file_t open read_mode is FileName;
    variable c     : character;
    variable count : std_logic_vector(31 downto 0) := (others => '0');
  begin  -- process MEASURE_LENGTH
    while not endfile(theFile) loop
      read(theFile, c);
      count := count + 1;
    end loop;
    FileLength <= count;
    wait;
  end process MEASURE_LENGTH;

  DO_READ : process (clk)
    file theFile : data_file_t open read_mode is FileName;
    variable c   : character;
  begin  -- process DO_READ
    if rising_edge(clk) then            -- rising clock edge
      dv <= '0';
      if endfile(theFile) then
        EndOfFile <= '1';
      elsif enable = '1' then
        read(theFile, c);
        dout <= conv_std_logic_vector(character'pos(c), 8);
        dv   <= '1';
        EndOfFile <= '0';
      end if;
    end if;
  end process DO_READ;
  

end testbench;
