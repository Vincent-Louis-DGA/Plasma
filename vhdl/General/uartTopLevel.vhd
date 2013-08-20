-------------------------------------------------------------------------------
-- Implements a UART including:
--      UART Core
--      Registers Map
--      Rx and Tx FIFOS (2048 bytes each)
--      Calculate baud rate div = (clk_uart / (PS+1) / BR)-1
--      Eg, 115200 (default rate), clk_uart = 19.3536 MHz, divider = 7, PS (prescale) = 20.
--
--      Maximum baud rate = 921,600 (PS = 20, baud div = 0)
--        Minimum baud rate =   3,600 (PS = 20, baud div = 255)
-------------------------------------------------------------------------------
-- Register Map:
--      Addr    Name                    Reset Value             Read/Write
--      0x00    TX Register             N/A                     W
--      0x01    RX Register             0                       R
--      0x02    UART Status             0                       R
--      0x03    UART Control            N/A                     W
--      0x04    Baudrate Div            7                       R/W
--      0x05    Unused                        
--      0x06    Interrupt Enable        0                       R/W
--      0x07    Interrupt Flags.        0                       R
--        0x8-F   Unused
-------------------------------------------------------------------------------
--      UART Status Bits
--      b0      TX FIFO Full
--      b1      TX FIFO Not Empty
--      b2      RX FIFO Full
--      b3      RX FIFO Not Empty (aka, RX Data Available)
--      b4      TX Busy
--      b5-7    Unused
-------------------------------------------------------------------------------
--      UART Control Bits
--      b0      TX FIFO Reset (Write '1' to clear TX FIFO)
--      b1      RX FIFO Reset (Write '1' to clear RX FIFO)
--      b2-7    Unused
-------------------------------------------------------------------------------
--      UART Interrupts (Flags and Enables have same bit positions)
--      b0      Unused
--      b1      TX FIFO Empty
--      b2      Unused
--      b3      RX Data Available
--      b4-7    Unused
-------------------------------------------------------------------------------
-- Written by A Jongenelen, 2012.
-- Utilises UART written by Steve Rhoads (rhoadss@yahoo.com)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity uartTopLevel is
  generic (
    DEFAULT_DIVIDER : std_logic_vector(7 downto 0) := X"07";
    PRESCALE_DIV    : std_logic_vector(7 downto 0) := X"14";  -- This prescale assumes 19.3536 MHz clock
    log_file        : string                       := "UNUSED"
    );  

  port (
    clk_uart : in  std_logic;  -- From a PLL. Preferably 19.3536 or some multiple of 921.6 kHZ.
    reset    : in  std_logic;
    tx       : out std_logic;           -- To pin
    rx       : in  std_logic;           -- From pin
    sys_clk  : in  std_logic;           -- CPU bus clock
    reg_addr : in  std_logic_vector(3 downto 0);
    reg_din  : in  std_logic_vector(7 downto 0);
    reg_dout : out std_logic_vector(7 downto 0);
    reg_we   : in  std_logic;
    reg_re   : in  std_logic;
    irq      : out std_logic;

    -- Use these signals to directly insert data into Rx FIFO (clk_uart domain)
    bypassRx         : in  std_logic_vector(7 downto 0);
    bypassRxWeToggle : in  std_logic;
    -- Use these signals to directly remove data written to Tx FIFO (sys_clk domain)
    bypassTx         : out std_logic_vector(7 downto 0);
    bypassTxDv       : out std_logic
    );

end uartTopLevel;

architecture logic of uartTopLevel is

  -- FIFO signals
  signal tx_fifo_reset : std_logic;
  signal tx_fifo_we    : std_logic;
  signal tx_fifo_din   : std_logic_vector(7 downto 0);
  signal rx_fifo_reset : std_logic;
  signal rx_fifo_re    : std_logic;
  signal rx_fifo_dout  : std_logic_vector(7 downto 0);
  signal rx_fifo_we    : std_logic;
  signal rx_fifo_din   : std_logic_vector(7 downto 0);

  -- UART Core signals
  signal uart_reset      : std_logic                    := '0';
  signal clk_u           : std_logic                    := '0';
  signal uart_reset_cnt  : std_logic_vector(1 downto 0) := (others => '0');
  signal uart_data_avail : std_logic;
  signal uart_we         : std_logic;
  signal uart_busy       : std_logic;
  signal uart_din        : std_logic_vector(7 downto 0);
  signal uart_dout       : std_logic_vector(7 downto 0);

  -- clock domain crossing signals
  signal rx_uc             : std_logic := '1';
  signal uart_busy_uc      : std_logic := '0';
  signal uart_busy_sc      : std_logic := '0';
  signal uart_busy_sc2     : std_logic := '0';
  signal uart_tx_not_empty : std_logic := '0';

  signal baud_divider : std_logic_vector(7 downto 0) := DEFAULT_DIVIDER;
  signal baud_div_uc  : std_logic_vector(11 downto 0);  -- uart_clk domain
  signal status_reg   : std_logic_vector(7 downto 0);
  signal int_enable   : std_logic_vector(7 downto 0);

  signal bypassRxWe  : std_logic;
  signal bypassRxTg  : std_logic;
  signal bypassRxTg2 : std_logic;
  signal bypassRxReg : std_logic_vector(7 downto 0);
  
