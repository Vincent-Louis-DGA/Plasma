-------------------------------------------------------------------------------
-- Ports configured as Addressable Registers.
-- Bidirectional port is last entity in the file.
-- Register Map (for Bidirectional port):
--      0x0     Port Output Register            R/W
--      0x1     Bitwise SET                     W
--      0x2     Bitwise CLR                     W
--      0x3     Bitwise Toggle                  W
--      0x4     Port Input Register             R
--      0x5     Tristate Control (1 = High Z)   R/W
--      0x6-7   Port Input Register             R
--
-- Output only ports Only have top 4 registers.
-- Input only ports have only 1 read-only register for the value.
--
-------------------------------------------------------------------------------
-- An output port, with SET, CLR and TOGGLE registers.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OutputPort is
  
  generic (
    W : integer := 8);                  -- Port Width

  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    port_o   : out std_logic_vector(W-1 downto 0);
    reg_din  : in  std_logic_vector(w-1 downto 0);
    reg_we   : in  std_logic;
    reg_addr : in  std_logic_vector(1 downto 0)
    );

end OutputPort;

architecture logic of OutputPort is

  signal port_reg : std_logic_vector(W-1 downto 0) := (others => '0');
  
  
begin  -- logic

  process (clk, reset)
  begin  -- process
    if reset = '1' then                 -- asynchronous reset (active high)
      port_reg <= (others => '0');
    elsif rising_edge(clk) then         -- rising clock edge
      if reg_we = '1' then
        case reg_addr is
          when "00"   => port_reg <= reg_din;
          when "01"   => port_reg <= port_reg or reg_din;         -- SET
          when "10"   => port_reg <= port_reg and (not reg_din);  -- CLR
          when others => port_reg <= (port_reg) xor reg_din;      -- TGL
        end case;
      end if;
    end if;
  end process;

  port_o <= port_reg;

end logic;

-------------------------------------------------------------------------------
-- An input port, with debouncing circuit
-------------------------------------------------------------------------------
-- Adrian Jongenelen, 2012
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity InputPort is
  
  generic (
    W         : integer   := 8;         -- Port Width
    D         : integer   := 8;         -- Debouncer Counter Width
    RESET_VAL : std_logic := '0'
    );

  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    port_i  : in  std_logic_vector(W-1 downto 0);
    reg_i   : out std_logic_vector(W-1 downto 0);
    pulse_i : out std_logic_vector(W-1 downto 0));

end InputPort;

architecture logic of InputPort is

  constant MAX      : std_logic_vector(D-1 downto 0) := (others => '1');
  constant min      : std_logic_vector(D-1 downto 0) := (others => '0');
  type     COUNT_ARRAY is array (W-1 downto 0) of std_logic_vector(D-1 downto 0);
  signal   counters : COUNT_ARRAY;
  signal   port_reg : std_logic_vector(W-1 downto 0) := (others => RESET_VAL);
  signal   reg2     : std_logic_vector(W-1 downto 0);
  
begin  -- logic

  COUNT_GEN : for i in 0 to W-1 generate
    DO_COUNT : process (clk, reset)
    begin  -- process DO_COUNT
      if reset = '1' then               -- asynchronous reset (active high)
        counters(i) <= '1' & min(D-2 downto 0);
        port_reg(i) <= RESET_VAL;
        reg_i(i)    <= RESET_VAL;
      elsif rising_edge(clk) then       -- rising clock edge
        if port_i(i) = '1' or port_i(i) = 'H' then
          port_reg(i) <= '1';
        else
          port_reg(i) <= '0';
        end if;
        if counters(i) /= MAX and port_reg(i) = '1' then
          counters(i) <= counters(i) + 1;
        end if;
        if counters(i) /= min and port_reg(i) = '0' then
          counters(i) <= counters(i) - 1;
        end if;
        reg_i(i) <= counters(i)(D-1);
      end if;
    end process DO_COUNT;

    process(clk)
    begin
      if rising_edge(clk) then
        reg2(i) <= counters(i)(D-1);
        if reg2(i) = '0' and counters(i)(D-1) = '1' then
          pulse_i(i) <= '1';
        else
          pulse_i(i) <= '0';
        end if;
      end if;
    end process;

  end generate COUNT_GEN;
  

end logic;

-------------------------------------------------------------------------------
-- A Bidirectional port of generic width.
-- Contains features common to Input and Output ports, as well as Tristate.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity BidirPort is
  
  generic (
    W : integer := 8;                   -- Port Width
    D : integer := 8                    -- Debouncer Width
    );                 

  port (
    clk      : in    std_logic;
    reset    : in    std_logic;
    reg_din  : in    std_logic_vector(W-1 downto 0);  -- for CPU Write
    reg_dout : out   std_logic_vector(W-1 downto 0);  -- for CPU Read
    reg_we   : in    std_logic;
    reg_addr : in    std_logic_vector(2 downto 0);
    port_io  : inout std_logic_vector(W-1 downto 0));

end BidirPort;

architecture logic of BidirPort is

  signal port_i    : std_logic_vector(W-1 downto 0);
  signal port_o    : std_logic_vector(W-1 downto 0) := (others => '0');
  signal tris      : std_logic_vector(W-1 downto 0) := (others => '1');
  signal op_we     : std_logic                      := '0';
  signal reg_addr1 : std_logic_vector(2 downto 0)   := (others => '0');
  signal db2       : std_logic                      := '0';
  
begin  -- logic

  TRIS_GEN : for i in 0 to W-1 generate
    port_io(i) <= port_o(i) when tris(i) = '0' else 'Z';
  end generate TRIS_GEN;

  process (clk, reset)
  begin  -- process
    if reset = '1' then                 -- asynchronous reset (active high)
      tris      <= (others => '1');
      reg_addr1 <= (others => '0');
      db2       <= '0';
    elsif rising_edge(clk) then         -- rising clock edge
      db2       <= '0';
      reg_addr1 <= reg_addr;
      if reg_addr = "101" and reg_we = '1' then
        tris <= reg_din;
      end if;
      if reg_addr1 = "100" then
        db2 <= '1';
      end if;
    end if;
  end process;

  op_we <= reg_we when reg_addr(2) = '0' else '0';

  process (port_o, port_i, tris, reg_addr1)
  begin  -- process
    case reg_addr1 is
      when "000"  => reg_dout <= port_o;
      when "001"  => reg_dout <= port_o;
      when "010"  => reg_dout <= port_o;
      when "011"  => reg_dout <= port_o;
      when "100"  => reg_dout <= port_i;
      when "101"  => reg_dout <= tris;
      when others => reg_dout <= port_i;
    end case;
  end process;

  u1_in : entity work.InputPort
    generic map (
      W => W,
      D => D)
    port map (
      clk    => clk,
      reset  => reset,
      port_i => port_io,
      reg_i  => port_i);

  u2_out : entity work.OutputPort
    generic map (
      W => W)
    port map (
      clk      => clk,
      reset    => reset,
      reg_din  => reg_din,
      reg_we   => op_we,
      reg_addr => reg_addr(1 downto 0),
      port_o   => port_o);


end logic;
