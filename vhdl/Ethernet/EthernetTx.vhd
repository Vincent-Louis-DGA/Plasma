library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.EthernetRegisters.all;

entity EthernetTx is
  
  port (
    clk_50  : in std_logic;
    reset_n : in std_logic;

    ethernetTXEN   : out std_logic                    := '0';
    ethernetTXCLK  : in  std_logic                    := '0';
    ethernetTXER   : out std_logic                    := '0';
    ethernetTXD    : out std_logic_vector(7 downto 0) := (others => '0');
    ethernetGTXCLK : out std_logic;

    etherDin       : in  std_logic_vector(31 downto 0) := (others => '0');
    etherTxDout    : out std_logic_vector(31 downto 0);
    etherTxConDout : out std_logic_vector(31 downto 0);
    etherAddr      : in  std_logic_vector(15 downto 0);
    etherRe        : in  std_logic;
    etherWbe       : in  std_logic_vector(3 downto 0);

    MacHigh : in std_logic_vector(15 downto 0);
    MacMid  : in std_logic_vector(15 downto 0);
    MacLow  : in std_logic_vector(15 downto 0)
    );

end EthernetTx;

architecture rtl of EthernetTx is

  constant MinFrameLength : std_logic_vector(11 downto 0) := X"004";  -- 60?
                                                                      
  constant MaxFrameLength : std_logic_vector(11 downto 0) := X"5DC";  -- 1500

  type TxState_t is (idle, preamble, header, data, crc, interframe);

  signal FifoState : TxState_t := idle;

  signal txBegin       : std_logic := '0';
  signal txBegin2      : std_logic;
  signal txBusy        : std_logic;
  signal fifoDin       : std_logic_vector(7 downto 0);
  signal fifoWe        : std_logic;
  signal ramWbe        : std_logic_vector(3 downto 0);
  signal ramWriteAddr  : std_logic_vector(10 downto 0);
  signal ramReadAddr   : std_logic_vector(10 downto 0);
  signal ramReadMax    : std_logic_vector(11 downto 0);
  signal ramDout       : std_logic_vector(31 downto 0);
  signal ramDoutSelect : std_logic_vector(1 downto 0);
  signal fifoReset     : std_logic;

  -- CPU Addressable Registers
  signal TxPacketLength                      : std_logic_vector(11 downto 0);
  signal DestMacHigh, DestMacMid, DestMacLow : std_logic_vector(15 downto 0);
  signal Ethertype                           : std_logic_vector(15 downto 0);

  -- clock domain crossing signals
  signal txBusy_txclk : std_logic;
  
