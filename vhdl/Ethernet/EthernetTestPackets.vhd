library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.EthernetRegisters.all;

package EthernetTestPackets is

  type Vector8 is array (natural range <>) of std_logic_vector(7 downto 0);

  signal ShortPacket : Vector8(0 to 5) := (X"6F", X"70", X"71", X"72", X"73", X"74");
  
  signal DummyCount : Vector8(0 to 15) := (
    X"00", X"01", X"02", X"03", X"04", X"05", X"06", X"07", X"08", X"09", X"0A", X"0B", X"0C", X"0D", X"0E", X"0F"
    );

  signal PingRequest : Vector8(0 to 59) := (
    X"45", X"00", X"00", X"3C", X"2F", X"4C", X"00", X"00", X"80", X"01", X"00", X"00", X"C0", X"A8", X"68", X"40",
    X"C0", X"A8", X"68", X"68", X"08", X"00", X"4D", X"4B", X"00", X"01", X"00", X"10", X"61", X"62", X"63", X"64",
    X"65", X"66", X"67", X"68", X"69", X"6A", X"6B", X"6C", X"6D", X"6E", X"6F", X"70", X"71", X"72", X"73", X"74",
    X"75", X"76", X"77", X"61", X"62", X"63", X"64", X"65", X"66", X"67", X"68", X"69"
    );

  signal ArpPacket : Vector8(0 to 67) := (
    X"70", X"f3", X"95", X"00", X"72", X"1f", X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"08", X"06", X"00", X"01",
    X"08", X"00", X"06", X"04", X"00", X"02", X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"c0", X"a8", X"68", X"fe",
    X"70", X"f3", X"95", X"00", X"72", X"1f", X"c0", X"a8", X"68", X"40", X"00", X"00", X"00", X"00", X"00", X"00",
    X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
    X"AB", X"CD", X"EF", X"89");

  signal ArpQuery50 : Vector8(0 to 41) := (
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"70", X"f3", X"95", X"00", X"72", X"1f", X"08", X"06", X"00", X"01",
    X"08", X"00", X"06", X"04", X"00", X"01", X"70", X"f3", X"95", X"00", X"72", X"1f", X"c0", X"a8", X"68", X"40",
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"c0", X"a8", X"68", X"fe"
    );
  signal ArpQuery51 : Vector8(0 to 42) := (
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"70", X"f3", X"95", X"00", X"72", X"1f", X"08", X"06", X"00", X"01",
    X"08", X"00", X"06", X"04", X"00", X"01", X"70", X"f3", X"95", X"00", X"72", X"1f", X"c0", X"a8", X"68", X"40",
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"c0", X"a8", X"68", X"fe", X"12"
    );
  signal ArpQuery53 : Vector8(0 to 44) := (
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"70", X"f3", X"95", X"00", X"72", X"1f", X"08", X"06", X"00", X"01",
    X"08", X"00", X"06", X"04", X"00", X"01", X"70", X"f3", X"95", X"00", X"72", X"1f", X"c0", X"a8", X"68", X"40",
    X"30", X"f7", X"0d", X"ef", X"01", X"4e", X"c0", X"a8", X"68", X"fe", X"12", X"34", X"00"
    );

  signal UdpPacket16 : Vector8(0 to 43) := (
    X"45", X"00", X"00", X"3C", X"2F", X"4C", X"00", X"00", X"80", X"01", X"00", X"00", X"C0", X"A8", X"68", X"40",
    X"C0", X"A8", X"68", X"68", X"00", X"00", X"F0", X"00", X"00", X"18", X"00", X"00",
    X"00", X"01", X"02", X"03", X"04", X"05", X"06", X"07", X"08", X"09", X"0A", X"0B", X"0C", X"0D", X"0E", X"0F"
    );

  procedure CpuWrite (
    constant word      : in  std_logic_vector(31 downto 0);
    constant addr      : in  std_logic_vector(15 downto 0);
    signal   clk       : in  std_logic;
    signal   etherDin  : out std_logic_vector(31 downto 0);
    signal   etherWbe  : out std_logic_vector(3 downto 0);
    signal   etherAddr : out std_logic_vector(15 downto 0));

  procedure CpuRead (
    constant addr      : in  std_logic_vector(15 downto 0);
    signal   clk       : in  std_logic;
    signal   etherAddr : out std_logic_vector(15 downto 0));

  procedure CpuSendPacket (
    constant packet    : in  Vector8;
    signal   clk       : in  std_logic;
    signal   etherDin  : out std_logic_vector(31 downto 0);
    signal   etherWbe  : out std_logic_vector(3 downto 0);
    signal   etherAddr : out std_logic_vector(15 downto 0);
    signal   etherDout : in  std_logic_vector(31 downto 0));

  procedure SendPacket (
    constant packet : in  Vector8;
    signal   clk    : in  std_logic;
    signal   rxd    : out std_logic_vector(7 downto 0);
    signal   rxdv   : out std_logic);

  procedure SendByte (
    constant byte : in  std_logic_vector(7 downto 0);
    signal   clk  : in  std_logic;
    signal   rxd  : out std_logic_vector(7 downto 0);
    signal   rxdv : out std_logic);

  constant UNDEFINED : std_logic_vector(7 downto 0) := (others => 'U');

