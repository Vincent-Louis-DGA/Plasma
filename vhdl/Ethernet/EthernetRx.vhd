library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.EthernetRegisters.all;

entity EthernetRx is
  generic (
    IGNORE_CRC : std_logic := '1');
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
    etherWbe       : in  std_logic_vector(3 downto 0);
    etherIrq       : out std_logic;
    MacHigh        : in  std_logic_vector(15 downto 0);
    MacMid         : in  std_logic_vector(15 downto 0);
    MacLow         : in  std_logic_vector(15 downto 0)
    );

end EthernetRx;

architecture rtl of EthernetRx is

  type   RXSTATE_T is (interframe, preamble, data, check, finish);
  signal FifoState : RXSTATE_T := interframe;

  signal rxFifoReset   : std_logic;
  signal rxFifoRe      : std_logic;
  signal rxFifoDout    : std_logic_vector(35 downto 0);
  signal rxFifoEmpty   : std_logic;
  signal rxPacketValid : std_logic;
  signal packetValid   : std_logic;


  signal ramWriteCount  : std_logic_vector(8 downto 0);
  signal ramWriteAddr   : std_logic_vector(11 downto 0);
  signal rxCount        : std_logic_vector(8 downto 0);
  signal ramWbe         : std_logic_vector(3 downto 0);
  signal ramWe          : std_logic;
  signal ramDin         : std_logic_vector(47 downto 0);
  signal ramWriteSelect : std_logic;
  signal rxActive       : std_logic;

  signal EtherHeader : std_logic_vector(127 downto 0);
  signal destMac : std_logic_vector(47 downto 0);
  signal ownMac : std_logic_vector(47 downto 0);

  signal packetLen : std_logic_vector(11 downto 0);

  -- Control Registers
  signal RxFilterMac : std_logic;

  signal RxPacketLength0 : std_logic_vector(11 downto 0);
  signal RxDestMac0      : std_logic_vector(47 downto 0);
  signal RxSrcMac0       : std_logic_vector(47 downto 0);
  signal RxEthertype0    : std_logic_vector(15 downto 0);

  signal RxPacketLength1 : std_logic_vector(11 downto 0);
  signal RxDestMac1      : std_logic_vector(47 downto 0);
  signal RxSrcMac1       : std_logic_vector(47 downto 0);
  signal RxEthertype1    : std_logic_vector(15 downto 0);

  signal crcActual   : std_logic_vector(31 downto 0);
  signal crcExpected : std_logic_vector(31 downto 0);

  signal rxCrcActual0   : std_logic_vector(31 downto 0);
  signal rxCrcExpected0 : std_logic_vector(31 downto 0);
  signal rxCrcExpected1 : std_logic_vector(31 downto 0);
  signal rxCrcActual1   : std_logic_vector(31 downto 0);
  
