library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.plasmaPeriphRegisters.all;
use work.EthernetRegisters.all;
use work.EthernetTestPackets.all;

entity PlasmaEthernet_tb is

end;

architecture testbench of PlasmaEthernet_tb is

  constant uartLogFile : string := "log.dat";

  signal clk_100    : std_logic := '1';
  signal clk_125    : std_logic := '0';
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

  -- Ethernet TX Source
  signal clk        : std_logic                     := '0';
  signal etherDin2  : std_logic_vector(31 downto 0) := (others => '0');
  signal etherDout2 : std_logic_vector(31 downto 0);
  signal etherAddr2 : std_logic_vector(15 downto 0) := (others => '0');
  signal etherRe2   : std_logic                     := '0';
  signal etherWbe2  : std_logic_vector(3 downto 0)  := (others => '0');


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
  clk_125       <= not clk_125       after 4 ns;
  clk           <= not clk           after 8 ns;
  ethernetRXCLK <= not ethernetRXCLK after 4 ns;
  ethernetTXCLK <= not ethernetTXCLK after 20 ns;
  switches      <= X"03";


  UUT2 : entity work.EthernetTop
    port map (
      clk           => clk,
      clk_125       => clk_125,
      reset_n       => reset_ex_n,
      ethernetRXCLK => ethernetRXCLK,
      ethernetTXCLK => ethernetTXCLK,
      ethernetTXD   => ethernetRXD,
      ethernetTXEN  => ethernetRXDV,
      etherAddr     => etherAddr2,
      etherDin      => etherDin2,
      etherDout     => etherDout2,
      etherRe       => etherRe2,
      etherWbe      => etherWbe2);


  tb : process
  begin  -- process tb
    wait until reset_ex_n = '1';
    wait for 200 ns;

    CpuWrite(X"000070F3", ETHER_MAC_HIGH, clk, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00009500", ETHER_MAC_MID, clk, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"0000721F", ETHER_MAC_LOW, clk, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00000800", TX_ETHERTYPE, clk, etherDin2, etherWbe2, etherAddr2);
    wait for 5 us;

    CpuSendPacket(PingRequest, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);
    wait for 5 us;

    CpuWrite(X"0000020A", TX_DEST_MAC_HIGH, clk, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00003544", TX_DEST_MAC_MID, clk, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00005441", TX_DEST_MAC_LOW, clk, etherDin2, etherWbe2, etherAddr2);

    wait for 15 us;
    CpuSendPacket(ShortPacket, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);

    wait for 20 us;
    CpuSendPacket(PingRequest, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);

    wait for 20 us;
    CpuSendPacket(ArpPacket, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);
    wait for 20 us;
    CpuSendPacket(UdpPacket16, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);
    wait for 20 us;
    CpuSendPacket(UdpPacket16, clk, etherDin2, etherWbe2, etherAddr2, etherDout2);


    wait;
  end process tb;

  RX_TB : process
  begin  -- process TB
    reset_ex_n <= '0';
    buttons    <= (others => '0');
    wait for 100 ns;
    reset_ex_n <= '1';

    wait;
  end process RX_TB;

  
end testbench;