end EthernetTestPackets;

package body EthernetTestPackets is

  
  procedure CpuWrite (
    constant word      : in  std_logic_vector(31 downto 0);
    constant addr      : in  std_logic_vector(15 downto 0);
    signal   clk       : in  std_logic;
    signal   etherDin  : out std_logic_vector(31 downto 0);
    signal   etherWbe  : out std_logic_vector(3 downto 0);
    signal   etherAddr : out std_logic_vector(15 downto 0)) is
  begin
    wait until clk = '1';
    etherAddr <= addr;
    etherDin  <= word;
    etherWbe  <= X"F";
    wait until clk = '1';
    etherWbe  <= X"0";
  end CpuWrite;
  
  procedure CpuRead (
    constant addr      : in  std_logic_vector(15 downto 0);
    signal   clk       : in  std_logic;
    signal   etherAddr : out std_logic_vector(15 downto 0)) is
  begin
    wait until clk = '1';
    etherAddr <= addr;
    wait until clk = '1';
    wait until clk = '1';
  end CpuRead;
  
  procedure CpuSendPacket (
    constant packet    : in  Vector8;
    signal   clk       : in  std_logic;
    signal   etherDin  : out std_logic_vector(31 downto 0);
    signal   etherWbe  : out std_logic_vector(3 downto 0);
    signal   etherAddr : out std_logic_vector(15 downto 0);
    signal   etherDout : in  std_logic_vector(31 downto 0)) is
    variable word : std_logic_vector(31 downto 0);
    variable len  : std_logic_vector(31 downto 0);
    variable addr : std_logic_vector(15 downto 0);
  begin
    addr(15 downto ETHER_TXBUF_OFFSET'right)  := ETHER_TXBUF_OFFSET;
    addr(ETHER_TXBUF_OFFSET'right-1 downto 0) := (others => '0');
    CpuWrite(X"00000001", TX_CONTROL, clk, etherDin, etherWbe, etherAddr);
    for i in 0 to packet'length/4-1 loop
      word(31 downto 24) := packet(i*4);
      word(23 downto 16) := packet(i*4+1);
      word(15 downto 8)  := packet(i*4+2);
      word(7 downto 0)   := packet(i*4+3);
      CpuWrite(word, addr, clk, etherDin, etherWbe, etherAddr);
      addr               := addr + 4;
    end loop;

    len  := std_logic_vector(to_unsigned(packet'length, word'length));
    word := (others => '0');
    if len(1 downto 0) > 2 then
      word(15 downto 8) := packet((packet'length/4)*4+2);
    end if;
    if len(1 downto 0) > 1 then
      word(23 downto 16) := packet((packet'length/4)*4+1);
    end if;
    if len(1 downto 0) > 0 then
      word(31 downto 24) := packet((packet'length/4)*4);
      CpuWrite(word, addr, clk, etherDin, etherWbe, etherAddr);
    end if;

    CpuWrite(len, TX_PACKET_LENGTH, clk, etherDin, etherWbe, etherAddr);

    CpuWrite(X"00000002", TX_CONTROL, clk, etherDin, etherWbe, etherAddr);

    CpuRead(TX_CONTROL, clk, etherAddr);
    while etherDout(2) = '1' loop
      CpuRead(TX_CONTROL, clk, etherAddr);
    end loop;
    
  end CpuSendPacket;
  
  procedure SendByte (
    constant byte : in  std_logic_vector(7 downto 0);
    signal   clk  : in  std_logic;
    signal   rxd  : out std_logic_vector(7 downto 0);
    signal   rxdv : out std_logic) is
  begin

    wait until clk = '1';
    wait for 0.5 ns;
    rxd  <= (others => 'U');
    rxdv <= 'U';
    wait for 5 ns;
    rxd  <= byte;
    if byte /= UNDEFINED then
      rxdv <= '1';
    else
      rxdv <= '0';
    end if;
    
  end SendByte;
  
  procedure SendPacket (
    constant packet : in  Vector8;
    signal   clk    : in  std_logic;
    signal   rxd    : out std_logic_vector(7 downto 0);
    signal   rxdv   : out std_logic) is
  begin  -- SendPacket

    for i in 0 to 6 loop
      SendByte(X"55", clk, rxd, rxdv);
    end loop;  -- i
    SendByte(X"5D", clk, rxd, rxdv);

    for i in 0 to packet'right loop
      SendByte(packet(i), clk, rxd, rxdv);
    end loop;  -- i


    SendByte(UNDEFINED, clk, rxd, rxdv);
  end SendPacket;

end EthernetTestPackets;
