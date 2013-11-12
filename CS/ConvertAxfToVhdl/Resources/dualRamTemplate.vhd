-------------------------------------------------------------------------------
-- Inferred BlockRAM with Initial Values
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity dualRamTemplate is
  generic (
    N : integer := 0004;                -- Width in bytes
    M : integer := 0009);               -- Address width

  port (
    clka  : in  std_logic;
    wea   : in  std_logic_vector(N-1 downto 0)   := (others => '0');
    addra : in  std_logic_vector(M-1 downto 0)   := (others => '0');
    dina  : in  std_logic_vector(N*8-1 downto 0) := (others => '0');
    douta : out std_logic_vector(N*8-1 downto 0);
    clkb  : in  std_logic;
    web   : in  std_logic_vector(N-1 downto 0)   := (others => '0');
    addrb : in  std_logic_vector(M-1 downto 0)   := (others => '1');
    dinb  : in  std_logic_vector(N*8-1 downto 0) := (others => '0');
    doutb : out std_logic_vector(N*8-1 downto 0)
    );

end dualRamTemplate;

architecture logic of dualRamTemplate is

  type mem_file is array(0 to (2**M)-1) of std_logic_vector(N*8-1 downto 0);
  
  signal ram : mem_file := (
    -- Insert initial values below here, eg,
    -- 0 => X"0000",
    -- 1 => X"0001",
    -- <INIT_DATA>
    others => (others => '0')
    );
  signal addra_i : std_logic_vector(M-1 downto 0);
  signal addrb_i : std_logic_vector(M-1 downto 0);

  signal dina_i : std_logic_vector(N*8-1 downto 0);
  signal dinb_i : std_logic_vector(N*8-1 downto 0);

  
begin  -- logic

  dina_i <= to_X01(dina);
  dinb_i <= to_X01(dinb);



  PROCESS_A : process (clka, clkb)
  begin  -- process WRITE_PROCESS
    if rising_edge(clka) then           -- rising clock edge
      for i in 0 to N-1 loop
        if wea(i) = '1' then
          ram(to_integer(unsigned(addra)))(8*i+7 downto 8*i) <= dina_i(8*i+7 downto 8*i);
        end if;
      end loop;  -- i
      addra_i <= addra;
    end if;

    if rising_edge(clkb) then           -- rising clock edge
      for i in 0 to N-1 loop
        if web(i) = '1' then
          ram(to_integer(unsigned(addrb)))(8*i+7 downto 8*i) <= dinb_i(8*i+7 downto 8*i);
        end if;
      end loop;  -- i
      addrb_i <= addrb;
    end if;
  end process PROCESS_A;

  douta <= ram(to_integer(unsigned(addra_i)));
  doutb <= ram(to_integer(unsigned(addrb_i)));

end logic;
