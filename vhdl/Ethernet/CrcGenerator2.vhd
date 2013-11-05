
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.PCK_CRC32_D8.all;

entity CrcGenerator is
  generic (
    REVERSEINPUT  : std_logic                     := '1';
    REVERSEOUTPUT : std_logic                     := '1';
    INITVAL       : std_logic_vector(31 downto 0) := X"FFFFFFFF";
    FINALXOR      : std_logic_vector(31 downto 0) := X"FFFFFFFF");
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    sReset  : in  std_logic;
    en      : in  std_logic;
    din     : in  std_logic_vector (7 downto 0);
    dv      : out std_logic;
    dout    : out std_logic_vector (31 downto 0)  -- CRC output
    );
end CrcGenerator;

architecture rtl of CrcGenerator is

-- Generator polynomial is
--  32   26   23   22   16   12   11   10   8   7   5   4   2   
-- x  + x  + x  + x  + x  + x  + x  + x  + x + x + x + x + x + x + 1
  constant POLYNOMIAL : std_logic_vector(31 downto 0) := X"04C11DB7";

  signal crc    : std_logic_vector(31 downto 0);
  signal input  : std_logic_vector(7 downto 0);
  signal output : std_logic_vector(31 downto 0);

begin

  REV : if REVERSEINPUT = '1' generate
    REVL : for i in 0 to 7 generate
      input(7-i) <= din(i);
    end generate REVL;
  end generate REV;
  NREV : if REVERSEINPUT /= '1' generate
    input <= din;
  end generate NREV;

  process (clk, reset_n)
  begin  -- process
    if reset_n = '0' then               -- asynchronous reset (active low)
      crc <= INITVAL;
      dv  <= '0';
    elsif rising_edge(clk) then         -- rising clock edge
      dv <= '0';
      if sReset = '1' then
        crc <= INITVAL;
        
      elsif en = '1' then
        dv  <= '1';
        crc <= nextCRC32_D8(input, crc);
      end if;
    end if;
  end process;

  REVO : if REVERSEOUTPUT = '1' generate
    REVOL : for i in 0 to 31 generate
      output(31-i) <= crc(i);
    end generate REVOL;
  end generate REVO;
  NREVO : if REVERSEOUTPUT /= '1' generate
    output <= crc;
  end generate NREVO;
  dout <= output xor FINALXOR;

end rtl;