begin  -- rtl

  EMPTY_FIFO : process (clk_50, reset_n)
    variable active1, active2 : std_logic := '0';
  begin  -- process EMPTY_FIFO
    if reset_n = '0' then               -- asynchronous reset (active low)
      active1        := '0';
      active2        := '0';
      FifoState      <= interframe;
      rxFifoRe       <= '0';
      rxFifoReset    <= '1';
      ramWriteSelect <= '0';
      EtherHeader    <= (others => '0');
      rxCount        <= (others => '0');
      ramDin         <= (others => '0');
      ramWe          <= '0';
      ramWriteCount  <= (others => '1');
      packetLen      <= (others => '0');
      packetValid    <= '0';
    elsif rising_edge(clk_50) then      -- rising clock edge

      packetValid <= rxPacketValid;
      rxFifoRe    <= '0';
      ramWe       <= '0';
      rxFifoReset <= '0';

      case FifoState is
        when interframe =>
          packetLen     <= (others => '0');
          ramWriteCount <= (others => '1');
          if active1 = '0' and active2 = '1' then

            -- Discard if packet not valid.
            if packetValid = '0' then
              rxFifoReset <= '1';
            elsif RxPacketLength0 /= 0 and RxPacketLength1 /= 0 then
              -- No place to put it...
              rxFifoReset <= '1';
            else
              FifoState <= preamble;
              rxCount   <= (others => '0');
              rxFifoRe  <= '1';
              if RxPacketLength0 /= 0 then
                ramWriteSelect <= '1';
              else
                ramWriteSelect <= '0';
              end if;
            end if;
          end if;
          
        when preamble =>
          rxCount  <= rxCount + 1;
          rxFifoRe <= '1';
          if rxCount = 3 then
            if RxFilterMac = '0' then
              FifoState <= data;
            elsif destMac = ownMac then
              FifoState <= data;
            else
              FifoState   <= interframe;
              rxFifoReset <= '1';
            end if;
          end if;
          EtherHeader <= EtherHeader(95 downto 0) & rxFifoDout(35 downto 4);
          ramDin      <= X"0000" & rxFifoDout(35 downto 4);
          
        when data =>
          rxFifoRe      <= '1';
          ramWe         <= '1';
          ramWriteCount <= ramWriteCount + 1;
          if rxFifoEmpty = '1' then
            rxFifoRe  <= '0';
            FifoState <= check;
          else
            case rxFifoDout(3 downto 0) is
              when X"8"   => packetLen <= packetLen + 1;
              when X"C"   => packetLen <= packetLen + 2;
              when X"E"   => packetLen <= packetLen + 3;
              when others => packetLen <= packetLen + 4;
            end case;
          end if;
          ramDin <= ramDin(15 downto 0) & rxFifoDout(35 downto 4);

        when check  => FifoState <= finish;
        when finish => FifoState <= interframe;
        when others => FifoState <= interframe;
      end case;

      active2 := active1;
      active1 := rxActive;
    end if;
  end process EMPTY_FIFO;

  ownMac <= MacHigh & MacMid & MacLow;
  destMac <= EtherHeader(95 downto 48);
  ramWbe       <= X"F" when (ramWe = '1') else X"0";
  ramWriteAddr <= ramWriteSelect & ramWriteCount & "00";

  CPU_REG : process (clk_50, reset_n)
  begin  -- process CPU_REG
    if reset_n = '0' then               -- asynchronous reset (active low)
      RxPacketLength0 <= (others => '0');
      RxPacketLength1 <= (others => '0');
      RxFilterMac     <= '0';
      RxDestMac0      <= (others => '0');
      RxDestMac1      <= (others => '0');
      RxSrcMac0       <= (others => '0');
      RxSrcMac1       <= (others => '0');
      RxEtherType0    <= (others => '0');
      RxEthertype1    <= (others => '0');
      RxCrcActual0    <= (others => '0');
      RxCrcExpected0  <= (others => '0');
      RxCrcActual1    <= (others => '0');
      RxCrcExpected1  <= (others => '0');
      etherRxConDout  <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge

      if etherWbe /= X"0" then
        case etherAddr is
          when RX_CONTROL =>
            RxFilterMac <= etherDin(0);
          when RX_PACKET_LENGTH0 => RxPacketLength0 <= etherDin(11 downto 0);
          when RX_PACKET_LENGTH1 => RxPacketLength1 <= etherDin(11 downto 0);
          when others            => null;
        end case;
      end if;

      case etherAddr is
        when RX_CONTROL =>
          etherRxConDout <= (0 => RxFilterMac, others => '0');
        when RX_PACKET_LENGTH0 =>
          etherRxConDout <= X"00000" & RxPacketLength0;
        when RX_DEST_MAC0_HIGH =>
          etherRxConDout <= X"0000" & RxDestMac0(47 downto 32);
        when RX_DEST_MAC0_MID =>
          etherRxConDout <= X"0000" & RxDestMac0(31 downto 16);
        when RX_DEST_MAC0_LOW =>
          etherRxConDout <= X"0000" & RxDestMac0(15 downto 0);
        when RX_ETHERTYPE0 =>
          etherRxConDout <= X"0000" & RxEthertype0;
        when RX_SRC_MAC0_HIGH =>
          etherRxConDout <= X"0000" & RxSrcMac0(47 downto 32);
        when RX_SRC_MAC0_MID =>
          etherRxConDout <= X"0000" & RxSrcMac0(31 downto 16);
        when RX_SRC_MAC0_LOW =>
          etherRxConDout <= X"0000" & RxSrcMac0(15 downto 0);
        when RX_CRC0_ACTUAL =>
          etherRxConDout <= RxCrcActual0;
        when RX_CRC0_EXPECTED =>
          etherRxConDout <= RxCrcExpected0;
        when RX_PACKET_LENGTH1 =>
          etherRxConDout <= X"00000" & RxPacketLength1;
        when RX_DEST_MAC1_HIGH =>
          etherRxConDout <= X"0000" & RxDestMac1(47 downto 32);
        when RX_DEST_MAC1_MID =>
          etherRxConDout <= X"0000" & RxDestMac1(31 downto 16);
        when RX_DEST_MAC1_LOW =>
          etherRxConDout <= X"0000" & RxDestMac1(15 downto 0);
        when RX_ETHERTYPE1 =>
          etherRxConDout <= X"0000" & RxEthertype1;
        when RX_SRC_MAC1_HIGH =>
          etherRxConDout <= X"0000" & RxSrcMac1(47 downto 32);
        when RX_SRC_MAC1_MID =>
          etherRxConDout <= X"0000" & RxSrcMac1(31 downto 16);
        when RX_SRC_MAC1_LOW =>
          etherRxConDout <= X"0000" & RxSrcMac1(15 downto 0);
        when RX_CRC1_ACTUAL =>
          etherRxConDout <= RxCrcActual1;
        when RX_CRC1_EXPECTED =>
          etherRxConDout <= RxCrcExpected1;
        when others => null;
      end case;

      if FifoState = finish then
        if ramWriteSelect = '0' then
          RxPacketLength0 <= packetLen+2;
          RxDestMac0      <= EtherHeader(127 downto 80);
          RxSrcMac0       <= EtherHeader(79 downto 32);
          RxEthertype0    <= EtherHeader(31 downto 16);
          RxCrcActual0    <= crcActual;
          RxCrcExpected0  <= crcExpected;
        else
          RxPacketLength1 <= packetLen+2;
          RxDestMac1      <= EtherHeader(127 downto 80);
          RxSrcMac1       <= EtherHeader(79 downto 32);
          RxEthertype1    <= EtherHeader(31 downto 16);
          RxCrcActual1    <= crcActual;
          RxCrcExpected1  <= crcExpected;
        end if;
      end if;
      
    end if;
  end process CPU_REG;

  etherIrq <= '0' when RxPacketLength0 = 0 and RxPacketLength1 = 0 else '1';

  RXRAM : entity work.dualRamMx8N
    generic map (
      N => 4,
      M => 10)
    port map (
      clka  => clk_50,
      wea   => ramWbe,
      addra => ramWriteAddr(11 downto 2),
      dina  => ramDin(47 downto 16),
      douta => open,
      clkb  => clk_50,
      web   => X"0",
      addrb => etherAddr(11 downto 2),
      dinb  => X"00000000",
      doutb => etherRxDout);

  -----------------------------------------------------------------------------
  -- ethernetRXCLK domain
  -----------------------------------------------------------------------------

  RXCLK_GEN : if true generate

    signal RxState : RXSTATE_T := interframe;

    -- ethernetRXCLK domain signals
    signal rxd        : std_logic_vector(7 downto 0);
    signal rxdv       : std_logic;
    signal rxdv2      : std_logic;
    signal rxd32      : std_logic_vector(31 downto 0);
    signal rxdv32     : std_logic_vector(3 downto 0);
    signal rxdFinal4  : std_logic_vector(35 downto 0);
    signal rxFifoDin  : std_logic_vector(35 downto 0);
    signal rxFifoWe   : std_logic;
    signal alignCount : std_logic_vector(1 downto 0);

    signal crcEn      : std_logic;
    signal crcValue   : std_logic_vector(31 downto 0);
    signal crcValueLE : std_logic_vector(31 downto 0);
    signal crcDin     : std_logic_vector(7 downto 0);
    signal crcReset   : std_logic;
  begin

    rxActive <= '0' when RxState = interframe else '1';

    process (ethernetRXCLK, reset_n)
    begin  -- process
      if reset_n = '0' then             -- asynchronous reset (active low)
        rxd           <= (others => '0');
        rxdv          <= '0';
        rxdv2         <= '0';
        rxd32         <= (others => '0');
        rxdv32        <= (others => '0');
        rxFifoDin     <= (others => '0');
        rxFifoWe      <= '0';
        RxState       <= interframe;
        alignCount    <= (others => '0');
        rxdFinal4     <= (others => '0');
        crcReset      <= '1';
        rxPacketValid <= '0';

        crcActual   <= (others => '0');
        crcExpected <= (others => '0');
        
      elsif rising_edge(ethernetRXCLK) then  -- rising clock edge
        rxd      <= ethernetRXD;
        rxdv     <= ethernetRXDV;
        rxdv2    <= rxdv;
        rxFifoWe <= '0';
        case RxState is
          when interframe =>
            if rxdv = '1' then
              if rxd = X"5D" then
                RxState <= data;
              else
                RxState <= preamble;
              end if;
            end if;
            crcReset <= '1';

          when preamble =>
            if rxdv = '0' then
              RxState <= interframe;
            elsif rxd = X"D5" then
              RxState <= data;
            end if;
            crcReset      <= '0';
            rxPacketValid <= '0';

          when data =>
            alignCount <= alignCount + 1;
            rxdv32     <= rxdv32(2 downto 0) & rxdv;
            rxd32      <= rxd32(23 downto 0) & rxd;
            if alignCount = "00" and rxdv32 = X"F" then
              rxFifodin <= rxd32 & rxdv32;
            end if;
            if alignCount = "11" and rxdv32 = X"F" and rxdv = '1' then
              rxFifoWe <= '1';
            end if;
            if rxdv = '0' then
              RxState   <= check;
              rxdFinal4 <= rxd32 & rxdv32;
              rxd32     <= rxd32(23 downto 0) & X"00";
              rxdv32    <= X"0";
            end if;

          when check =>
            RxState <= finish;
            if alignCount = "11" then
              rxFifoWe              <= '1';
              rxFifoDin(3 downto 0) <= X"C";
            elsif alignCount = "00" then
              rxFifoDin(3 downto 0) <= X"E";
              rxFifoWe              <= '1';
            elsif alignCount = "10" then
              rxFifoDin(3 downto 0) <= X"8";
              rxFifoWe              <= '1';
            end if;
            alignCount  <= (others => '0');
            crcActual   <= crcValueLE;
            crcExpected <= rxdFinal4(35 downto 4);
            if IGNORE_CRC = '1' then
              rxPacketValid <= '1';
            end if;
            if crcValueLE = rxdFinal4(35 downto 4) then
              rxPacketValid <= '1';
            end if;
          when finish =>
            RxState <= interframe;
          when others => RxState <= interframe;
        end case;
      end if;
    end process;

    RxFifo : entity work.fallThroughFifo512x36
      port map (
        rst    => rxFifoReset,
        wr_clk => ethernetRXCLK,
        rd_clk => clk_50,
        din    => rxFifoDin,
        wr_en  => rxFifoWe,
        rd_en  => rxFifoRe,
        dout   => rxFifoDout,
        full   => open,
        empty  => rxFifoEmpty);

    crcDin     <= rxd32(31 downto 24);
    crcEn      <= '1' when (rxdv32(3) = '1' and rxdv = '1') else '0';
    crcValueLE <= crcValue(7 downto 0) & crcValue(15 downto 8) &
                  crcValue(23 downto 16) & crcValue(31 downto 24);

    CRCGEN : entity work.CrcGenerator
      port map (
        clk     => ethernetRXCLK,
        reset_n => reset_n,
        sReset  => crcReset,
        en      => crcEn,
        din     => crcDin,
        dv      => open ,
        dout    => crcValue);

  end generate RXCLK_GEN;


end rtl;
