library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.EthernetRegisters.all;

entity EthernetTop is
  
  port (
    clk_50  : in std_logic;
    reset_n : in std_logic;

    -- Ethernet
    ethernetMDIO    : inout std_logic                    := '0';
    ethernetMDC     : out   std_logic                    := '0';
    ethernetINT_n   : out   std_logic                    := '0';
    ethernetRESET_n : out   std_logic                    := '1';
    ethernetCOL     : in    std_logic                    := '0';
    ethernetCRS     : in    std_logic                    := '0';
    ethernetRXDV    : in    std_logic                    := '0';
    ethernetRXCLK   : in    std_logic                    := '0';
    ethernetRXER    : in    std_logic                    := '0';
    ethernetRXD     : in    std_logic_vector(7 downto 0) := (others => '0');
    ethernetGTXCLK  : out   std_logic                    := '0';
    ethernetTXCLK   : in    std_logic                    := '0';
    ethernetTXER    : out   std_logic                    := '0';
    ethernetTXEN    : out   std_logic                    := '0';
    ethernetTXD     : out   std_logic_vector(7 downto 0) := (others => '0');

    -- Cpu Bus
    etherDin  : in  std_logic_vector(31 downto 0) := (others => '0');
    etherDout : out std_logic_vector(31 downto 0);
    etherAddr : in  std_logic_vector(15 downto 0);
    etherRe   : in  std_logic;
    etherWbe  : in  std_logic_vector(3 downto 0);

    etherIrq : out std_logic
    );

end EthernetTop;

architecture rtl of EthernetTop is
  signal count_r : std_logic_vector(25 downto 0);
  signal count_t : std_logic_vector(25 downto 0);

  signal etherWe    : std_logic;
  signal eWe        : std_logic;
  signal eRe        : std_logic;
  signal eRts       : std_logic;
  signal eAddr      : std_logic_vector(4 downto 0);
  signal eReadData  : std_logic_vector(15 downto 0);
  signal eWriteData : std_logic_vector(15 downto 0);

  signal etherConDout   : std_logic_vector(31 downto 0);
  signal etherAddrReg   : std_logic_vector(15 downto 0);
  signal etherRxConDout : std_logic_vector(31 downto 0);
  signal etherTxConDout : std_logic_vector(31 downto 0);
  signal etherRxDout    : std_logic_vector(31 downto 0);
  signal etherTxDout    : std_logic_vector(31 downto 0);


  signal rxClk1024   : std_logic;
  signal txClk1024   : std_logic;
  signal rxClk1024_i : std_logic;
  signal txClk1024_i : std_logic;
  signal rxClkCount  : std_logic_vector(31 downto 0);
  signal txClkCount  : std_logic_vector(31 downto 0);
  signal rxClkPeriod : std_logic_vector(31 downto 0);
  signal txClkPeriod : std_logic_vector(31 downto 0);

  signal MacHigh : std_logic_vector(15 downto 0);
  signal MacMid  : std_logic_vector(15 downto 0);
  signal MacLow  : std_logic_vector(15 downto 0);

  
