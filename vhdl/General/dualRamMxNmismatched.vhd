-------------------------------------------------------------------------------
-- Inferred BlockRAM with mismatched size ports.
-- Port A must have a data width less than Port B.
--
-- This still needs some work...  Currently it's all broken.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dualRamMxNmismatched is
  generic (
    Na : integer := 1;                  -- Width in bytes of A port
    Ma : integer := 11;                 -- Address with of A port
    Nb : integer := 4;                  -- Width in bytes of B port
    Mb : integer := 9                   -- Address with of A port
    ); 

  port (
    clka  : in  std_logic;
    wea   : in  std_logic_vector(Na-1 downto 0)   := (others => '0');
    addra : in  std_logic_vector(Ma-1 downto 0)   := (others => '0');
    dina  : in  std_logic_vector(Na*8-1 downto 0) := (others => '0');
    douta : out std_logic_vector(Na*8-1 downto 0);
    clkb  : in  std_logic;
    web   : in  std_logic_vector(Nb-1 downto 0)   := (others => '0');
    addrb : in  std_logic_vector(Mb-1 downto 0)   := (others => '1');
    dinb  : in  std_logic_vector(Nb*8-1 downto 0) := (others => '0');
    doutb : out std_logic_vector(Nb*8-1 downto 0)
    );

end dualRamMxNmismatched;

architecture logic of dualRamMxNmismatched is

  type   mem_array is array(0 to (2**Ma)-1) of std_logic_vector(7 downto 0);
  type   mem_file is array(0 to Na-1) of mem_array;
  signal ram      : mem_file                        := (others => (others => (others => '0')));
  signal raddra_i : std_logic_vector(Ma-1 downto 0);
  signal raddrb_i : std_logic_vector(Ma-1 downto 0);
  signal addra_i  : std_logic_vector(Ma-1 downto 0) := (others => '0');
  signal addrb_i  : std_logic_vector(Ma-1 downto 0) := (others => '0');

  signal dina_i : std_logic_vector(Na*8-1 downto 0);
  signal dinb_i : std_logic_vector(Nb*8-1 downto 0);

  signal ratio : integer := 4;

 constant zero : std_logic_vector(7 downto 0) := X"00";
  
begin  -- logic

  ratio <= Nb/Na;

  dina_i <= to_X01(dina);
  dinb_i <= to_X01(dinb);

  raddra_i <= to_X01(addra);
  raddrb_i <= to_X01(addrb) & zero((Ma-Mb)-1 downto 0);

  RAM_GEN : for i in 0 to Na-1 generate

    PROCESS_A : process (clka, clkb)
    begin  -- process WRITE_PROCESS
      if rising_edge(clka) then         -- rising clock edge
        addra_i <= raddra_i;
        if wea(i) = '1' then
          ram(i)(to_integer(unsigned(raddra_i))) <= dina_i(8*i+7 downto 8*i);
        end if;
      end if;
      if rising_edge(clkb) then         -- rising clock edge
        addrb_i <= raddrb_i(raddrb_i'left downto (Ma-Mb));
        if web(i) = '1' then
          ram(i)(to_integer(unsigned(raddrb_i))) <= dinb_i(8*i+7 downto 8*i);
          ram(i)(to_integer(unsigned(raddrb_i)+1)) <= dinb_i(8*i+15 downto 8*i+8);
          ram(i)(to_integer(unsigned(raddrb_i)+2)) <= dinb_i(8*i+23 downto 8*i+16);
          ram(i)(to_integer(unsigned(raddrb_i)+3)) <= dinb_i(8*i+31 downto 8*i+24);
        end if;
      end if;
    end process PROCESS_A;

    douta(8*i+7 downto 8*i) <= ram(i)(to_integer(unsigned(addra_i)));

    doutb(8*i+31 downto 8*i+24) <= ram(i)(to_integer(unsigned(addrb_i)+0));
    doutb(8*i+23 downto 8*i+16) <= ram(i)(to_integer(unsigned(addrb_i)+1));
    doutb(8*i+15 downto 8*i+8)  <= ram(i)(to_integer(unsigned(addrb_i)+2));
    doutb(8*i+7 downto 8*i+0)   <= ram(i)(to_integer(unsigned(addrb_i)+3));
    

  end generate RAM_GEN;

  
end logic;
