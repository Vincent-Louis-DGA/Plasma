-------------------------------------------------------------------------------
-- Reads a file and encodes it onto a UART Tx line.
-- Listens to the Uart RX line and writes to a different file.
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
    regWriteEnable   : in  std_logic;
    regDout          : out std_logic_vector(7 downto 0);
    regDvToggle      : out std_logic;
    uartTx           : out std_logic;
    uartRx           : in  std_logic;
    SourceFileLength : out std_logic_vector(31 downto 0);
    EndOfSourceFile  : out std_logic
    );

end UartFileReader;

architecture testbench of UartFileReader is

  signal reset : std_logic;

  signal reg_din  : std_logic_vector(7 downto 0);
  signal reg_dout : std_logic_vector(7 downto 0);
  signal reg_addr : std_logic_vector(3 downto 0);
  signal reg_we   : std_logic := '0';
  signal reg_we2  : std_logic := '0';
  signal reg_re   : std_logic := '0';

  signal readerEnable    : std_logic := '0';
  signal readerEnable2   : std_logic := '0';
  signal readerValid     : std_logic := '0';
  signal regWriteEnable2 : std_logic := '0';

  signal readerDout    : std_logic_vector(7 downto 0);
  signal writerEnable  : std_logic := '0';
  signal writerEnable2 : std_logic := '0';
  signal writerEnable3 : std_logic;
  signal writerDin     : std_logic_vector(7 downto 0);
  signal writerDin2    : std_logic_vector(7 downto 0);

  type   UART_CONTROL_STATE is (Rest, Read_Status, Read_Status2, Read_Rx, Read_Rx2, Read_Rx3, Write_Tx, Write_Tx2, Write_Tx3, Pause);
  signal currentState : UART_CONTROL_STATE := Rest;
  signal uartStatus   : std_logic_vector(7 downto 0);
  signal stateCount   : std_logic_vector(7 downto 0);

  signal bypassRx         : std_logic_vector(7 downto 0);
  signal bypassRxWeToggle : std_logic;
  signal bypassTx         : std_logic_vector(7 downto 0);
  signal bypassTxDv       : std_logic;
  signal regDvToggle2     : std_logic;


begin  -- testbench


  CYCLE_STATES : process (clk_uart, reset_n)
  begin  -- process CYCLE_STATES
    if reset_n = '0' then               -- asynchronous reset (active high)
      currentState <= Rest;
      stateCount   <= (others => '0');
    elsif rising_edge(clk_uart) then    -- rising clock edge
      if currentState = Pause then
        stateCount <= stateCount + 1;
      else
        stateCount <= (others => '0');
      end if;
      case currentState is
        when Rest         => currentState <= Read_Status;
        when Read_Status  => currentState <= Read_Status2;
        when Read_Status2 => currentState <= Read_Rx;
        when Read_Rx      => currentState <= Read_Rx2;
        when Read_Rx2     => currentState <= Read_Rx3;
        when Read_Rx3     => currentState <= Write_Tx;
        when Write_Tx     => currentState <= Write_Tx2;
        when Write_Tx2    => currentState <= Write_Tx3;
        when Write_Tx3    => currentState <= Pause;
        when Pause        =>
          if stateCount = X"17" then
            currentState <= Read_Status;
          end if;
        when others => currentState <= Rest;
      end case;
    end if;
  end process CYCLE_STATES;

  DO_ALL : process (clk_uart, reset_n)
  begin  -- process DO_ALL
    if reset_n = '0' then               -- asynchronous reset (active high)
      reg_din         <= (others => '0');
      reg_addr        <= (others => '0');
      reg_re          <= '0';
      reg_we          <= '0';
      readerEnable    <= '0';
      writerEnable    <= '0';
      writerDin       <= (others => '0');
      uartStatus      <= (others => '0');
      regWriteEnable2 <= '0';
      regDvToggle2    <= '0';
      regDout         <= (others => '0');
      regDvToggle     <= '0';
    elsif rising_edge(clk_uart) then    -- rising clock edge
      reg_re          <= '0';
      reg_we          <= '0';
      readerEnable    <= '0';
      writerEnable    <= '0';
      writerEnable2   <= writerEnable;
      regWriteEnable2 <= '0';
      regDvToggle     <= regDvToggle2;
      case currentState is
        when Read_Status =>
          reg_addr <= X"2";
          reg_re   <= '1';
        when Read_status2 =>
          uartStatus <= reg_dout;
        when Read_Rx =>
          if uartStatus(3) = '1' then
            reg_addr <= X"1";
            reg_re   <= '1';
          end if;
        when Read_Rx2 =>
          if reg_re = '1' then
            writerDin    <= reg_dout;
            writerEnable <= '1';
          end if;
        when Read_Rx3 =>
          if writerEnable = '1' then
            writerDin <= reg_dout;
          end if;
        when Write_Tx =>
          if uartStatus(0) = '0' then
            if regWriteEnable = '1' then
              regWriteEnable2 <= '1';
            elsif readEnable = '1' then
              readerEnable <= '1';
            end if;
          end if;
        when Write_Tx2 =>
          if regWriteEnable2 = '1' then
            reg_din      <= regDin;
            reg_addr     <= X"0";
            reg_we       <= '1';
            regDout      <= regDin;
            regDvToggle2 <= not regDvToggle2;
          end if;
        when Write_Tx3 =>
          if readerValid = '1' then
            reg_din      <= readerDout;
            reg_addr     <= X"0";
            reg_we       <= '1';
            regDout      <= readerDout;
            regDvToggle2 <= not regDvToggle2;
          end if;
        when others => null;
      end case;
    end if;
  end process DO_ALL;

  reg_we2 <= reg_we and SIM_UART;
  reset   <= not reset_n;

  u1_uart : entity work.uartTopLevel
    generic map (
      DEFAULT_DIVIDER => X"00",
      PRESCALE_DIV    => X"10")
    port map (
      clk_uart         => clk_uart,
      reset            => reset,
      tx               => uartTx,
      rx               => uartRx,
      sys_clk          => clk_uart,
      reg_addr         => reg_addr,
      reg_din          => reg_din,
      reg_dout         => reg_dout,
      reg_we           => reg_we2,
      reg_re           => reg_re,
      bypassRx         => bypassRx,
      bypassRxWeToggle => bypassRxWeToggle,
      bypassTx         => bypassTx,
      bypassTxDv       => bypassTxDv);

  u2_fileReader : entity work.BinaryFileReader
    generic map (
      FileName => SourceFile)
    port map (
      clk        => clk_uart,
      enable     => readerEnable,
      dout       => readerDout,
      dv         => readerValid,
      FileLength => SourceFileLength,
      EndOfFile  => EndOfSourceFile);

  writerEnable3 <= bypassTxDv;
  writerDin2    <= bypassTx;

  u3_fileWriter : entity work.BinaryFileWriter
    generic map (
      FileName => DestFile)
    port map (
      clk    => clk_uart,
      enable => writerEnable3,
      din    => writerDin2);

end testbench;