begin  -- logic


  BIDIR_BUFFER : entity work.BiDirFifoBuffer
    port map (
      clk_cpu         => sys_clk,
      cpu_din         => tx_fifo_din,
      cpu_we          => tx_fifo_we,
      cpu_dout        => rx_fifo_dout,
      cpu_re          => rx_fifo_re,
      cpu_fifo_status => status_reg(3 downto 0),
      cpu_rx_reset    => rx_fifo_reset,
      cpu_tx_reset    => tx_fifo_reset,
      clk_io          => clk_u,
      io_tx_we        => uart_we,
      io_tx_din       => uart_din,
      io_tx_busy      => uart_busy,
      io_rx_dv        => rx_fifo_we,
      io_rx_dout      => rx_fifo_din);

  status_reg(4)          <= uart_busy_sc2 or uart_tx_not_empty;
  status_reg(7 downto 5) <= (others => '0');
  uart_reset             <= '0' when uart_reset_cnt = "11" else '1';

  rx_fifo_we  <= uart_data_avail or bypassRxWe;
  rx_fifo_din <= bypassRxReg when bypassRxWe = '1' else uart_dout;

  bypassTx   <= tx_fifo_din;
  bypassTxDv <= tx_fifo_we;

  CPU_REGISTERS : process (sys_clk, reset)
  begin  -- process CPU_REGISTERS
    if reset = '1' then                 -- asynchronous reset (active high)
      baud_divider      <= DEFAULT_DIVIDER;
      tx_fifo_we        <= '0';
      tx_fifo_din       <= (others => '0');
      int_enable        <= (others => '0');
      irq               <= '0';
      tx_fifo_reset     <= '1';
      rx_fifo_reset     <= '1';
      uart_busy_sc      <= '0';
      uart_busy_sc2     <= '0';
      uart_tx_not_empty <= '0';
      uart_reset_cnt    <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      uart_busy_sc      <= uart_busy_uc;
      uart_busy_sc2     <= uart_busy_sc;
      uart_tx_not_empty <= status_reg(1);
      tx_fifo_we        <= '0';
      tx_fifo_reset     <= '0';
      rx_fifo_reset     <= '0';
      if reg_we = '1' then
        case reg_addr is
          when X"0" =>
            tx_fifo_we  <= '1';
            tx_fifo_din <= reg_din;
          when X"3" =>
            tx_fifo_reset <= reg_din(0);
            rx_fifo_reset <= reg_din(1);
          when X"4" =>
            baud_divider   <= reg_din;
            uart_reset_cnt <= (others => '0');
          when X"6" =>
            int_enable <= reg_din;
          when others => null;
        end case;
      end if;
      if uart_reset_cnt /= "11" then
        uart_reset_cnt <= uart_reset_cnt + 1;
      end if;
    end if;
  end process CPU_REGISTERS;

  rx_fifo_re <= reg_re when reg_addr = "001" else '0';

  SET_CPU_DOUT : process (reg_addr, rx_fifo_dout, status_reg, baud_divider)
  begin  -- process SET_CPU_DOUT
    case reg_addr is
      when X"1"   => reg_dout <= rx_fifo_dout;
      when X"2"   => reg_dout <= status_reg;
      when X"4"   => reg_dout <= baud_divider;
      when others => reg_dout <= (others => '0');
    end case;
  end process SET_CPU_DOUT;

  REG_INPUTS : process (clk_u, reset)
  begin  -- process REG_INPUTS
    if reset = '1' then
      baud_div_uc  <= X"0" & DEFAULT_DIVIDER;
      rx_uc        <= '1';
      uart_busy_uc <= '0';
      bypassRxWe   <= '0';
      bypassRxTg   <= '0';
      bypassRxReg  <= (others => '0');
    elsif rising_edge(clk_u) then
      bypassRxTg  <= bypassRxWeToggle;
      bypassRxTg2 <= bypassRxTg;
      bypassRxWe  <= '0';
      if bypassRxTg /= bypassRxTg2 then
        bypassRxWe <= '1';
      end if;
      bypassRxReg  <= bypassRx;
      baud_div_uc  <= X"0" & baud_divider;
      rx_uc        <= rx;
      uart_busy_uc <= uart_busy;
    end if;
  end process REG_INPUTS;


  UART_CORE : entity work.uart
    generic map (
      PRESCALE_DIV => PRESCALE_DIV)
    port map (
      clk          => clk_u,
      reset        => uart_reset,
      enable_write => uart_we,
      data_in      => uart_din,
      data_out     => uart_dout,
      uartRx       => rx_uc,
      uartTx       => tx,
      busy_write   => uart_busy,
      data_avail   => uart_data_avail,
      baud_div     => baud_div_uc);

  PS_GEN : if log_file = "UNUSED" generate

    clk_u <= clk_uart;

  end generate PS_GEN;

  PS_LOG : if log_file /= "UNUSED" generate

    clk_u <= sys_clk;

    log_proc : process(sys_clk)
      file store_file        : text open write_mode is log_file;
      variable console_line  : line;
      variable hex_file_line : line;
      variable c             : character;
      variable index         : natural;
      variable line_length   : natural := 0;
    begin
      if rising_edge(sys_clk) then
        if tx_fifo_we = '1' then
          index := conv_integer(tx_fifo_din);
          if index /= 10 and index /= 13 then
            c           := character'val(index);
            write(hex_file_line, c);
            write(console_line, c);
            line_length := line_length + 1;
          end if;
          if index = 10 or line_length >= 72 then
            --The following line had to be commented out for synthesis
            writeline(output, console_line);
            writeline(store_file, hex_file_line);
            line_length := 0;
          end if;
        end if;  -- tx_fifo_we
      end if;  --rising_edge(clk)
    end process;  --log_proc
  end generate PS_LOG;



  
end logic;