begin  -- rtl

  ethernetGTXCLK <= ethernetTXCLK;

  FILL_FIFO : process (clk_50, reset_n)
  begin  -- process FILL_FIFO
    if reset_n = '0' then               -- asynchronous reset (active low)
      TxPacketLength <= MinFrameLength;
      fifoReset      <= '1';
      txBegin        <= '0';
      fifoWe         <= '0';
      ramReadAddr    <= (others => '1');
      ramReadMax     <= (others => '0');
      ramDoutSelect  <= (others => '0');
      etherTxConDout <= (others => '0');
      FifoState      <= idle;

      DestMacHigh <= X"0000";
      DestMacMid  <= X"0000";
      DestMacLow  <= X"0000";
      Ethertype   <= X"0800";
    elsif rising_edge(clk_50) then      -- rising clock edge
      fifoReset <= '0';
      fifoWe    <= '0';


      -- RAM reading / FIFO filling
      case FifoState is
        when idle =>
          txBegin <= '0';
        when header =>
          FifoState   <= data;
          ramReadAddr <= (others => '0');
          ramReadMax  <= TxPacketLength;
        when data =>
          ramReadAddr <= ramReadAddr + 1;
          fifoWe      <= '1';
          if ramReadAddr = TxPacketLength-1 then
            FifoState <= idle;
          end if;
          if ramReadAddr = (TxPacketLength - ("00" & TxPacketLength(11 downto 2))) then
            txBegin <= '1';
          end if;
        when others => null;
      end case;

      ramDoutSelect <= ramReadAddr(1 downto 0);

      -- CPU Register Writes
      if etherWbe /= X"0" then
        case etherAddr is
          when TX_CONTROL =>
            if etherDin(0) = '1' then
              fifoReset <= '1';
              FifoState <= idle;
            end if;
            if FifoState = idle and etherDin(1) = '1' then
              FifoState <= header;
            end if;
            
          when TX_PACKET_LENGTH =>
            if etherDin(11 downto 0) < MinFrameLength then
              TxPacketLength <= MinFrameLength;
            elsif etherDin(11 downto 0) > MaxFrameLength then
              TxPacketLength <= MaxFrameLength;
            else
              TxPacketLength <= etherDin(11 downto 0);
            end if;

          when TX_ETHERTYPE     => EtherType   <= etherDin(15 downto 0);
          when TX_DEST_MAC_LOW  => DestMacLow  <= etherDin(15 downto 0);
          when TX_DEST_MAC_MID  => DestMacMid  <= etherDin(15 downto 0);
          when TX_DEST_MAC_HIGH => DestMacHigh <= etherDin(15 downto 0);

          when others => null;
        end case;
      end if;

      -- CPU Register Reads
      case etherAddr is
        when TX_CONTROL =>
          etherTxConDout(1 downto 0) <= "00";
          if txBusy = '1' or ramReadAddr < TxPacketLength then
            etherTxConDout(2) <= '1';
          else
            etherTxConDout(2) <= '0';
          end if;
          etherTxConDout(31 downto 3) <= (others => '0');
          
        when TX_PACKET_LENGTH =>
          etherTxConDout <= X"00000" & TxPacketLength;

        when TX_ETHERTYPE     => etherTxConDout <= X"0000" & EtherType;
        when TX_DEST_MAC_LOW  => etherTxConDout <= X"0000" & DestMacLow;
        when TX_DEST_MAC_MID  => etherTxConDout <= X"0000" & DestMacMid;
        when TX_DEST_MAC_HIGH => etherTxConDout <= X"0000" & DestMacHigh;
        when others           => null;
      end case;

      
    end if;
  end process FILL_FIFO;

  ramWriteAddr <= etherAddr(10 downto 0);
  ramWbe       <= etherWbe when etherAddr(15 downto ETHER_TXBUF_OFFSET'right) = ETHER_TXBUF_OFFSET else X"0";

  with ramDoutSelect select
    fifoDin <=
    ramDout(31 downto 24) when "00",
    ramDout(23 downto 16) when "01",
    ramDout(15 downto 8)  when "10",
    ramDout(7 downto 0)   when others;

  process (clk_50, reset_n)
  begin  -- process
    if reset_n = '0' then               -- asynchronous reset (active low)
      txBusy   <= '1';
      txBegin2 <= '0';
    elsif rising_edge(clk_50) then      -- rising clock edge
      txBusy   <= txBusy_txclk;
      txBegin2 <= txBegin;
    end if;
  end process;

  TXRAM : entity work.dualRamMx8N
    generic map (
      N => 4,
      M => 9)
    port map (
      clka  => clk_50,
      wea   => ramWbe,
      addra => ramWriteAddr(10 downto 2),
      dina  => etherDin,
      douta => etherTxDout,
      clkb  => clk_50,
      web   => X"0",
      addrb => ramReadAddr(10 downto 2),
      dinb  => X"00000000",
      doutb => ramDout);

  -----------------------------------------------------------------------------
  -- ethernetTXCLK domain
  -----------------------------------------------------------------------------

  TXCLK_GEN : if true generate

    signal TxState     : TxState_t := idle;
    signal txCount     : std_logic_vector(7 downto 0);
    signal txData      : std_logic_vector(31 downto 0);
    signal txd         : std_logic_vector(7 downto 0);
    signal txen        : std_logic;
    signal txFifoFull  : std_logic;
    signal txFifoRe    : std_logic;
    signal txFifoEmpty : std_logic;
    signal txFifoDout  : std_logic_vector(7 downto 0);

    signal crcValid : std_logic;
    signal crcValue : std_logic_vector(31 downto 0);
    signal crcEn    : std_logic;
    signal crcReset : std_logic;
    signal crcDin   : std_logic_vector(7 downto 0);

    signal EtherHeader : std_logic_vector(111 downto 0);
  begin


    process (ethernetTXCLK, reset_n)
      variable begin1, begin2 : std_logic;
    begin  -- process
      if reset_n = '0' then                  -- asynchronous reset (active low)
        TxState      <= idle;
        txCount      <= (others => '0');
        txd          <= (others => '0');
        txen         <= '0';
        txData       <= (others => '0');
        begin1       := '0';
        begin2       := '0';
        txBusy_txclk <= '1';
        EtherHeader  <= (others => '0');
      elsif rising_edge(ethernetTXCLK) then  -- rising clock edge

        
        begin1       := txBegin2;
        txCount      <= txCount + 1;
        txen         <= '0';
        txBusy_txclk <= '1';

        ethernetTXD  <= txd;
        ethernetTXEN <= txen;

        case TxState is
          when idle =>
            txBusy_txclk <= '0';
            txCount      <= (others => '0');
            if begin1 = '1' and begin2 = '0' then
              TxState <= preamble;
              txData  <= X"55555555";
            end if;
          when preamble =>
            EtherHeader <= DestMacHigh & DestMacMid & DestMacLow
                           & MacHigh & MacMid & MacLow
                           & Ethertype;
            txen   <= '1';
            txData <= txData(23 downto 0) & X"00";
            txd    <= txData(31 downto 24);
            if txCount(3 downto 0) = X"7" then
              TxState <= header;
            elsif txCount(1 downto 0) = "11" then
              txData <= X"555555D5";
            end if;
          when header =>
            txen        <= '1';
            txd         <= EtherHeader(111 downto 104);
            EtherHeader <= EtherHeader(103 downto 0) & X"00";
            if txCount = 21 then
              TxState <= data;
            end if;

          when data =>
            txen    <= '1';
            txd     <= txFifoDout;
            txCount <= (0 => '1', others => '0');

            if txFifoEmpty = '1' then
              TxState <= crc;
              txd     <= crcValue(7 downto 0);
            end if;
          when crc =>
            txen <= '1';
            if txCount(1 downto 0) = "01" then
              txd <= crcValue(15 downto 8);
            elsif txCount(1 downto 0) = "10" then
              txd <= crcValue(23 downto 16);
            else
              txd     <= crcValue(31 downto 24);
              TxState <= interframe;
            end if;
            
          when interframe =>
            if txCount(3 downto 0) = X"E" then
              TxState <= idle;
            end if;
          when others => TxState <= idle;
        end case;

        begin2 := begin1;


      end if;
    end process;

    txFifoRe <= not txFifoEmpty when TxState = data else '0';

    TXFIFO : entity work.FallThroughFifo2048x8
      port map (
        rst    => fifoReset,
        wr_clk => clk_50,
        rd_clk => ethernetTXCLK,
        din    => fifoDin,
        wr_en  => fifoWe,
        rd_en  => txFifoRe,
        dout   => txFifoDout,
        full   => txFifoFull,
        empty  => txFifoEmpty);

    CRCGEN : entity work.CrcGenerator
      port map (
        clk     => ethernetTXCLK,
        reset_n => reset_n,
        sReset  => crcReset,
        en      => crcEn,
        din     => crcDin,
        dv      => crcValid,
        dout    => crcValue);

    crcEn    <= '1' when (txFifoRe = '1' or TxState = header) else '0';
    crcReset <= '1' when TxState = idle                       else '0';

    crcDin <= txFifoDout when TxState = data else EtherHeader(111 downto 104);

  end generate TXCLK_GEN;


end rtl;
