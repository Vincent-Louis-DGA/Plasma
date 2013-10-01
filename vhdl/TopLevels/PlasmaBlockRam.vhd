---------------------------------------------------------------------
-- TITLE: Plasma MCU with DDR2 RAM targetting Digilent ATLYS Board
-- AUTHOR: Adrian Jongenelen
--
-- Adds a shared Fifo to get 32-bit words in/out of the CPU.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.plasmaPeriphRegisters.all;


entity PlasmaBlockRam is
  generic(
    uartLogFile     : string    := "UNUSED";
    simulateRam     : std_logic := '0';
    simulateProgram : std_logic := '0'
    );
  port(
    clk_100    : in  std_logic;
    reset_ex_n : in  std_logic;         -- external reset
    UartRx     : in  std_logic := '1';
    UartTx     : out std_logic;

    leds     : out   std_logic_vector(7 downto 0);
    switches : in    std_logic_vector(7 downto 0);
    buttons  : in    std_logic_vector(4 downto 0);
    pmod     : inout std_logic_vector(7 downto 0);

    Uart_bypassRx         : in  std_logic_vector(7 downto 0) := (others => '0');
    Uart_bypassRxWeToggle : in  std_logic                    := '0';
    Uart_bypassTx         : out std_logic_vector(7 downto 0);
    Uart_bypassTxDvToggle : out std_logic;

    FifoDin   : in  std_logic_vector(31 downto 0) := (others => '0');
    FifoDout  : out std_logic_vector(31 downto 0);
    FifoWe    : in  std_logic                     := '0';
    FifoRe    : in  std_logic                     := '0';
    FifoFull  : out std_logic;
    FifoEmpty : out std_logic;
    FifoClear : in  std_logic                     := '0';

    ExBusDin  : in  std_logic_vector(31 downto 0) := (others => '0');
    ExBusDout : out std_logic_vector(31 downto 0);
    ExBusAddr : out std_logic_vector(31 downto 0);
    ExBusRe   : out std_logic;
    ExBusWe   : out std_logic;

    -- Flash
    FlashCLK   : out   std_logic;
    FlashCS    : out   std_logic;
    FlashMemDq : inout std_logic_vector(3 downto 0)
    );
end;


architecture logic of PlasmaBlockRam is

  signal sysClk : std_logic;
  signal reset_n : std_logic;

begin  --architecture

  MCU : entity work.PlasmaTop
    generic map (
      uartLogFile     => uartLogFile,
      simulateRam     => simulateRam,
      simulateProgram => simulateProgram,
      AtlysDDR        => '0')
    port map (
      clk_100               => clk_100,
      reset_ex_n            => reset_ex_n,
      sysClk                => sysClk,
      reset_n               => reset_n,
      UartRx                => UartRx,
      UartTx                => UartTx,
      Uart_bypassRx         => Uart_bypassRx,
      Uart_bypassRxWeToggle => Uart_bypassRxWeToggle,
      Uart_bypassTx         => Uart_bypassTx,
      Uart_bypassTxDvToggle => Uart_bypassTxDvToggle,
      leds                  => leds,
      switches              => switches,
      buttons               => buttons,
      pmod                  => pmod,
      FlashClk              => FlashClk,
      FlashCS               => FlashCS,
      FlashMemDq            => FlashMemDq);


end;  --architecture logic

