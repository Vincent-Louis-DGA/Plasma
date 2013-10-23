library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity EthernetMDIO is
  
  generic (
    PHY_ADDR : std_logic_vector(4 downto 0) := "00111");

  port (
    clk_50    : in    std_logic;
    reset_n   : in    std_logic;
    MDC       : out   std_logic := '1';
    MDIO      : inout std_logic := '1';
    addr      : in    std_logic_vector(4 downto 0);
    readData  : out   std_logic_vector(15 downto 0);
    writeData : in    std_logic_vector(15 downto 0);
    we        : in    std_logic;
    re        : in    std_logic;
    rts       : out   std_logic);

end EthernetMDIO;

architecture rtl of EthernetMDIO is

  type   STATE is (idle, preambleW, preambleR, write16, write32, read16);
  signal cs       : STATE := idle;
  signal count    : std_logic_vector(7 downto 0);
  signal pcount   : std_logic_vector(4 downto 0);
  signal mdcUp    : std_logic;
  signal mdcDown  : std_logic;
  signal writeReg : std_logic_vector(31 downto 0);
  signal readReg  : std_logic_vector(15 downto 0);
  signal mdi      : std_logic;
  
begin  -- rtl

  DO_MDC : process (clk_50, reset_n)
  begin  -- process DO_MDC
    if reset_n = '0' then               -- asynchronous reset (active low)
      mdcUp   <= '0';
      mdcDown <= '0';
      MDC     <= '1';
      pcount  <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      pcount  <= pcount + 1;
      mdcUp   <= '0';
      mdcDown <= '0';
      if pcount = 0 then
        mdcUp <= '1';
        MDC   <= '1';
      end if;
      if pcount(pcount'left-1 downto 0) = 0 and pcount(pcount'left) = '1' then
        mdcDown <= '1';
        MDC     <= '0';
      end if;
    end if;
  end process DO_MDC;

  DO_STATES : process (clk_50, reset_n)
  begin  -- process DO_STATES
    if reset_n = '0' then               -- asynchronous reset (active low)
      cs       <= idle;
      count    <= (others => '0');
      writeReg <= (others => '0');
      readReg  <= (others => '0');
      rts      <= '0';
      readData <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      case cs is
        when idle =>
          rts   <= '1';
          count <= (others => '0');
          if we = '1' then
            cs       <= preambleW;
            writeReg <= X"5" & PHY_ADDR & addr & "10" & writeData;
            rts      <= '0';
          end if;
          if re = '1' then
            cs       <= preambleR;
            writeReg <= X"6" & PHY_ADDR & addr & "10" & X"0000";
            rts      <= '0';
          end if;

          
        when preambleW =>
          if mdcDown = '1' then
            count <= count + 1;
            if count = 32 then
              cs    <= write32;
              count <= (others => '0');
            end if;
          end if;

          
        when preambleR =>
          if mdcDown = '1' then
            count <= count + 1;
            if count = 32 then
              cs    <= write16;
              count <= (others => '0');
            end if;
          end if;
          
        when write32 =>
          if mdcDown = '1' then
            count    <= count + 1;
            writeReg <= writeReg(writeReg'left-1 downto 0) & '0';
            if count = 31 then
              cs    <= idle;
              count <= (others => '0');
            end if;
          end if;
        when write16 =>
          readReg <= (others => '0');
          if mdcDown = '1' then
            count    <= count + 1;
            writeReg <= writeReg(writeReg'left-1 downto 0) & '0';
            if count = 14 then
              cs    <= read16;
              count <= (others => '0');
            end if;
          end if;
        when read16 =>
          if mdcDown = '1' then
            count   <= count + 1;
            readReg <= readReg(readReg'left-1 downto 0) & mdi;
            if count = 16 then
              readData <= readReg;
              cs       <= idle;
              count    <= (others => '0');
            end if;
          end if;
          
        when others => null;
      end case;
    end if;
  end process DO_STATES;

  with cs select
    MDIO <=
    writeReg(writeReg'left) when write32,
    writeReg(writeReg'left) when write16,
    'Z'                     when read16,
    'Z'                     when idle,
    '1'                     when others;

  REG_INPUT : process (clk_50, reset_n)
  begin  -- process REG_INPUT
    if reset_n = '0' then               -- asynchronous reset (active low)
      mdi <= '1';
    elsif rising_edge(clk_50) then      -- rising clock edge
      case MDIO is
        when '0'    => mdi <= '0';
        when 'L'    => mdi <= '0';
        when others => mdi <= '1';
      end case;
    end if;
  end process REG_INPUT;


end rtl;
