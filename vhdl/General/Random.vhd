-------------------------------------------------------------------------------
-- 32-bit Random number generator using psuedo random sequence generator
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity Random is
  generic (
    WIDTH : integer range 2 to 32 := 32);
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    dout  : out std_logic_vector(WIDTH-1 downto 0);  -- Random output
    re    : in  std_logic;              -- read enable. Advances state
    din   : in  std_logic_vector(WIDTH-1 downto 0);  -- Set random output
    we    : in  std_logic);             -- write enable for din

end Random;

architecture logic of Random is

  type TtapBits is array (2 to 32) of integer;
  constant tapBits : TtapBits := (
    2  => 0, 3 => 0, 4 => 0, 5 => 1,
    6  => 0, 7 => 0, 8 => 2, 9 => 3,
    10 => 2, 11 => 1, 12 => 0, 13 => 2,
    14 => 0, 15 => 0, 16 => 8, 17 => 2,
    18 => 6, 19 => 5, 20 => 2, 21 => 1,
    22 => 0, 23 => 4, 24 => 4, 25 => 2,
    26 => 4, 27 => 7, 28 => 2, 29 => 1,
    30 => 6, 31 => 2, 32 => 14
    );

  signal randomValue : std_logic_vector(WIDTH-1 downto 0) := (others => '1');
  signal randXor     : std_logic                          := '0';
  
begin  -- logic

  randXor <= randomValue(WIDTH-1) xor randomValue(tapBits(WIDTH));
  dout    <= randomValue;

  DO_RAND : process (clk, reset)
  begin  -- process DO_RAND
    if reset = '1' then                 -- asynchronous reset (active high)
      randomValue <= (others => '1');
    elsif rising_edge(clk) then         -- rising clock edge
      if we = '1' then
        randomValue <= din;
      elsif re = '1' then
        randomValue <= randomValue(WIDTH-2 downto 0) & randXor;
      end if;
    end if;
  end process DO_RAND;

end logic;
