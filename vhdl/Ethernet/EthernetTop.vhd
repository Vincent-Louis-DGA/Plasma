library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

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

    -- Ex Bus
    etherDin  : in  std_logic_vector(31 downto 0) := (others => '0');
    etherDout : out std_logic_vector(31 downto 0);
    etherAddr : in  std_logic_vector(15 downto 0);
    etherRe   : in  std_logic;
    etherWbe  : in  std_logic_vector(3 downto 0)
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

  signal etherConDout : std_logic_vector(31 downto 0);
  signal etherAddrReg : std_logic_vector(15 downto 0);
  signal etherRxDout : std_logic_vector(31 downto 0);
  signal etherTxDout : std_logic_vector(31 downto 0);

  constant ETHER_MDIO_WR_ADDR : std_logic_vector(15 downto 0) := X"0000";
  constant ETHER_MDIO_RE_ADDR : std_logic_vector(15 downto 0) := X"0004";
  constant ETHER_MDIO_RD_ADDR : std_logic_vector(15 downto 0) := X"0008";
  constant ETHER_STATUS_ADDR  : std_logic_vector(15 downto 0) := X"000C";


  constant ETHER_RX_PRD   : std_logic_vector(15 downto 0) := X"0014";
  constant ETHER_TX_PRD   : std_logic_vector(15 downto 0) := X"0010";
  constant ETHER_RXD_ADDR : std_logic_vector(15 downto 0) := X"0020";


  signal rxClk1024   : std_logic;
  signal txClk1024   : std_logic;
  signal rxClk1024_i : std_logic;
  signal txClk1024_i : std_logic;
  signal rxClkCount  : std_logic_vector(31 downto 0);
  signal txClkCount  : std_logic_vector(31 downto 0);
  signal rxClkPeriod : std_logic_vector(31 downto 0);
  signal txClkPeriod : std_logic_vector(31 downto 0);



  signal rxFifoWe    : std_logic;
  signal rxFifoRe    : std_logic;
  signal rxFifoEmpty : std_logic;
  signal rxFifoDin   : std_logic_vector(7 downto 0);
  signal rxFifoDout  : std_logic_vector(7 downto 0);
  signal rxFifoReset : std_logic;

  type   STATE is (interframe, preamble, data, check, done);
  signal RxState : STATE := interframe;
  
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


  RXD_REG : process (ethernetRXCLK, reset_n)
  begin  -- process RXD_REG
    if reset_n = '0' then                  -- asynchronous reset (active low)
      rxFifoWe  <= '0';
      rxFifoDin <= (others => '0');
      RxState   <= interframe;
    elsif rising_edge(ethernetRXCLK) then  -- rising clock edge
      rxFifoWe <= '0';

      if ethernetRXDV = '1' then
        case RxState is
          when interframe =>
            RxState <= preamble;
          when preamble =>
            if ethernetRXD = X"5D" then
              RxState <= data;
            end if;
          when data =>
            rxFifoWe  <= ethernetRXDV;
            rxFifoDin <= ethernetRXD;
          when others =>
            RxState <= interframe;
        end case;
        
      else
        RxState <= interframe;
      end if;

    end if;
  end process RXD_REG;

  etherWe <= '0' when etherWbe = X"0" else '1';

  CPU_BUS : process (clk_50, reset_n)
  begin  -- process EX_BUS
    if reset_n = '0' then               -- asynchronous reset (active low)
      eWriteData   <= (others => '0');
      eAddr        <= (others => '0');
      eWe          <= '0';
      eRe          <= '0';
      etherConDout <= (others => '0');
      rxFifoReset  <= '0';
      rxFifoRe     <= '0';
      etherAddrReg <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      eWe          <= '0';
      eRe          <= '0';
      rxFifoReset  <= '0';
      rxFifoRe     <= '0';
      etherAddrReg <= etherAddr;
      if etherWe = '1' then
        case etherAddr is
          when ETHER_MDIO_WR_ADDR =>
            eWriteData <= etherDin(15 downto 0);
            eAddr      <= etherDin(28 downto 24);
            eWe        <= '1';
          when ETHER_MDIO_RE_ADDR =>
            eAddr <= etherDin(28 downto 24);
            eRe   <= '1';
          when ETHER_STATUS_ADDR =>
            rxFifoReset <= etherDin(3);
          when others => null;
        end case;
      end if;
      case etherAddr is
        when ETHER_MDIO_RD_ADDR => etherConDout <= X"0000" & eReadData;
        when ETHER_STATUS_ADDR  => etherConDout <= X"0000000" & "00"
                                                   & rxFifoEmpty & eRts;
        when ETHER_TX_PRD   => etherConDout <= txClkPeriod;
        when ETHER_RX_PRD   => etherConDout <= rxClkPeriod;
        when ETHER_RXD_ADDR =>
          etherConDout <= X"000000" & rxFifoDout;
          rxFifoRe     <= etherRe;
        when others => null;
      end case;
    end if;
  end process CPU_BUS;

  CPU_DOUT : process (etherAddrReg, etherConDout, etherRxDout, etherTxDout)
  begin  -- process CPU_DOUT
    if etherAddrReg(15 downto 14) = "00" then
      etherDout <= etherConDout;
    elsif etherAddrReg(15 downto 14) = "01" then
      etherDout <= etherTxDout;
    else
      etherDout <= etherRxDout;
    end if;
  end process CPU_DOUT;


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

  
  

  RX_FIFO : entity work.fallThroughFifo2048x8
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

end rtl;
