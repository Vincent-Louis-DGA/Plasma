---------------------------------------------------------------------
-- TITLE: UART
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 5/29/02
-- FILENAME: uart.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the UART.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all;
--use std.textio.all;
--use work.mlite_pack.all;

entity uart is
  generic(PRESCALE_DIV : std_logic_vector(7 downto 0) := X"14");
  port(clk          : in  std_logic;
       reset        : in  std_logic;
       enable_write : in  std_logic;
       data_in      : in  std_logic_vector(7 downto 0);
       data_out     : out std_logic_vector(7 downto 0) := (others => '0');
       uartRX       : in  std_logic;
       uartTX       : out std_logic                    := '1';
       busy_write   : out std_logic                    := '0';
       data_avail   : out std_logic                    := '0';
       baud_div     : in  std_logic_vector(11 downto 0));
end;  --entity uart

architecture logic of uart is

  constant ZERO     : std_logic_vector(15 downto 0) := (others => '0');
  constant ONES     : std_logic_vector(15 downto 0) := (others => '1');
  constant NUM_BITS : std_logic_vector(3 downto 0)  := X"A";

                                        -- default prescale converts 19.3536 MHz input clock to a 921.6 kHz pulse.
  signal prescale_count : std_logic_vector(7 downto 0) := (others => '0');
  signal ps_enable      : std_logic                    := '0';

  signal rx_prescale_count : std_logic_vector(7 downto 0) := (others => '0');
  signal rx_ps_enable      : std_logic                    := '0';
  signal rx_in_progress    : std_logic                    := '0';

  signal delay_write_reg : std_logic_vector(11 downto 0) := (others => '0');
  signal bits_write_reg  : std_logic_vector(3 downto 0)  := (others => '0');
  signal data_write_reg  : std_logic_vector(8 downto 0)  := (others => '1');
  signal delay_read_reg  : std_logic_vector(11 downto 0) := (others => '0');
  signal bits_read_reg   : std_logic_vector(3 downto 0)  := (others => '0');
  signal data_read_reg   : std_logic_vector(7 downto 0)  := (others => '1');
  signal busy_write_sig  : std_logic                     := '0';
  signal uart_rx_reg     : std_logic                     := '1';
  signal uartRX2         : std_logic                     := '1';
  signal rx_start_delay  : std_logic_vector(2 downto 0);

begin

  u1_rx_in : entity work.InputPort
    generic map (W => 1, D => 4, RESET_VAL => '1')
    port map (clk  => clk, reset => reset, port_i(0) => uartRX, reg_i(0) => uartRX2);

  PRE_SCALE : process (clk, reset)
  begin  -- process PRE_SCALE
    if reset = '1' then                 -- asynchronous reset (active high)
      prescale_count    <= (others => '0');
      ps_enable         <= '0';
      rx_prescale_count <= (others => '0');
      rx_ps_enable      <= '0';
    elsif rising_edge(clk) then         -- rising clock edge

      -- count off prescale
      if prescale_count = PRESCALE_DIV then
        prescale_count <= (others => '0');
        ps_enable      <= '1';
      else
        ps_enable      <= '0';
        prescale_count <= prescale_count + 1;
      end if;

      -- count off rx_prescale at faster rate while waiting for rx.
      if rx_start_delay(2) = '0' and rx_prescale_count = PRESCALE_DIV then
        rx_prescale_count <= (others => '0');
        rx_ps_enable      <= '1';
      elsif rx_start_delay(2) = '1' and rx_prescale_count >= ("000" & PRESCALE_DIV(7 downto 3)) then
        rx_prescale_count <= (others => '0');
        rx_ps_enable      <= '1';
      else
        rx_prescale_count <= rx_prescale_count + 1;
        rx_ps_enable      <= '0';
      end if;
      
    end if;
  end process PRE_SCALE;

  UART_WRITE_PROC : process (clk, reset)
  begin  -- process UART_WRITE_PROC
    if reset = '1' then                 -- asynchronous reset (active high)
      data_write_reg  <= (others => '1');
      bits_write_reg  <= "0000";
      delay_write_reg <= (others => '0');
      uartTX          <= '1';
    elsif rising_edge(clk) then         -- rising clock edge
      if bits_write_reg = "0000" then   --nothing left to write?
        if enable_write = '1' then
          delay_write_reg <= (others => '0');      --delay before next bit
          bits_write_reg  <= NUM_BITS;  --number of bits to write
          data_write_reg  <= data_in & "0";        --remember data & start bit
        end if;
      elsif ps_enable = '1' then
        uartTX <= data_write_reg(0);
        if delay_write_reg /= baud_div then
          delay_write_reg <= delay_write_reg + 1;  --delay before next bit
        else
          delay_write_reg <= (others => '0');      --reset delay
          bits_write_reg  <= bits_write_reg - 1;   --bits left to write
          data_write_reg  <= '1' & data_write_reg(8 downto 1);
        end if;
      end if;
    end if;
  end process UART_WRITE_PROC;

  busy_write_sig <= '1' when (bits_write_reg /= "0000") else '0';
  busy_write     <= busy_write_sig;

  UART_READ_PROC : process(clk, reset)
  begin

    if reset = '1' then
      data_read_reg  <= (others => '1');
      bits_read_reg  <= "0000";
      delay_read_reg <= (others => '0');
      data_out       <= (others => '0');
      rx_start_delay <= (others => '1');
    elsif rising_edge(clk) then

      data_avail <= '0';
      --Read UART
      if bits_read_reg = "0000" then
        rx_start_delay <= rx_start_delay(1 downto 0) & '1';
      else
        rx_start_delay <= rx_start_delay(1 downto 0) & '0';
      end if;

      if rx_ps_enable = '1' then
        
        if bits_read_reg = "0000" and uartRX2 = '0' then
          bits_read_reg  <= NUM_BITS;
          delay_read_reg <= (others => '0');
        elsif bits_read_reg /= "0000" then
          -- Sample period half as long on for start bit, to align sampling at mid-point between edges.
          if bits_read_reg = NUM_BITS and delay_read_reg = ('0' & baud_div(baud_div'left downto 1)) then
            delay_read_reg <= (others => '0');
            bits_read_reg  <= bits_read_reg -1;
            data_read_reg  <= uartRX2 & data_read_reg(7 downto 1);
          elsif delay_read_reg = baud_div then
            delay_read_reg <= (others => '0');
            bits_read_reg  <= bits_read_reg -1;
            data_read_reg  <= uartRX2 & data_read_reg(7 downto 1);
          else
            delay_read_reg <= delay_read_reg + 1;
          end if;
        end if;

        if bits_read_reg = "0001" and delay_read_reg = X"00" then
          data_avail <= '1';
          data_out   <= data_read_reg(7 downto 0);
        end if;

      end if;  -- ps_enable
    end if;  --rising_edge(clk)

    
  end process;  --UART_READ_PROC




end;  --architecture logic
