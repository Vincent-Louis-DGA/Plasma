-- Demonstrates the PlasmaBootLoader using the Plasma/C/Example project.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity PlasmaBootLoader_tb is

end;

architecture testbench of PlasmaBootLoader_tb is

  constant uartLogFile : string := "bootLoaderLog.dat";
  constant codeFile    : string := "../../../C/Example/Example.bin";

  signal clk_100    : std_logic := '1';
  signal clk_50     : std_logic := '1';
  signal reset_ex_n : std_logic := '0';
  signal reset_n    : std_logic;


  signal switches : std_logic_vector(7 downto 0);
  signal buttons  : std_logic_vector(4 downto 0);
  signal leds     : std_logic_vector(7 downto 0);
  signal pmod     : std_logic_vector(7 downto 0);

  signal bootToggle : std_logic;
  signal bootData   : std_logic_vector(7 downto 0);

  signal fileToggle      : std_logic;
  signal fileData        : std_logic_vector(7 downto 0);
  signal fileEnable      : std_logic;
  signal fileLength      : std_logic_vector(31 downto 0);
  signal EndOfSourceFile : std_logic;

  signal Uart_bypassRx         : std_logic_vector(7 downto 0);
  signal Uart_bypassRxWeToggle : std_logic;
  signal Uart_bypassTx         : std_logic_vector(7 downto 0);
  signal Uart_bypassTxDvToggle : std_logic;

  
begin  -- testbench
  
  UUT : entity work.PlasmaBlockRam
    generic map (simulateRam     => '1',
                 simulateProgram => '0')
    port map (
      clk_100    => clk_100,
      reset_ex_n => reset_ex_n,
      sysClk     => clk_50,
      reset_n    => reset_n,
      switches   => switches,
      leds       => leds,
      buttons    => buttons,
      pmod       => pmod,

      Uart_bypassRx         => Uart_bypassRx,
      Uart_bypassRxWeToggle => Uart_bypassRxWeToggle,
      Uart_bypassTx         => Uart_bypassTx,
      Uart_bypassTxDvToggle => Uart_bypassTxDvToggle
      );

  clk_100  <= not clk_100 after 5 ns;
  switches <= X"03";
  buttons  <= "11111";


  TB : process
  begin  -- process TB
    reset_ex_n <= '0';
    fileEnable <= '0';
    bootToggle <= '0';
    bootData   <= (others => '0');
    wait for 100 ns;
    reset_ex_n <= '1';
    wait for 1000 ns;
    wait until clk_50 = '1';

    bootData   <= fileLength(31 downto 24);
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= fileLength(23 downto 16);
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= fileLength(15 downto 8);
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= fileLength(7 downto 0);
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= X"40";
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= X"00";
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= X"00";
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    bootData   <= X"00";
    wait until clk_50 = '1';
    wait until clk_50 = '1';
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';
    wait until clk_50 = '1';

    fileEnable <= '1';

    wait until leds(0) = '1';
    wait for 1 us;
    bootToggle <= fileToggle;
    wait until clk_50 = '1';
    fileEnable <= '0';
    wait until clk_50 = '1';
    bootData   <= X"12";
    bootToggle <= not bootToggle;
    wait until clk_50 = '1';


    wait;
  end process TB;

  Uart_bypassRx         <= bootData   when fileEnable = '0' else fileData;
  Uart_bypassRxWeToggle <= bootToggle when fileEnable = '0' else fileToggle;

  FileReader : entity work.UartFileReader
    generic map (
      SourceFile => codeFile,
      DestFile   => uartLogFile,
      SIM_UART   => '0')
    port map (
      clk_uart         => clk_50,
      reset_n          => reset_n,
      readEnable       => fileEnable,
      regDin           => Uart_bypassTx,
      regRxToggle      => Uart_bypassTxDvToggle,
      regDout          => fileData,
      regDvToggle      => fileToggle,
      SourceFileLength => fileLength,
      EndOfSourceFile  => EndOfSourceFile,
      uartTx           => open,
      uartRx           => '1');


end testbench;
