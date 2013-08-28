---------------------------------------------------------------------
-- TITLE: Plasma MCU with DDR2 RAM targetting Digilent ATLYS Board
-- AUTHOR: Adrian Jongenelen
--
-- Adds a shared Fifo to get 32-bit words in/out of the CPU.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.plasmaPeriphRegisters.all;


entity PlasmaDataAcquisition is
  generic(
    uartLogFile     : string    := "UNUSED";
    simulateRam     : std_logic := '0';
    simulateProgram : std_logic := '0'
    );
  port(
    clk_100    : in  std_logic;
    reset_ex_n : in  std_logic;         -- external reset
    UartRx     : in  std_logic;
    UartTx     : out std_logic;

    leds     : out   std_logic_vector(7 downto 0);
    switches : in    std_logic_vector(7 downto 0);
    buttons  : in    std_logic_vector(4 downto 0);
    pmod     : inout std_logic_vector(7 downto 0);

    Uart_bypassRx         : in  std_logic_vector(7 downto 0) := (others => '0');
    Uart_bypassRxWeToggle : in  std_logic                    := '0';
    Uart_bypassTx         : out std_logic_vector(7 downto 0);
    Uart_bypassTxDv       : out std_logic;


    -- Flash
    FlashCLK   : out   std_logic;
    FlashCS    : out   std_logic;
    FlashTris  : out   std_logic_vector(3 downto 0);
    FlashMemDq : inout std_logic_vector(3 downto 0) := (others => 'Z');

    -- DDR2 SDRAM on ATLYS Board
    ddr_s_dq     : inout std_logic_vector(15 downto 0) := (others => 'Z');
    ddr_s_a      : out   std_logic_vector(12 downto 0);
    ddr_s_ba     : out   std_logic_vector(2 downto 0);
    ddr_s_ras_n  : out   std_logic;
    ddr_s_cas_n  : out   std_logic;
    ddr_s_we_n   : out   std_logic;
    ddr_s_odt    : out   std_logic;
    ddr_s_cke    : out   std_logic;
    ddr_s_dm     : out   std_logic;
    ddr_d_udqs   : inout std_logic                     := 'Z';
    ddr_d_udqs_n : inout std_logic                     := 'Z';
    ddr_s_rzq    : inout std_logic                     := 'Z';
    ddr_s_zio    : inout std_logic                     := 'Z';
    ddr_s_udm    : out   std_logic;
    ddr_d_dqs    : inout std_logic                     := 'Z';
    ddr_d_dqs_n  : inout std_logic                     := 'Z';
    ddr_d_ck     : out   std_logic;
    ddr_d_ck_n   : out   std_logic
    );
end;


architecture logic of PlasmaDataAcquisition is

  signal clk     : std_logic;
  signal reset_n : std_logic;

  signal pmodReg     : std_logic_vector(7 downto 0);
  signal switchesReg : std_logic_vector(7 downto 0);
  signal buttonsReg  : std_logic_vector(7 downto 0);
  signal nonsenseReg : std_logic_vector(7 downto 0);
  signal counter     : std_logic_vector(31 downto 0);

  signal samplePrescale : std_logic_vector(5 downto 0);
  signal sampleCount    : std_logic_vector(15 downto 0);
  signal sample         : std_logic;

  signal dataMask  : std_logic_vector(7 downto 0);
  signal sampleDiv : std_logic_vector(31 downto 0);

  signal FifoDin : std_logic_vector(7 downto 0);
  signal FifoWe  : std_logic;

  signal ExBusDin  : std_logic_vector(31 downto 0);
  signal ExBusDout : std_logic_vector(31 downto 0);
  signal ExBusAddr : std_logic_vector(27 downto 0);
  signal ExBusRe   : std_logic;
  signal ExBusWe   : std_logic;

