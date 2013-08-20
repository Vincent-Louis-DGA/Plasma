library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity PlasmaDataAcquisition_tb is

end;

architecture testbench of PlasmaDataAcquisition_tb is

  constant uartLogFile : string := "log.dat";

  signal clk_100    : std_logic := '1';
  signal reset_ex_n : std_logic := '0';


  signal switches : std_logic_vector(7 downto 0);
  signal buttons  : std_logic_vector(4 downto 0);
  signal leds     : std_logic_vector(7 downto 0);
  signal pmod     : std_logic_vector(7 downto 0);

  signal UartRx : std_logic := '1';
  signal UartTx : std_logic := '1';

  signal Uart_bypassRx         : std_logic_vector(7 downto 0) := (others => '0');
  signal Uart_bypassRxWeToggle : std_logic                    := '0';
  signal Uart_bypassTx         : std_logic_vector(7 downto 0);
  signal Uart_bypassTxDv       : std_logic;

  
begin  -- testbench
  
  UUT : entity work.PlasmaDataAcquisition
    generic map (simulation  => '1',
                 uartLogFile => uartLogFile)
    port map (
      clk_100    => clk_100,
      reset_ex_n => reset_ex_n,
      switches   => switches,
      leds       => leds,
      buttons    => buttons,
      pmod       => pmod,
      UartRx     => UartRx,
      UartTx     => UartTx,

      Uart_bypassRx         => Uart_bypassRx,
      Uart_bypassRxWeToggle => Uart_bypassRxWeToggle,
      Uart_bypassTx         => Uart_bypassTx,
      Uart_bypassTxDv       => Uart_bypassTxDv
      );

  clk_100  <= not clk_100 after 5 ns;
  switches <= X"08";
  buttons  <= "00000";
  pmod <= X"bd";


  TB : process
  begin  -- process TB
    reset_ex_n <= '0';
    wait for 100 ns;
    reset_ex_n <= '1';
    wait;
  end process TB;
  
end testbench;
