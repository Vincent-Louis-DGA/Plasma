-- Register map for Ethernet submodule.
library ieee;
use ieee.std_logic_1164.all;

package EthernetRegisters is

  constant ETHER_CON_OFFSET : std_logic_vector(15 downto 12) := X"0";

  constant MDIO_WRITE_ADDR    : std_logic_vector(15 downto 0) := X"0000";
  constant MDIO_READADDR_ADDR : std_logic_vector(15 downto 0) := X"0004";
  constant MDIO_READ_ADDR     : std_logic_vector(15 downto 0) := X"0008";
  constant STATUS_ADDR        : std_logic_vector(15 downto 0) := X"000C";
  constant TX_PRD             : std_logic_vector(15 downto 0) := X"0010";
  constant RX_PRD             : std_logic_vector(15 downto 0) := X"0014";

  constant DEFAULT_ETHER_MAC : std_logic_vector(47 downto 0) := X"020A35445441";
  constant ETHER_MAC_HIGH    : std_logic_vector(15 downto 0) := X"0024";
  constant ETHER_MAC_MID     : std_logic_vector(15 downto 0) := X"0028";
  constant ETHER_MAC_LOW     : std_logic_vector(15 downto 0) := X"002C";

  constant ETHER_TXBUF_OFFSET : std_logic_vector(15 downto 12) := X"2";

  constant ETHER_TXCON_OFFSET : std_logic_vector(15 downto 12) := X"3";
  constant TX_CONTROL         : std_logic_vector(15 downto 0)  := X"3000";
  constant TX_PACKET_LENGTH   : std_logic_vector(15 downto 0)  := X"3020";
  constant TX_DEST_MAC_HIGH   : std_logic_vector(15 downto 0)  := X"3024";
  constant TX_DEST_MAC_MID    : std_logic_vector(15 downto 0)  := X"3028";
  constant TX_DEST_MAC_LOW    : std_logic_vector(15 downto 0)  := X"302C";
  constant TX_ETHERTYPE       : std_logic_vector(15 downto 0)  := X"3030";

  constant ETHER_RXBUF_OFFSET : std_logic_vector(15 downto 12) := X"4";

  constant ETHER_RXCON_OFFSET : std_logic_vector(15 downto 12) := X"5";
  constant RX_CONTROL         : std_logic_vector(15 downto 0)  := X"5000";

  constant RX_PACKET_LENGTH0 : std_logic_vector(15 downto 0) := X"5020";
  constant RX_DEST_MAC0_HIGH : std_logic_vector(15 downto 0) := X"5024";
  constant RX_DEST_MAC0_MID  : std_logic_vector(15 downto 0) := X"5028";
  constant RX_DEST_MAC0_LOW  : std_logic_vector(15 downto 0) := X"502C";
  constant RX_ETHERTYPE0     : std_logic_vector(15 downto 0) := X"5030";
  constant RX_SRC_MAC0_HIGH  : std_logic_vector(15 downto 0) := X"5034";
  constant RX_SRC_MAC0_MID   : std_logic_vector(15 downto 0) := X"5038";
  constant RX_SRC_MAC0_LOW   : std_logic_vector(15 downto 0) := X"503C";
  constant RX_CRC0_ACTUAL    : std_logic_vector(15 downto 0) := X"5040";
  constant RX_CRC0_EXPECTED  : std_logic_vector(15 downto 0) := X"5044";

  constant RX_PACKET_LENGTH1 : std_logic_vector(15 downto 0) := X"5820";
  constant RX_DEST_MAC1_HIGH : std_logic_vector(15 downto 0) := X"5824";
  constant RX_DEST_MAC1_MID  : std_logic_vector(15 downto 0) := X"5828";
  constant RX_DEST_MAC1_LOW  : std_logic_vector(15 downto 0) := X"582C";
  constant RX_ETHERTYPE1     : std_logic_vector(15 downto 0) := X"5830";
  constant RX_SRC_MAC1_HIGH  : std_logic_vector(15 downto 0) := X"5834";
  constant RX_SRC_MAC1_MID   : std_logic_vector(15 downto 0) := X"5838";
  constant RX_SRC_MAC1_LOW   : std_logic_vector(15 downto 0) := X"583C";
  constant RX_CRC1_ACTUAL    : std_logic_vector(15 downto 0) := X"5840";
  constant RX_CRC1_EXPECTED  : std_logic_vector(15 downto 0) := X"5844";

end EthernetRegisters;

package body EthernetRegisters is



end EthernetRegisters;
