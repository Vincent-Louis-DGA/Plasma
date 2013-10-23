library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.plasmaPeriphRegisters.all;

entity PlasmaEthernet_tb is

end;

architecture testbench of PlasmaEthernet_tb is

  constant uartLogFile : string := "log.dat";

  signal clk_100    : std_logic := '1';
  signal reset_ex_n : std_logic := '0';


  signal switches : std_logic_vector(7 downto 0);
  signal buttons  : std_logic_vector(4 downto 0);
  signal leds     : std_logic_vector(7 downto 0);
  signal pmod     : std_logic_vector(7 downto 0);

  signal Uart_bypassRx         : std_logic_vector(7 downto 0);
  signal Uart_bypassRxWeToggle : std_logic;
  signal Uart_bypassTx         : std_logic_vector(7 downto 0);
  signal Uart_bypassTxDvToggle : std_logic;

  -- Ethernet
  signal ethernetMDIO    : std_logic                    := 'H';
  signal ethernetMDC     : std_logic;
  signal ethernetINT_n   : std_logic;
  signal ethernetRESET_n : std_logic;
  signal ethernetCOL     : std_logic                    := '1';
  signal ethernetCRS     : std_logic                    := '1';
  signal ethernetRXDV    : std_logic                    := '0';
  signal ethernetRXCLK   : std_logic                    := '0';
  signal ethernetRXER    : std_logic                    := '0';
  signal ethernetRXD     : std_logic_vector(7 downto 0) := (others => '0');
  signal ethernetGTXCLK  : std_logic;
  signal ethernetTXCLK   : std_logic                    := '0';
  signal ethernetTXER    : std_logic;
  signal ethernetTXEN    : std_logic;
  signal ethernetTXD     : std_logic_vector(7 downto 0);

  type Vector8 is array (natural range <>) of std_logic_vector(7 downto 0);
  signal ArpPacket : Vector8(0 to 75) := (
    X"55", X"55", X"55", X"55", X"55", X"55", X"55", X"5D",
    X"70", X"f3", X"95", X"00", X"72", X"1f", X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"08", X"06", X"00", X"01",
    X"08", X"00", X"06", X"04", X"00", X"02", X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"c0", X"a8", X"68", X"fe",
    X"70", X"f3", X"95", X"00", X"72", X"1f", X"c0", X"a8", X"68", X"40", X"00", X"00", X"00", X"00", X"00", X"00",
    X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
    X"AB", X"CD", X"EF", X"89");

begin  -- testbench

  process
  begin  -- process
    ethernetMDIO <= 'H';
    wait for 6 us;
    ethernetMDIO <= 'L';
    wait for 6 us;
  end process;

  UUT : entity work.PlasmaEthernet
    generic map (simulateRam     => '1',
                 simulateProgram => '1',
                 uartLogFile     => uartLogFile)
    port map (
      clk_100    => clk_100,
      reset_ex_n => reset_ex_n,
      switches   => switches,
      leds       => leds,
      buttons    => buttons,
      pmod       => pmod,
      UartRx     => '1',

      Uart_bypassRx         => Uart_bypassRx,
      Uart_bypassRxWeToggle => Uart_bypassRxWeToggle,
      Uart_bypassTx         => Uart_bypassTx,
      Uart_bypassTxDvToggle => Uart_bypassTxDvToggle,

      ethernetMDIO    => ethernetMDIO,
      ethernetMDC     => ethernetMDC,
      ethernetINT_n   => ethernetINT_n,
      ethernetRESET_n => ethernetRESET_n,
      ethernetCOL     => ethernetCOL,
      ethernetCRS     => ethernetCRS,
      ethernetRXDV    => ethernetRXDV,
      ethernetRXCLK   => ethernetRXCLK,
      ethernetRXER    => ethernetRXER,
      ethernetRXD     => ethernetRXD,
      ethernetGTXCLK  => ethernetGTXCLK,
      ethernetTXCLK   => ethernetTXCLK,
      ethernetTXER    => ethernetTXER,
      ethernetTXEN    => ethernetTXEN,
      ethernetTXD     => ethernetTXD
      );

  clk_100       <= not clk_100       after 5 ns;
  ethernetRXCLK <= not ethernetRXCLK after 4 ns;
  ethernetTXCLK <= not ethernetTXCLK after 20 ns;
  switches      <= X"03";


  TB : process
  begin  -- process TB
    reset_ex_n <= '0';
    buttons    <= (others => '0');
    wait for 100 ns;
    reset_ex_n <= '1';

    wait for 20 us;
    buttons <= "00001";
    wait for 20 us;
    buttons <= "00000";
    wait for 20 us;
    buttons <= "00001";
    wait;
  end process TB;

  SEND_TO_RX : process
  begin  -- process SEND_TO_RX
    ethernetRXDV <= '0';
    ethernetRXD  <= (others => 'U');
    wait for 1 us;

    for i in 0 to ArpPacket'right loop
      
      wait until ethernetRXCLK = '1';
      wait for 0.5 ns;
      ethernetRXD  <= (others => 'U');
      ethernetRXDV <= '1';
      wait for 5 ns;
      ethernetRXD  <= ArpPacket(i);
      
    end loop;  -- i
    wait until ethernetRXCLK = '1';
    wait for 0.5 ns;
    ethernetRXDV <= '0';
    ethernetRXD  <= (others => 'U');

    wait for 2 us;
  end process SEND_TO_RX;
  
end testbench;
