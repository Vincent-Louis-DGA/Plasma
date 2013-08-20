-- Demonstrates the PlasmaBootLoader using the Plasma/C/Example project.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity PlasmaBootLoader_tb is

end;

architecture testbench of PlasmaBootLoader_tb is

  constant uartLogFile : string := "bootLoaderLog.dat";
  constant codeFile    : string := "../../C/Example/code.txt";

  signal clk_100    : std_logic := '1';
  signal clk_50     : std_logic := '1';
  signal reset_ex_n : std_logic := '0';
  signal reset_n    : std_logic;


  signal switches : std_logic_vector(7 downto 0);
  signal buttons  : std_logic_vector(4 downto 0);
  signal leds     : std_logic_vector(7 downto 0);
  signal pmod     : std_logic_vector(7 downto 0);

  signal Uart_bypassRx         : std_logic_vector(7 downto 0);
  signal Uart_bypassRxWeToggle : std_logic;
  signal Uart_bypassTx         : std_logic_vector(7 downto 0);
  signal Uart_bypassTxDv       : std_logic;

  
begin  -- testbench
  
  UUT : entity work.PlasmaBlockRam
    generic map (simulation => '1')
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
      Uart_bypassTxDv       => Uart_bypassTxDv
      );

  clk_100  <= not clk_100 after 5 ns;
  switches <= X"03";
  buttons  <= "00000";


  TB : process
  begin  -- process TB
    reset_ex_n <= '0';
    wait for 100 ns;
    reset_ex_n <= '1';
    wait;
  end process TB;

  FileReader : entity work.UartFileReader
    generic map (
      SourceFile => codeFile,
      DestFile   => uartLogFile,
      SIM_UART   => '0')
    port map (
      clk_uart       => clk_50,
      reset_n        => reset_n,
      readEnable     => '1',
      regDin         => Uart_bypassTx,
      regWriteEnable => Uart_bypassTxDv,
      regDout        => Uart_bypassRx,
      regDvToggle    => Uart_bypassRxWeToggle,
      uartTx         => open,
      uartRx         => '1');


end testbench;
