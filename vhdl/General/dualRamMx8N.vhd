-------------------------------------------------------------------------------
-- Inferred BlockRAM
-- raddra/raddrb, ie, read addresses are only useful for small RAMs using
-- distributed memory. BlockRAM doesn't really have that many address ports.
-- SIMULATION generic (default '0') allows different read addresses.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dualRamMx8N is
  generic (
    N : integer := 4;                   -- Width in bytes
    M : integer := 11;
    SIMULATION : std_logic := '0');                 -- Address width

  port (
    clka   : in  std_logic;
    wea    : in  std_logic_vector(N-1 downto 0)   := (others => '0');
    addra  : in  std_logic_vector(M-1 downto 0)   := (others => '0');
    dina   : in  std_logic_vector(N*8-1 downto 0) := (others => '0');
    raddra : in  std_logic_vector(M-1 downto 0)   := (others => '0');
    douta  : out std_logic_vector(N*8-1 downto 0);
    clkb   : in  std_logic;
    web    : in  std_logic_vector(N-1 downto 0)   := (others => '0');
    addrb  : in  std_logic_vector(M-1 downto 0)   := (others => '1');
    dinb   : in  std_logic_vector(N*8-1 downto 0) := (others => '0');
    raddrb : in  std_logic_vector(M-1 downto 0)   := (others => '0');
    doutb  : out std_logic_vector(N*8-1 downto 0)
    );

end dualRamMx8N;

architecture logic of dualRamMx8N is

  type   mem_array is array(0 to (2**M)-1) of std_logic_vector(7 downto 0);
  type   mem_file is array(0 to N-1) of mem_array;
  signal ram     : mem_file                       := (others => (others => (others => '0')));
  signal raddra_i : std_logic_vector(M-1 downto 0);
  signal raddrb_i : std_logic_vector(M-1 downto 0);
  signal addra_i : std_logic_vector(M-1 downto 0) := (others => '0');
  signal addrb_i : std_logic_vector(M-1 downto 0) := (others => '0');

  signal dina_i : std_logic_vector(N*8-1 downto 0);
  signal dinb_i : std_logic_vector(N*8-1 downto 0);
   
  
begin  -- logic

  dina_i <= to_X01(dina);
  dinb_i <= to_X01(dinb);
  
  SIM: if SIMULATION = '1' generate
    raddra_i <= to_X01(raddra);
    raddrb_i <= to_X01(raddrb);
  end generate SIM;

  NOT_SIM: if SIMULATION /= '1' generate
    raddra_i <= addra;
    raddrb_i <= addrb;
  end generate NOT_SIM;
  
  RAM_GEN : for i in 0 to N-1 generate

    PROCESS_A : process (clka, clkb)
    begin  -- process WRITE_PROCESS
      if rising_edge(clka) then         -- rising clock edge
        addra_i <= raddra_i;
        if wea(i) = '1' then
          ram(i)(to_integer(unsigned(addra))) <= dina_i(8*i+7 downto 8*i);
        end if;
      end if;
      if rising_edge(clkb) then         -- rising clock edge
        addrb_i <= raddrb_i;
        if web(i) = '1' then
          ram(i)(to_integer(unsigned(addrb))) <= dinb_i(8*i+7 downto 8*i);
        end if;
      end if;
    end process PROCESS_A;
    douta(8*i+7 downto 8*i) <= ram(i)(to_integer(unsigned(addra_i)));
    doutb(8*i+7 downto 8*i) <= ram(i)(to_integer(unsigned(addrb_i)));

  end generate RAM_GEN;
  
end logic;
