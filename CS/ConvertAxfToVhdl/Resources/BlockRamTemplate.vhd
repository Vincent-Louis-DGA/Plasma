-------------------------------------------------------------------------------
-- Inferred BlockRAM with Initial Values
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity BlockRamTemplate is
  generic (
    N : integer := 0004;                -- Width in bytes
    M : integer := 0009);               -- Address width

  port (
    clk  : in  std_logic;
    wbe   : in  std_logic_vector(N-1 downto 0)   := (others => '0');
    addr : in  std_logic_vector(M-1 downto 0)   := (others => '0');
    din  : in  std_logic_vector(N*8-1 downto 0) := (others => '0');
    dout : out std_logic_vector(N*8-1 downto 0)
    );

end BlockRamTemplate;

architecture logic of BlockRamTemplate is

  type mem_file is array(0 to (2**M)-1) of std_logic_vector(N*8-1 downto 0);
  
  signal ram : mem_file := (
    -- Insert initial values below here, eg,
    -- 0 => X"0000",
    -- 1 => X"0001",
    -- <INIT_DATA>
    others => (others => '0')
    );
  signal addr_i : std_logic_vector(M-1 downto 0);

  signal din_i : std_logic_vector(N*8-1 downto 0);

  
begin  -- logic

  din_i <= to_X01(din);


  PROCESS_A : process (clk)
  begin  -- process WRITE_PROCESS
    if rising_edge(clk) then           -- rising clock edge
      addr_i <= addr;
      for i in 0 to N-1 loop
        if wbe(i) = '1' then
          ram(to_integer(unsigned(addr)))(8*i+7 downto 8*i) <= din_i(8*i+7 downto 8*i);
        end if;
      end loop;  -- i
    end if;
  end process PROCESS_A;

  dout <= ram(to_integer(unsigned(addr_i)));

end logic;