begin  --architecture

  DO_SAMPLE : process (clk, reset_n)
  begin  -- process DO_SAMPLE
    if reset_n = '0' then               -- asynchronous reset (active low)
      samplePrescale <= (others => '0');
      sampleCount    <= (others => '0');
      sample         <= '0';
    elsif rising_edge(clk) then         -- rising clock edge
      samplePrescale <= samplePrescale + 1;
      if samplePrescale = 24 then
        samplePrescale <= (others => '0');
        sampleCount    <= sampleCount + 1;
        if sampleCount = sampleDiv then
          sampleCount <= (others => '0');
          sample      <= '1';
        else
          sample <= '0';
        end if;
      end if;
    end if;
  end process DO_SAMPLE;

  process (clk, reset_n)
  begin  -- process
    if reset_n = '0' then               -- asynchronous reset (active low)
      pmodReg     <= (others => '0');
      switchesReg <= (others => '0');
      counter     <= (others => '0');
      buttonsReg  <= (others => '0');
      nonsenseReg <= (others => '0');
      FifoWe      <= '0';
      FifoDin     <= (others => '0');
    elsif rising_edge(clk) then         -- rising clock edge
      FifoWe <= '0';
      if samplePrescale = 0 then
        counter <= counter + 1;
      end if;
      if sampleCount = 0 and samplePrescale = 0 then
        pmodReg     <= pmod;
        switchesReg <= switches;
        buttonsReg  <= "000" & buttons;
        nonsenseReg <= "00110" & counter(2 downto 0);
      end if;
      if sample = '1' then
        if samplePrescale(5 downto 3) = "001" then
          for i in 0 to dataMask'left loop
            if samplePrescale(2 downto 0) = i then
              if dataMask(i) = '1' then
                FifoWe <= '1';
              end if;
            end if;
          end loop;  -- i
          case samplePrescale(2 downto 0) is
            when "000"  => FifoDin <= pmodReg;
            when "001"  => FifoDin <= switchesReg;
            when "010"  => FifoDin <= buttonsReg;
            when "011"  => FifoDin <= nonsenseReg;
            when "100"  => FifoDin <= counter(7 downto 0);
            when "101"  => FifoDin <= counter(15 downto 8);
            when "110"  => FifoDin <= counter(23 downto 16);
            when others => FifoDin <= counter(31 downto 24);
          end case;
        end if;
      end if;
    end if;
  end process;

  MCU_EXBUS : process (clk, reset_n)
  begin  -- process MCU_EXBUS
    if reset_n = '0' then               -- asynchronous reset (active low)
      sampleDiv <= (others => '0');
      dataMask  <= (others => '0');
    elsif rising_edge(clk) then         -- rising clock edge
      if ExBusWe = '1' then
        case ExBusAddr is
          when X"0000000" => sampleDiv <= ExBusDout;
          when X"0000004" => dataMask  <= ExBusDout(7 downto 0);
          when others     => null;
        end case;
      end if;
    end if;
  end process MCU_EXBUS;

  ExBusDin <= sampleDiv when ExBusAddr = X"0000000" else X"000000" & dataMask;


  MCU : entity work.PlasmaTop
    generic map (
      uartLogFile     => uartLogFile,
      simulateRam     => simulateRam,
      simulateProgram => simulateProgram,
      AtlysDDR        => '1')
    port map (
      clk_100      => clk_100,
      reset_ex_n   => reset_ex_n,
      sysClk       => clk,
      reset_n      => reset_n,
      UartRx       => UartRx,
      UartTx       => UartTx,
      leds         => leds,
      switches     => switches,
      buttons      => buttons,
      pmod         => pmod,
      FifoDin      => FifoDin,
      FifoWe       => FifoWe,
      ExBusDin     => ExBusDin,
      ExBusDout    => ExBusDout,
      ExBusAddr    => ExBusAddr,
      ExBusRe      => ExBusRe,
      ExBusWe      => ExBusWe,
      FlashClk     => FlashClk,
      FlashCS      => FlashCS,
      FlashTris    => FlashTris,
      FlashMemDq   => FlashMemDq,
      ddr_s_dq     => ddr_s_dq,
      ddr_s_a      => ddr_s_a,
      ddr_s_ba     => ddr_s_ba,
      ddr_s_ras_n  => ddr_s_ras_n,
      ddr_s_cas_n  => ddr_s_cas_n,
      ddr_s_we_n   => ddr_s_we_n,
      ddr_s_odt    => ddr_s_odt,
      ddr_s_cke    => ddr_s_cke,
      ddr_s_dm     => ddr_s_dm,
      ddr_d_udqs   => ddr_d_udqs,
      ddr_d_udqs_n => ddr_d_udqs_n,
      ddr_s_rzq    => ddr_s_rzq,
      ddr_s_zio    => ddr_s_zio,
      ddr_s_udm    => ddr_s_udm,
      ddr_d_dqs    => ddr_d_dqs,
      ddr_d_dqs_n  => ddr_d_dqs_n,
      ddr_d_ck     => ddr_d_ck,
      ddr_d_ck_n   => ddr_d_ck_n);


end;  --architecture logic

