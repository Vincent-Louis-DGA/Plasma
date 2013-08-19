--
--      Package File Template
--
--      Purpose: This package defines supplemental types, subtypes, 
--               constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package GeneralPurposeFunctions is

  constant ZEROS : std_logic_vector(127 downto 0) := (others => '0');
  constant ONES  : std_logic_vector(127 downto 0) := (others => '1');
  constant ZEES  : std_logic_vector(127 downto 0) := (others => 'Z');


  procedure RisingEdgeDetect (
    signal clk      : in  std_logic;
    signal inSig    : in  std_logic;
    signal outPulse : out std_logic);

end GeneralPurposeFunctions;

package body GeneralPurposeFunctions is

  procedure RisingEdgeDetect (
    signal clk      : in  std_logic;
    signal inSig    : in  std_logic;
    signal outPulse : out std_logic) is
    variable sig2 : std_logic;
    variable sig3 : std_logic;
  begin  -- EdgeDetect
    if rising_edge(clk) then
      sig3 := sig2;
      if sig2 = '1' and sig3 = '0' then
        outPulse <= '1';
      else
        outPulse <= '0';
      end if;
      sig2 := inSig;
    end if;
  end RisingEdgeDetect;



end GeneralPurposeFunctions;
