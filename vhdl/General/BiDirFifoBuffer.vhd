-------------------------------------------------------------------------------
-- A general purpose Bidirectional FIFO buffering system.
-- Use with receivers/transmitters that take some time to complete, eg, UART
-- Do not read (cpu_re = '1') or write (cpu_we = '1') with sustained bursts.
--
-- Port names reflect the clock domain they are in.
--
-- Writes from either end (CPU or IO_RX) when respective FIFO is full will
-- drop those bytes without error. If this is a problem, be sure to check the
-- fifo status more often.
--
-- Buffers are 2048 bytes long.
-------------------------------------------------------------------------------
-- Adrian Jongenelen, 2012.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity BidirFifoBuffer is
  
  port (
    clk_cpu         : in  std_logic;    -- CPU side clock
    cpu_din         : in  std_logic_vector(7 downto 0);
    cpu_we          : in  std_logic;    -- write enable
    cpu_dout        : out std_logic_vector(7 downto 0);
    cpu_re          : in  std_logic;    -- read enable
    cpu_fifo_status : out std_logic_vector(3 downto 0);
    cpu_rx_reset    : in  std_logic;    -- Resets (clears) RX FIFO
    cpu_tx_reset    : in  std_logic;    -- Resets (clears) TX FIFO
    -- fifo_status <= TX_FULL & not TX_EMPTY & RX_FULL & not RX_EMPTY
    clk_io          : in  std_logic;    -- IO side clock
    io_tx_we        : out std_logic;    -- IO write enable
    io_tx_din       : out std_logic_vector(7 downto 0);  -- input to IO
    io_tx_busy      : in  std_logic;
    io_rx_dv        : in  std_logic;    -- IO receiver data available
    io_rx_dout      : in  std_logic_vector(7 downto 0)
    );
end BidirFifoBuffer;

architecture logic of BidirFifoBuffer is

  signal tx_fifo_we : std_logic := '0';
  signal rx_fifo_we : std_logic := '0';
  signal tx_fifo_re : std_logic := '0';
  signal rx_fifo_re : std_logic := '0';
  signal tx_fifo_re2 : std_logic := '0';

  signal tx_fifo_empty_cc2 : std_logic := '1';
  signal tx_fifo_empty_cc : std_logic := '1';
  signal tx_fifo_empty_ic : std_logic := '1';
  signal tx_fifo_empty    : std_logic := '1';
  signal tx_fifo_full     : std_logic := '0';
  signal rx_fifo_full_cc2  : std_logic := '0';
  signal rx_fifo_full_cc  : std_logic := '0';
  signal rx_fifo_full_ic  : std_logic := '0';
  signal rx_fifo_full     : std_logic := '0';
  signal rx_fifo_empty    : std_logic := '1';
  
  
  
begin  -- logic

  tx_fifo_we <= cpu_we and not tx_fifo_full;
  rx_fifo_we <= io_rx_dv and not rx_fifo_full;

  cpu_fifo_status(0) <= tx_fifo_full;
  cpu_fifo_status(1) <= not tx_fifo_empty_cc2;
  cpu_fifo_status(2) <= rx_fifo_full_cc2;
  cpu_fifo_status(3) <= not rx_fifo_empty;

  REG_CLK_CPU : process (clk_cpu)
  begin  -- process REG_CLK_CPU
    if rising_edge(clk_cpu) then
      tx_fifo_empty_cc <= tx_fifo_empty_ic;
      rx_fifo_full_cc  <= rx_fifo_full_ic;
		rx_fifo_full_cc2 <= rx_fifo_full_cc;
		tx_fifo_empty_cc2 <= tx_fifo_empty_cc;
    end if;
  end process REG_CLK_CPU;

  REG_CLK_IO : process (clk_io)
  begin  -- process REG_CLK_IO
    if rising_edge(clk_io) then         -- rising clock edge
		tx_fifo_re2 <= tx_fifo_re;
		io_tx_we <= tx_fifo_re and not tx_fifo_re2;
		rx_fifo_full_ic <= rx_fifo_full;
		tx_fifo_empty_ic <= tx_fifo_empty;
    end if;
  end process REG_CLK_IO;
  
      tx_fifo_re <= not tx_fifo_empty and not io_tx_busy and not tx_fifo_re2;

  TX_FIFO : entity work.fifo2048x8
    port map (
      rst    => cpu_tx_reset,
      wr_clk => clk_cpu,
      rd_clk => clk_io,
      din    => cpu_din,
      wr_en  => tx_fifo_we,
      rd_en  => tx_fifo_re,
      dout   => io_tx_din,
      full   => tx_fifo_full,
      empty  => tx_fifo_empty);

  RX_FIFO : entity work.fifo2048x8
    port map (
      rst    => cpu_rx_reset,
      wr_clk => clk_io,
      rd_clk => clk_cpu,
      din    => io_rx_dout,
      wr_en  => rx_fifo_we,
      rd_en  => cpu_re,
      dout   => cpu_dout,
      full   => rx_fifo_full,
      empty  => rx_fifo_empty);

end logic;
