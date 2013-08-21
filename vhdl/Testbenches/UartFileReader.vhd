-------------------------------------------------------------------------------
-- Reads a file and encodes it onto a UART Tx line.
-- Listens to the Uart RX line and writes to a different file.
--
-- Does the same with the uart_bypass lines.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity UartFileReader is
  
  generic (
    SourceFile : string;
    DestFile   : string    := "default.bin";
    SIM_UART   : std_logic := '1');

  port (
    clk_uart         : in  std_logic;   -- This should be same as FPGA uses.
    reset_n          : in  std_logic;
    readEnable       : in  std_logic;
    regDin           : in  std_logic_vector(7 downto 0);
    regRxToggle      : in  std_logic;
    regDout          : out std_logic_vector(7 downto 0);
    regDvToggle      : out std_logic;
    uartTx           : out std_logic;
    uartRx           : in  std_logic;
    SourceFileLength : out std_logic_vector(31 downto 0);
    EndOfSourceFile  : out std_logic
    );

end UartFileReader;

architecture testbench of UartFileReader is

  signal readerEnable  : std_logic;
  signal readerValid   : std_logic;
  signal readerDout    : std_logic_vector(7 downto 0);
  signal readerToggle  : std_logic;
  signal count         : std_logic_vector(3 downto 0);
  signal EndOfSource : std_logic;

  signal writerEnable : std_logic;
  signal writerDin    : std_logic_vector(7 downto 0);
  
begin  -- testbench

  UART_BYPASS : process (clk_uart, reset_n)
    variable RxTg1 : std_logic;
    variable RxTg2 : std_logic;
  begin  -- process UART_BYPASS
    if reset_n = '0' then               -- asynchronous reset (active low)
      readerEnable <= '0';
      count        <= (others => '0');
      readerToggle <= '0';
      regDout      <= (others => '0');
      writerEnable <= '0';
      writerDin    <= (others => '0');
      RxTg1        := '0';
      RxTg2        := '0';
    elsif clk_uart'event and clk_uart = '1' then  -- rising clock edge
      count        <= count + 1;
      readerEnable <= '0';
      regDout      <= readerDout;
      regDvToggle  <= readerToggle;
      if count(2 downto 0) = "001" and readEnable = '1' and EndOfSource = '0' then
        readerEnable <= '1';
      end if;
      if readerEnable = '1' then
        readerToggle <= not readerToggle;
      end if;

      RxTg1        := regRxToggle;
      writerEnable <= '0';
      writerDin    <= regDin;
      if RxTg1 /= RxTg2 then
        writerEnable <= '1';
      end if;
      RxTg2 := RxTg1;
    end if;
  end process UART_BYPASS;

  EndOfSourceFile <= EndOfSource;


  u2_fileReader : entity work.BinaryFileReader
    generic map (
      FileName => SourceFile)
    port map (
      clk        => clk_uart,
      enable     => readerEnable,
      dout       => readerDout,
      dv         => readerValid,
      FileLength => SourceFileLength,
      EndOfFile  => EndOfSource);

  u3_fileWriter : entity work.BinaryFileWriter
    generic map (
      FileName => DestFile)
    port map (
      clk    => clk_uart,
      enable => writerEnable,
      din    => writerDin);

end testbench;
