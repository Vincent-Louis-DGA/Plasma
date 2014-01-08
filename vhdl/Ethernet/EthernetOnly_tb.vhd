library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.EthernetTestPackets.all;
use work.EthernetRegisters.all;

entity EthernetOnly_tb is

end EthernetOnly_tb;

architecture testbench of EthernetOnly_tb is

  signal clk_50  : std_logic := '1';
  signal reset_n : std_logic := '0';

  -- Ethernet
  signal ethernetMDIO    : std_logic                    := 'H';
  signal ethernetMDC     : std_logic;
  signal ethernetINT_n   : std_logic;
  signal ethernetRESET_n : std_logic;
  signal ethernetCOL     : std_logic                    := '1';
  signal ethernetCRS     : std_logic                    := '1';
  signal ethernetRXDV    : std_logic                    := '0';
  signal ethernetRXCLK   : std_logic                    := '0';
  signal ethernetRXER    : std_logic                    := '0';
  signal ethernetRXD     : std_logic_vector(7 downto 0) := (others => '0');
  signal ethernetGTXCLK  : std_logic;
  signal ethernetTXCLK   : std_logic                    := '0';
  signal ethernetTXER    : std_logic;
  signal ethernetTXEN    : std_logic;
  signal ethernetTXD     : std_logic_vector(7 downto 0);

  -- Cpu Bus
  signal etherDin1  : std_logic_vector(31 downto 0) := (others => '0');
  signal etherDout1 : std_logic_vector(31 downto 0);
  signal etherAddr1 : std_logic_vector(15 downto 0) := (others => '0');
  signal etherRe1   : std_logic                     := '0';
  signal etherWbe1  : std_logic_vector(3 downto 0)  := (others => '0');
  signal etherIrq   : std_logic;

  signal etherDin2  : std_logic_vector(31 downto 0) := (others => '0');
  signal etherDout2 : std_logic_vector(31 downto 0);
  signal etherAddr2 : std_logic_vector(15 downto 0) := (others => '0');
  signal etherRe2   : std_logic                     := '0';
  signal etherWbe2  : std_logic_vector(3 downto 0)  := (others => '0');
  
begin  -- testbench

  clk_50        <= not clk_50        after 10 ns;
  ethernetRXCLK <= not ethernetRXCLK after 4 ns;
  ethernetTXCLK <= not ethernetTXCLK after 20 ns;

  UUT1 : entity work.EthernetTop
    port map (
      clk          => clk_50,
      clk_125 => ethernetRXCLK,
      reset_n         => reset_n,
      ethernetMDIO    => ethernetMDIO,
      ethernetMDC     => ethernetMDC,
      ethernetINT_n   => ethernetINT_n,
      ethernetRESET_n => ethernetRESET_n,
      ethernetCOL     => ethernetCOL,
      ethernetCRS     => ethernetCRS,
      ethernetRXDV    => ethernetRXDV,
      ethernetRXCLK   => ethernetRXCLK,
      ethernetRXER    => ethernetRXER,
      ethernetRXD     => ethernetRXD,
      ethernetGTXCLK  => ethernetGTXCLK,
      ethernetTXCLK   => ethernetTXCLK,
      ethernetTXER    => ethernetTXER,
      ethernetTXEN    => ethernetTXEN,
      ethernetTXD     => ethernetTXD,
      etherAddr       => etherAddr1,
      etherDin        => etherDin1,
      etherDout       => etherDout1,
      etherRe         => etherRe1,
      etherWbe        => etherWbe1,
      etherIrq        => etherIrq
      );

  UUT2 : entity work.EthernetTop
    port map (
      clk        => clk_50,
      clk_125 => ethernetRXCLK,
      reset_n       => reset_n,
      ethernetRXCLK => ethernetRXCLK,
      ethernetTXCLK => ethernetTXCLK,
      ethernetTXD   => ethernetRXD,
      ethernetTXEN  => ethernetRXDV,
      etherAddr     => etherAddr2,
      etherDin      => etherDin2,
      etherDout     => etherDout2,
      etherRe       => etherRe2,
      etherWbe      => etherWbe2);

  RM : entity work.Ram_Program
    port map (
      clka  => clk_50,
      addra => etherAddr2(14 downto 2),
      dina  => etherDin2,
      wea   => etherWbe2,
      douta => open,
      clkb => clk_50);
    

  tb : process
  begin  -- process tb
    reset_n <= '0';
    wait for 200 ns;
    reset_n <= '1';
    wait for 200 ns;

    CpuWrite(X"00006162", TX_DEST_MAC_HIGH, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00006364", TX_DEST_MAC_MID, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00006566", TX_DEST_MAC_LOW, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00006768", ETHER_MAC_HIGH, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"0000696A", ETHER_MAC_MID, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00006B6C", ETHER_MAC_LOW, clk_50, etherDin2, etherWbe2, etherAddr2);
    CpuWrite(X"00006D6E", TX_ETHERTYPE, clk_50, etherDin2, etherWbe2, etherAddr2);


    CpuSendPacket(ShortPacket, clk_50, etherDin2, etherWbe2, etherAddr2, etherDout2);

    wait for 2 us;
    CpuSendPacket(PingRequest, clk_50, etherDin2, etherWbe2, etherAddr2, etherDout2);

    wait for 2 us;
    CpuSendPacket(ArpPacket, clk_50, etherDin2, etherWbe2, etherAddr2, etherDout2);


    wait;
  end process tb;

  tb_rx : process
    variable len : integer;
  begin  -- process tb_rx
    wait until reset_n = '1';
    wait for 200 ns;

    CpuWrite(X"00006162", ETHER_MAC_HIGH, clk_50, etherDin1, etherWbe1, etherAddr1);
    CpuWrite(X"00006364", ETHER_MAC_MID, clk_50, etherDin1, etherWbe1, etherAddr1);
    CpuWrite(X"00006566", ETHER_MAC_LOW, clk_50, etherDin1, etherWbe1, etherAddr1);

    loop

      if etherIrq = '0' then
        wait for 500 ns;
        
      else
        wait for 2 us;
        CpuRead(RX_PACKET_LENGTH0, clk_50, etherAddr1);
        len := to_integer(unsigned(etherDout1));
        if etherDout1 > 0 then
          -- Read from RXBUF0
          etherAddr1 <= ETHER_RXBUF_OFFSET & X"000";
          for i in 0 to len-1 loop
            wait for 400 ns;
            wait until clk_50 = '1';
            etherAddr1 <= etherAddr1 + 1;
          end loop;  -- i
          CpuWrite(X"00000000", RX_PACKET_LENGTH0, clk_50, etherDin1, etherWbe1, etherAddr1);
        end if;

        CpuRead(RX_PACKET_LENGTH1, clk_50, etherAddr1);
        len := to_integer(unsigned(etherDout1));
        if etherDout1 > 0 then
          -- Read from RXBUF1
          etherAddr1 <= ETHER_RXBUF_OFFSET & X"800";
          for i in 0 to len-1 loop
            wait for 400 ns;
            wait until clk_50 = '1';
            etherAddr1 <= etherAddr1 + 1;
          end loop;  -- i
          CpuWrite(X"00000000", RX_PACKET_LENGTH1, clk_50, etherDin1, etherWbe1, etherAddr1);
        end if;

        wait for 500 ns;
      end if;
    end loop;

  end process tb_rx;

  
end testbench;
