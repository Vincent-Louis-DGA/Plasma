library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.EthernetRegisters.all;

entity EthernetRx is
  
  port (
    clk_50  : in std_logic;
    reset_n : in std_logic;

    ethernetRXDV  : in std_logic                    := '0';
    ethernetRXCLK : in std_logic                    := '0';
    ethernetRXER  : in std_logic                    := '0';
    ethernetRXD   : in std_logic_vector(7 downto 0) := (others => '0');

    etherDin       : in  std_logic_vector(31 downto 0) := (others => '0');
    etherRxDout    : out std_logic_vector(31 downto 0);
    etherRxConDout : out std_logic_vector(31 downto 0);
    etherAddr      : in  std_logic_vector(15 downto 0);
    etherRe        : in  std_logic;
    etherWbe       : in  std_logic_vector(3 downto 0)
    );

end EthernetRx;

architecture rtl of EthernetRx is

  type Vector16 is array (natural range<>) of std_logic_vector(15 downto 0);


  -- ethernetRXCLK domain
  signal s_reset : std_logic;
  signal rxdv    : std_logic;
  signal rxd     : std_logic_vector(7 downto 0);
  signal rxd2    : std_logic_vector(7 downto 0);

  type   STATE is (sreset, interframe, preamble, data, check, pass, fail);
  signal RxState   : STATE := interframe;
  signal rxCounter : std_logic_vector(15 downto 0);

  signal ramDin    : std_logic_vector(7 downto 0);
  signal ramWrAddr : std_logic_vector(12 downto 0);
  signal ramWea    : std_logic_vector(0 downto 0);
  signal rxLen     : std_logic_vector(15 downto 0);
  signal rxOffset  : std_logic_vector(12 downto 0);

  signal srcMac        : std_logic_vector(47 downto 0);
  signal destMac       : std_logic_vector(47 downto 0);
  signal srcMacFilter  : std_logic_vector(47 downto 0);
  signal destMacFilter : std_logic_vector(47 downto 0);

  -- domain crossing signals, ethernetRXCLK.
  signal frameCompleteToggle : std_logic;

  -- dmain crossing signals, clk_50.
  signal frameComplete : std_logic;
  signal rxLen_50      : std_logic_vector(15 downto 0);
  signal rxOffset_50   : std_logic_vector(15 downto 0);

  -- clk_50 domain


  signal ramDout   : std_logic_vector(31 downto 0);
  signal ramRdAddr : std_logic_vector(12 downto 2);
  signal ramWeb    : std_logic_vector(3 downto 0);


  signal RxPacketValid : std_logic_vector(1 downto 0);
  signal PacketOffsets : Vector16(1 downto 0);
  signal PacketLengths : Vector16(1 downto 0);
  signal nextValid     : integer;

  signal srcMacFilter_50  : std_logic_vector(47 downto 0);
  signal destMacFilter_50 : std_logic_vector(47 downto 0);
  
