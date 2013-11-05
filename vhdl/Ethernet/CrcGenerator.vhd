-------------------------------------------------------------------------------
-- crcGenerator.vhd
--
-- Author(s):     Jorgen Peddersen
-- Created:       19 Jan 2001
-- Last Modified: 26 Jan 2001
-- 
-- Calculates the CRC check for incoming and outgoing bytes of the ethernet 
-- frame.  Uses CRC-32 to generate the check.  The frame must be passed into
-- the CRC generator with 4 bytes of h00 at the end for a valid CRC.
-- Assert sReset before every frame.  Assert en for each byte in the
-- frame, with the byte at din.  Only positive edges of en are 
-- detected.  dv indicates when a new byte can be received.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity CrcGenerator is
  port (
    clk      : in  std_logic;           -- Input clock
    reset_n     : in  std_logic;           -- Asynchronous active low reset
    sReset : in  std_logic;           -- Assert to restart calculations
    en  : in  std_logic;  -- Assert to indicate a dv input byte
    din   : in  std_logic_vector (7 downto 0);  -- Input byte
    dv : out std_logic;           -- Indicates dv CRC.  Active HIGH
    dout : out std_logic_vector (31 downto 0)  -- CRC output
    );
end CrcGenerator;

architecture crcGenerator_arch of CrcGenerator is

  signal   presState : std_logic;       -- current state
  constant stIdle    : std_logic := '0';
  constant stCalc    : std_logic := '1';

  signal bitCnt       : integer range 0 to 7;  -- counts bit in stCalc
  signal byteCnt      : integer range 0 to 4;  -- counts the four initial bytes
  signal doutInt  : std_logic_vector (31 downto 0);  -- stores current crc
  signal latchedByte  : std_logic_vector (7 downto 0);   -- latches input byte
  signal reversedByte : std_logic_vector (7 downto 0);   -- bit reverseddin
  signal lastNewByte  : std_logic;      -- previous value of en

-- Generator polynomial is
--  32   26   23   22   16   12   11   10   8   7   5   4   2   
-- x  + x  + x  + x  + x  + x  + x  + x  + x + x + x + x + x + x + 1
  constant GENERATOR : std_logic_vector := X"04C11DB7";

begin
  process(doutInt)
    -- Output is the inverted bit reversal of the internal signal
  begin
    for i in 0 to 31 loop               -- invert and bit reverse
      dout(i) <= not doutInt(31-i);
    end loop;
  end process;

  process (din)
    -- Bit reversed version of din
  begin
    for i in 0 to 7 loop                -- bit reverse
      reversedByte(i) <= din(7 - i);
    end loop;
  end process;

  process (clk, reset_n)
    -- FSM
  begin
    if reset_n = '0' then                  -- reset signals to strting values
      presState   <= stIdle;
      bitCnt      <= 0;
      byteCnt     <= 0;
      doutInt <= (others => '0');
      lastNewByte <= '0';
    elsif clk'event and clk = '1' then  -- operate on positive edge
      lastNewByte <= en;           -- remember previous value
      case presState is
        when stIdle =>
          bitCnt   <= 0;
          dv <= '1';
          if sReset = '1' then  -- reset crcGenerator to starting values
            presState   <= stIdle;
            byteCnt     <= 0;
            doutInt <= (others => '0');
            dv    <= '0';
          elsif en = '1' then-- and lastNewByte = '0' then  -- positive edge
            if byteCnt /= 4 then        -- shift in inverted byte
              presState   <= stIdle;
              doutInt <= doutInt(23 downto 0) & not reversedByte;
              byteCnt     <= byteCnt + 1;
              dv    <= '0';
            else        -- go to calculation state after fourth byte
              presState   <= stCalc;
              latchedByte <= din;    -- latch din
              dv    <= '0';
            end if;
          end if;
        when stCalc =>  -- shift in byte in little-endian and XOR if necessary
          dv <= '0';
          if sReset = '1' then  -- reset crcGenerator to starting values
            presState   <= stIdle;
            doutInt <= (others => '0');
            dv    <= '0';
            bitCnt      <= 0;
          else                          -- shift in current bit, LSB first.
            if doutInt(31) = '1' then  -- XOR with generator if MSB is '1'
              doutInt <= (doutInt(30 downto 0) & latchedByte(bitCnt)) xor GENERATOR;
            else
              doutInt <= (doutInt(30 downto 0) & latchedByte(bitCnt));
            end if;
            if bitCnt = 7 then          -- stop after all bits are shifted in
              presState <= stIdle;
              dv  <= '1';
              bitCnt    <= 0;
            else                        -- move to next bit
              presState <= stCalc;
              dv  <= '0';
              bitCnt    <= bitCnt + 1;
            end if;
          end if;
        when others =>
          presState <= stIdle;
          dv  <= '0';
          bitCnt    <= 0;
      end case;
    end if;
  end process;
end crcGenerator_arch;