begin  -- rtl
  
  ethernetRESET_n <= reset_n;

  process (ethernetRXCLK, reset_n)
  begin  -- process
    if reset_n = '0' then                  -- asynchronous reset (active low)
      count_r <= (others => '0');
    elsif rising_edge(ethernetRXCLK) then  -- rising clock edge
      count_r <= count_r + 1;
    end if;
  end process;

  process (ethernetTXCLK, reset_n)
  begin  -- process
    if reset_n = '0' then                  -- asynchronous reset (active low)
      count_t <= (others => '0');
    elsif rising_edge(ethernetTXCLK) then  -- rising clock edge
      count_t <= count_t + 1;
    end if;
  end process;


  process (clk_50, reset_n)
  begin  -- process
    if reset_n = '0' then               -- asynchronous reset (active low)
      rxClk1024   <= '0';
      txClk1024   <= '0';
      rxClk1024_i <= '0';
      txClk1024_i <= '0';
      rxClkCount  <= (others => '0');
      txClkCount  <= (others => '0');
      rxClkPeriod <= (others => '0');
      txClkPeriod <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      rxClk1024   <= count_r(9);
      txClk1024   <= count_t(9);
      rxClk1024_i <= rxClk1024;
      txClk1024_i <= txClk1024;
      rxClkCount  <= rxClkCount + 1;
      txClkCount  <= txClkCount + 1;
      if rxClk1024 = '1' and rxClk1024_i = '0' then
        rxClkPeriod <= rxClkCount+1;
        rxClkCount  <= (others => '0');
      end if;
      if txClk1024 = '1' and txClk1024_i = '0' then
        txClkPeriod <= txClkCount+1;
        txClkCount  <= (others => '0');
      end if;
    end if;
  end process;


  etherWe <= '0' when etherWbe = X"0" else '1';

  CPU_BUS : process (clk_50, reset_n)
  begin  -- process EX_BUS
    if reset_n = '0' then               -- asynchronous reset (active low)
      eWriteData   <= (others => '0');
      eAddr        <= (others => '0');
      eWe          <= '0';
      eRe          <= '0';
      etherConDout <= (others => '0');
      etherAddrReg <= (others => '0');
      MacHigh      <= DEFAULT_ETHER_MAC(47 downto 32);
      MacMid       <= DEFAULT_ETHER_MAC(31 downto 16);
      MacLow       <= DEFAULT_ETHER_MAC(15 downto 0);
    elsif rising_edge(clk_50) then      -- rising clock edge
      eWe          <= '0';
      eRe          <= '0';
      etherAddrReg <= etherAddr(15 downto 0);
      if etherWe = '1' then
        case etherAddr(15 downto 0) is
          when MDIO_WRITE_ADDR =>
            eWriteData <= etherDin(15 downto 0);
            eAddr      <= etherDin(28 downto 24);
            eWe        <= '1';
          when MDIO_READADDR_ADDR =>
            eAddr <= etherDin(28 downto 24);
            eRe   <= '1';
            
          when ETHER_MAC_LOW  => MacLow  <= etherDin(15 downto 0);
          when ETHER_MAC_MID  => MacMid  <= etherDin(15 downto 0);
          when ETHER_MAC_HIGH => MacHigh <= etherDin(15 downto 0);

          when others => null;
        end case;
      end if;
      case etherAddr(15 downto 0) is
        when MDIO_READ_ADDR => etherConDout <= X"0000" & eReadData;
        when STATUS_ADDR    => etherConDout <= X"0000000" & "000" & eRts;
        when TX_PRD         => etherConDout <= txClkPeriod;
        when RX_PRD         => etherConDout <= rxClkPeriod;

        when ETHER_MAC_LOW  => etherConDout <= X"0000" & MacLow;
        when ETHER_MAC_MID  => etherConDout <= X"0000" & MacMid;
        when ETHER_MAC_HIGH => etherConDout <= X"0000" & MacHigh;
        when others         => null;
      end case;
    end if;
  end process CPU_BUS;

  CPU_DOUT : process (etherAddrReg, etherConDout, etherRxDout, etherTxDout,
                      etherRxConDout, etherTxConDout)
  begin  -- process CPU_DOUT
    if etherAddrReg(15 downto ETHER_RXCON_OFFSET'right) = ETHER_RXCON_OFFSET then
      etherDout <= etherRxConDout;
    elsif etherAddrReg(15 downto ETHER_TXCON_OFFSET'right) = ETHER_TXCON_OFFSET then
      etherDout <= etherTxConDout;
    elsif etherAddrReg(15 downto ETHER_CON_OFFSET'right) = ETHER_CON_OFFSET then
      etherDout <= etherConDout;
    elsif etherAddrReg(15 downto ETHER_TXBUF_OFFSET'right) = ETHER_TXBUF_OFFSET then
      etherDout <= etherTxDout;
    else
      etherDout <= etherRxDout;
    end if;
  end process CPU_DOUT;


  RXD_IF : entity work.EthernetRx
    port map (
      clk_50         => clk_50,
      reset_n        => reset_n,
      ethernetRXDV   => ethernetRXDV,
      ethernetRXCLK  => ethernetRXCLK,
      ethernetRXER   => ethernetRXER,
      ethernetRXD    => ethernetRXD,
      etherDin       => etherDin,
      etherRxDout    => etherRxDout,
      etherRxConDout => etherRxConDout,
      etherAddr      => etherAddr,
      etherRe        => etherRe,
      etherWbe       => etherWbe,
      etherIrq       => etherIrq,
      MacHigh        => MacHigh,
      MacMid         => MacMid,
      MacLow         => MacLow);


  TXD_IF : entity work.EthernetTx
    port map (
      clk_50         => clk_50,
      reset_n        => reset_n,
      ethernetTXEN   => ethernetTXEN,
      ethernetTXCLK  => ethernetRXCLK,
      ethernetGTXCLK => ethernetGTXCLK,
      ethernetTXER   => ethernetTXER,
      ethernetTXD    => ethernetTXD,
      etherDin       => etherDin,
      etherTxDout    => etherTxDout,
      etherTxConDout => etherTxConDout,
      etherAddr      => etherAddr,
      etherRe        => etherRe,
      etherWbe       => etherWbe,
      MacHigh        => MacHigh,
      MacMid         => MacMid,
      MacLow         => MacLow);

  MDIO_IF : entity work.EthernetMDIO
    port map (
      clk_50    => clk_50,
      reset_n   => reset_n,
      MDC       => ethernetMDC,
      MDIO      => ethernetMDIO,
      addr      => eAddr,
      readData  => eReadData,
      writeData => eWriteData,
      we        => eWe,
      re        => eRe,
      rts       => eRts);




end rtl;