begin  -- rtl

  RXD_REG : process (ethernetRXCLK, reset_n)
  begin  -- process RXD_REG
    if reset_n = '0' then                  -- asynchronous reset (active low)
      rxdv                <= '0';
      rxd                 <= (others => '0');
      rxd2                <= (others => '0');
      rxCounter           <= (others => '0');
      RxState             <= interframe;
      ramDin              <= (others => '0');
      ramWrAddr           <= (others => '0');
      ramWea              <= (others => '0');
      rxLen               <= (others => '0');
      rxOffset            <= (others => '0');
      frameCompleteToggle <= '0';
      srcMac              <= (others => '0');
      destMac             <= (others => '0');
    elsif rising_edge(ethernetRXCLK) then  -- rising clock edge
      rxdv   <= ethernetRXDV;
      rxd    <= ethernetRXD;
      rxd2   <= rxd;
      ramWea <= (others => '0');
      case RxState is
        when sreset =>
          RxState   <= interframe;
          rxCounter <= (others => '0');
          rxLen     <= (others => '0');
          rxOffset  <= (others => '0');
        when interframe =>
          if rxdv = '1' then
            RxState <= preamble;
          end if;
        when preamble =>
          if ramWrAddr(1 downto 0) /= "00" then
            ramWrAddr <= ramWrAddr + 1;
          end if;
          rxOffset  <= ramWrAddr;
          rxCounter <= (others => '0');
          if rxdv = '0' then
            RxState <= interframe;
          elsif rxd2 /= X"55" then
            RxState <= data;
          end if;
        when data =>
          rxCounter <= rxCounter + 1;
          ramWea    <= (others => '1');
          ramDin    <= rxd2;
          ramWrAddr <= rxCounter(ramWrAddr'left downto 0) + rxOffset;
          if rxdv = '0' then
            RxState <= check;
          end if;
          if rxCounter < 6 then
            destMac <= destMac(39 downto 0) & rxd2;
          elsif rxCounter < 12 then
            srcMac <= srcMac(39 downto 0) & rxd2;
          end if;
        when check =>
          if srcMacFilter /= 0 and srcMac /= srcMacFilter then
            RxState <= fail;
          elsif destMacFilter /= 0 and destMac /= destMacFilter then
            RxState <= fail;
          else
            RxState <= pass;
          end if;
          
        when pass =>
          rxLen               <= rxCounter;
          frameCompleteToggle <= not frameCompleteToggle;
          RxState             <= interframe;
        when fail =>
          ramWrAddr <= rxOffset;
          RxState   <= interframe;
        when others =>
          RxState <= interframe;
      end case;
    end if;
  end process RXD_REG;

  CLK50_to_ETH : process (ethernetRXCLK, reset_n)
  begin  -- process CLK50_to_ETH
    if reset_n = '0' then                  -- asynchronous reset (active low)
      srcMacFilter  <= (others => '0');
      destMacFilter <= (others => '0');
    elsif rising_edge(ethernetRXCLK) then  -- rising clock edge
      destMacFilter <= destMacFilter_50;
      srcMacFilter  <= srcMacFilter_50;
    end if;
  end process CLK50_to_ETH;

  ECLK_to_CLK50 : process (clk_50, reset_n)
    variable fct : std_logic_vector(2 downto 0);
  begin  -- process ECLK_to_CLK50
    if reset_n = '0' then               -- asynchronous reset (active low)
      fct           := (others => '0');
      frameComplete <= '0';
      rxLen_50      <= (others => '0');
      rxOffset_50   <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      fct           := fct(fct'left-1 downto 0) & frameCompleteToggle;
      frameComplete <= '0';
      if fct(2) /= fct(1) then
        frameComplete <= '1';
        rxLen_50      <= rxLen;
        rxOffset_50   <= "000" & rxOffset;
      end if;
    end if;
  end process ECLK_to_CLK50;

  CPU_REG : process (clk_50, reset_n)
  begin  -- process CPU_REG
    if reset_n = '0' then               -- asynchronous reset (active low)
      PacketLengths    <= (others => (others => '0'));
      PacketOffsets    <= (others => (others => '0'));
      RxPacketValid    <= (others => '0');
      nextValid        <= 0;
      etherRxConDout   <= (others => '0');
      srcMacFilter_50  <= (others => '0');
      destMacFilter_50 <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      if frameComplete = '1' then
        if RxPacketValid(nextValid) = '0' then
          RxPacketValid(nextValid) <= '1';
          PacketLengths(nextValid) <= rxLen_50;
          PacketOffsets(nextValid) <= rxOffset_50;
        end if;
        if nextValid = 1 then
          nextValid <= 0;
        else
          nextValid <= nextValid + 1;
        end if;
      end if;

      if etherWbe /= X"0" then
        case etherAddr is
          when RX_PACKET_VALID_ADDR =>
            RxPacketValid <= RxPacketValid and not etherDin(1 downto 0);
          when SRCMAC_FILTER0_ADDR  => srcMacFilter_50(31 downto 0)   <= etherDin;
          when SRCMAC_FILTER1_ADDR  => srcMacFilter_50(47 downto 32)  <= etherDin(15 downto 0);
          when DESTMAC_FILTER0_ADDR => destMacFilter_50(31 downto 0)  <= etherDin;
          when DESTMAC_FILTER1_ADDR => destMacFilter_50(47 downto 32) <= etherDin(15 downto 0);
          when others               => null;
        end case;
      end if;

      if etherAddr = RX_PACKET_VALID_ADDR then
        etherRxConDout <= X"0000000" & "00" & RxPacketValid;
      elsif etherAddr(15 downto RX_PACKET_OFFSETS'right) = RX_PACKET_OFFSETS then
        etherRxConDout <= X"0000" & PacketOffsets(to_integer(unsigned(etherAddr(4 downto 2))));
      elsif etherAddr(15 downto RX_PACKET_LENGTHS'right) = RX_PACKET_LENGTHS then
        etherRxConDout <= X"0000" & PacketLengths(to_integer(unsigned(etherAddr(4 downto 2))));
      end if;
      
    end if;
  end process CPU_REG;

  ramRdAddr <= etherAddr(ramRdAddr'left downto ramRdAddr'right);

  ramWeb      <= etherWbe when etherAddr(15 downto ETHER_RX_OFFSET'right) = ETHER_RX_OFFSET else X"0";
  etherRxDout <= ramDout;

  RAM : entity work.dualRam8kx8_2kx32
    port map (
      clka  => ethernetRXCLK,
      wea   => ramWea,
      addra => ramWrAddr,
      dina  => ramDin,
      douta => open,
      clkb  => clk_50,
      web   => ramWeb,
      addrb => ramRdAddr,
      dinb  => etherDin,
      doutb => ramDout);




end rtl;
