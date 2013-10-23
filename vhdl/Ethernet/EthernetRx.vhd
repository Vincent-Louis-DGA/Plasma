library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity EthernetRx is
  
  port (
    clk_50  : in std_logic;
    reset_n : in std_logic;

    ethernetRXDV  : in std_logic                    := '0';
    ethernetRXCLK : in std_logic                    := '0';
    ethernetRXER  : in std_logic                    := '0';
    ethernetRXD   : in std_logic_vector(7 downto 0) := (others => '0');

    etherDin  : in  std_logic_vector(31 downto 0) := (others => '0');
    etherRxDout : out std_logic_vector(31 downto 0);
    etherAddr : in  std_logic_vector(15 downto 0);
    etherRe   : in  std_logic;
    etherWbe  : in  std_logic_vector(3 downto 0)
    );

end EthernetRx;

architecture rtl of EthernetRx is

begin  -- rtl

  

end rtl;
