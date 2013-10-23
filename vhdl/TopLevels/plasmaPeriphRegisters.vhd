-------------------------------------------------------------------------------
-- Plasma Peripheral Registers.
-- These should match the 32-bit (8 hex digit) address in the C code.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package plasmaPeriphRegisters is

  constant IN_RAM_OFFSET : std_logic_vector(31 downto 29) := "000";
  constant EX_RAM_OFFSET : std_logic_vector(31 downto 29) := "010";
  constant PERIPH_OFFSET : std_logic_vector(31 downto 29) := "001";
  
  constant INTERRUPT_VECTOR : std_logic_vector(31 downto 0) := X"00000080";
  
  constant UART_OFFSET : std_logic_vector(31 downto 6) := X"200000" & "00";
  constant ETHERNET_OFFSET : std_logic_vector(31 downto 16) := X"2001";

  constant IRQ_STATUS_ADDR     : std_logic_vector(31 downto 0) := X"20000040";
  constant IRQ_STATUS_CLR_ADDR : std_logic_vector(31 downto 0) := X"20000044";
  constant IRQ_VECTOR_ADDR     : std_logic_vector(31 downto 0) := X"2000004C";
  constant IRQ_MASK_ADDR       : std_logic_vector(31 downto 0) := X"20000050";
  constant IRQ_MASK_SET_ADDR   : std_logic_vector(31 downto 0) := X"20000054";
  constant IRQ_MASK_CLR_ADDR   : std_logic_vector(31 downto 0) := X"20000058";
  constant LEDS_OFFSET         : std_logic_vector(31 downto 4) := X"2000006";
  constant SWITCHES_ADDR       : std_logic_vector(31 downto 0) := X"20000070";
  constant BUTTONS_ADDR        : std_logic_vector(31 downto 0) := X"20000074";
  constant RAND_ADDR           : std_logic_vector(31 downto 0) := X"20000078";

  constant PMOD_OFFSET : std_logic_vector(31 downto 5) := X"200000" & "100";

  constant COUNTER1_ADDR    : std_logic_vector(31 downto 0) := X"200000A0";
  constant COUNTER1_PS_ADDR : std_logic_vector(31 downto 0) := X"200000A4";
  constant COUNTER1_TC_ADDR : std_logic_vector(31 downto 0) := X"200000A8";

  constant CACHE_HITCOUNT_ADDR  : std_logic_vector(31 downto 0) := X"200000B0";
  constant CACHE_READCOUNT_ADDR : std_logic_vector(31 downto 0) := X"200000B4";

  constant FLASH_CON_ADDR  : std_logic_vector(31 downto 0) := X"200000C0";
  constant FLASH_DATA_ADDR : std_logic_vector(31 downto 0) := X"200000C4";
  constant FLASH_TRIS_ADDR : std_logic_vector(31 downto 0) := X"200000C8";

  constant FIFO_DIN_ADDR  : std_logic_vector(31 downto 0) := X"200000D0";
  constant FIFO_DOUT_ADDR : std_logic_vector(31 downto 0) := X"200000D4";
  constant FIFO_CON_ADDR  : std_logic_vector(31 downto 0) := X"200000D8";

  constant LOGIC_AN_CON_ADDR : std_logic_vector(31 downto 0)  := X"21000000";
  constant LOGIC_AN_OFFSET   : std_logic_vector(31 downto 16) := X"2200";

  constant EX_BUS_OFFSET : std_logic_vector(31 downto 28) := X"3";


  constant ZEROS32 : std_logic_vector(31 downto 0) := (others => '0');
  constant ONES32  : std_logic_vector(31 downto 0) := (others => '1');

  constant EX_RAM_ADDR_WIDTH  : integer := 13;  -- 8192 words = 32 kB
  constant DDR_RAM_ADDR_WIDTH : integer := 27;  -- 1 Gbit = 128 MB

end plasmaPeriphRegisters;

package body plasmaPeriphRegisters is


end plasmaPeriphRegisters;
