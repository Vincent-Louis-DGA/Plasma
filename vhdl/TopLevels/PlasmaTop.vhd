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


entity PlasmaTop is
  generic(
    log_file   : string    := "UNUSED";
    simulation : std_logic := '0';
    ATLYS_DDR  : std_logic := '0'
    );
  port(
    clk_100    : in  std_logic;
    reset_ex_n : in  std_logic;         -- external reset
    sysClk     : out std_logic;         -- 50 MHz system clock.
    reset_n    : out std_logic;         -- system generated reset
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

    FifoDin   : in  std_logic_vector(31 downto 0) := (others => '0');
    FifoDout  : out std_logic_vector(31 downto 0);
    FifoWe    : in  std_logic                     := '0';
    FifoRe    : in  std_logic                     := '0';
    FifoFull  : out std_logic;
    FifoEmpty : out std_logic;
    FifoClear : in  std_logic                     := '0';

    ExBusDin  : in  std_logic_vector(31 downto 0) := (others => '0');
    ExBusDout : out std_logic_vector(31 downto 0);
    ExBusAddr : out std_logic_vector(31 downto 0);
    ExBusRe   : out std_logic;
    ExBusWe   : out std_logic;

    -- Flash
    FlashCLK   : out   std_logic;
    FlashCS    : out   std_logic;
    FlashTris  : out   std_logic_vector(3 downto 0);
    FlashMemDq : inout std_logic_vector(3 downto 0);

    -- DDR2 SDRAM on ATLYS Board
    ddr_d_dq     : inout std_logic_vector(15 downto 0) := (others => 'Z');
    ddr_d_a      : out   std_logic_vector(12 downto 0);
    ddr_d_ba     : out   std_logic_vector(2 downto 0);
    ddr_d_ras_n  : out   std_logic;
    ddr_d_cas_n  : out   std_logic;
    ddr_d_we_n   : out   std_logic;
    ddr_d_odt    : out   std_logic;
    ddr_d_cke    : out   std_logic;
    ddr_d_dm     : out   std_logic;
    ddr_d_udqs   : inout std_logic                     := 'Z';
    ddr_d_udqs_n : inout std_logic                     := 'Z';
    ddr_d_rzq    : inout std_logic                     := 'Z';
    ddr_d_zio    : inout std_logic                     := 'Z';
    ddr_d_udm    : out   std_logic;
    ddr_d_dqs    : inout std_logic                     := 'Z';
    ddr_d_dqs_n  : inout std_logic                     := 'Z';
    ddr_d_ck     : out   std_logic;
    ddr_d_ck_n   : out   std_logic
    );
end;


architecture logic of PlasmaTop is


  attribute keep : string;

  signal clk_50             : std_logic;
  signal clk_mem            : std_logic;
  attribute keep of clk_50  : signal is "true";
  attribute keep of clk_mem : signal is "true";

  signal reset_ex  : std_logic;
  signal reset     : std_logic;
  signal reset_n_i : std_logic;

  signal bus_address    : std_logic_vector(31 downto 0);
  signal periph_address : std_logic_vector(31 downto 0);
  signal bus_din        : std_logic_vector(31 downto 0);
  signal mem_pause_in   : std_logic;

  signal periph_dout       : std_logic_vector(31 downto 0);
  signal periph_re         : std_logic;
  signal periph_we         : std_logic;
  signal periph_irq        : std_logic;
  signal periph_din_debug  : std_logic_vector(31 downto 0);
  signal periph_addr_read  : std_logic_vector(31 downto 0);
  signal periph_dout_debug : std_logic_vector(31 downto 0);
  signal periph_addr_write : std_logic_vector(31 downto 0);
  signal periph_re2        : std_logic;

  signal uart_re   : std_logic;
  signal uart_we   : std_logic;
  signal uart_dout : std_logic_vector(7 downto 0);
  signal uart_irq  : std_logic;

  signal ex_ram_address  : std_logic_vector(31 downto 0);
  signal ex_ram_dout     : std_logic_vector(31 downto 0);
  signal ex_ram_wbe      : std_logic_vector(3 downto 0);
  signal ex_ram_wbe2     : std_logic_vector(3 downto 0);
  signal ex_ram_en       : std_logic;
  signal ex_ram_busy     : std_logic;
  signal ex_ram_debug    : std_logic_vector(7 downto 0);
  signal cache_hitcount  : std_logic_vector(31 downto 0);
  signal cache_readcount : std_logic_vector(31 downto 0);

  signal leds_reg     : std_logic_vector(31 downto 0);
  signal leds_we      : std_logic := '0';
  signal buttons_reg  : std_logic_vector(buttons'left downto 0);
  signal switches_reg : std_logic_vector(switches'left downto 0);
  signal pmod_we      : std_logic := '0';
  signal pmod_reg     : std_logic_vector(pmod'left downto 0);
  signal pmod_i       : std_logic_vector(31 downto 0);

  signal rand_reg : std_logic_vector(31 downto 0) := (others => '0');
  signal rand_re  : std_logic                     := '0';
  signal rand_we  : std_logic                     := '0';

  signal irq_status  : std_logic_vector(31 downto 0) := (others => '0');
  signal irq_mask    : std_logic_vector(31 downto 0) := (others => '1');
  signal intr_vector : std_logic_vector(31 downto 0) := X"0000004C";

  signal buttons_reg2 : std_logic_vector(buttons'left downto 0);

  signal bypassRxWeToggle_sim : std_logic := '0';

  signal counter1     : std_logic_vector(31 downto 0) := (others => '0');
  signal counter1_psc : std_logic_vector(31 downto 0) := (others => '0');
  signal counter1_ps  : std_logic_vector(31 downto 0) := (others => '0');
  signal counter1_tc  : std_logic_vector(31 downto 0) := (others => '1');

  -----------------------------------------------------------------------------
  -- Fifo Signals
  -----------------------------------------------------------------------------
  signal fifoDout_i  : std_logic_vector(31 downto 0);
  signal fifoDin_i   : std_logic_vector(31 downto 0);
  signal fifoRe_i    : std_logic := '0';
  signal fifoWe_i    : std_logic := '0';
  signal fifoFull_i  : std_logic;
  signal fifoEmpty_i : std_logic;
  signal fifoClear_i : std_logic;
  signal fifoClear_c : std_logic;

  -----------------------------------------------------------------------------
  -- Flash Signals
  -----------------------------------------------------------------------------
  signal Flash_tris   : std_logic_vector(3 downto 0);
  signal Flash_dq_out : std_logic_vector(3 downto 0);
  signal Flash_dq_in  : std_logic_vector(3 downto 0);
  signal Flash_cs     : std_logic;
  signal Flash_sclk   : std_logic;

  -----------------------------------------------------------------------------
  -- DDR2 RAM Signals
  -----------------------------------------------------------------------------
  signal cmd_0_en        : std_logic;
  signal cmd_0_instr     : std_logic_vector(2 downto 0);
  signal cmd_0_bl        : std_logic_vector(5 downto 0);
  signal cmd_0_byte_addr : std_logic_vector(29 downto 0);
  signal wr_0_en         : std_logic;
  signal wr_0_mask       : std_logic_vector(3 downto 0);
  signal wr_0_data       : std_logic_vector(31 downto 0);
  signal wr_0_full       : std_logic;
  signal rd_0_en         : std_logic;
  signal rd_0_data       : std_logic_vector(31 downto 0);
  signal rd_0_empty      : std_logic;
  
begin  --architecture

  sysClk   <= clk_50;
  reset_n  <= reset_n_i;
  reset_ex <= not reset_ex_n;


-------------------------------------------------------------------------------
-- FIFO
-------------------------------------------------------------------------------
  fifoRe_i    <= '1' when fifoRe = '1' else periph_re when bus_address = FIFO_DOUT_ADDR else '0';
  fifoWe_i    <= '1' when fifoWe = '1' else periph_we when bus_address = FIFO_DIN_ADDR else '0';
  fifoDout    <= fifoDout_i;
  fifoFull    <= fifoFull_i;
  fifoEmpty   <= fifoEmpty_i;
  fifoClear_i <= FifoClear or fifoClear_c;

  fifoDin_i <= bus_din when (bus_address = FIFO_DIN_ADDR and periph_we = '1') else fifoDin;

  process (clk_50, reset_n_i)
  begin  -- process
    if reset_n_i = '0' then             -- asynchronous reset (active low)
      fifoClear_c <= '1';
    elsif rising_edge(clk_50) then      -- rising clock edge
      fifoClear_c <= '0';
      if bus_address = FIFO_CON_ADDR and periph_we = '1' then
        fifoClear_c <= bus_din(2);
      end if;
    end if;
  end process;

  FIFO : entity work.fifo64x8N
    generic map (
      N            => 4,
      FALL_THROUGH => '0')
    port map (
      rst    => fifoClear_i,
      wr_clk => clk_50,
      rd_clk => clk_50,
      din    => fifoDin_i,
      wr_en  => fifoWe_i,
      rd_en  => fifoRe_i,
      dout   => fifoDout_i,
      full   => fifoFull_i,
      empty  => fifoEmpty_i);

-------------------------------------------------------------------------------
-- RAM and CPU
-------------------------------------------------------------------------------

  ExBusAddr <= bus_address(31 downto 2) & "00";
  ExBusDout <= bus_din;
  ExBusRe   <= periph_re when bus_address(31 downto 28) = EX_BUS_OFFSET else '0';
  ExBusWe   <= periph_we when bus_address(31 downto 28) = EX_BUS_OFFSET else '0';

  u1_plasma : entity work.PlasmaCore
    generic map (memory_type => "XILINX_16X",
                 SIMULATION  => SIMULATION)
    port map (
      clk   => clk_50,
      reset => reset,

      bus_address  => bus_address(31 downto 2),
      bus_din      => bus_din,
      ex_ram_addr  => ex_ram_address,
      ex_ram_dout  => ex_ram_dout,
      ex_ram_wbe   => ex_ram_wbe,
      ex_ram_en    => ex_ram_en,
      periph_dout  => periph_dout,
      periph_we    => periph_we,
      periph_re    => periph_re,
      periph_irq   => periph_irq,
      intr_vector  => INTERRUPT_VECTOR,
      mem_pause_in => mem_pause_in);

  BLOCK_RAM : if ATLYS_DDR = '0' generate
    u2_memory : entity work.dualRamMx8N
      generic map (
        N => 4,
        M => EX_RAM_ADDR_WIDTH)
      port map (
        clka  => clk_50,
        wea   => ex_ram_wbe2,
        addra => ex_ram_address(EX_RAM_ADDR_WIDTH+1 downto 2),
        dina  => bus_din,
        douta => ex_ram_dout,

        clkb  => clk_50,
        web   => X"0",
        addrb => "1111000000000",
        dinb  => X"00000000",
        doutb => open
        );
    BRS : if simulation = '1' generate
      process (clk_100, reset_ex_n)
      begin  -- process
        if reset_ex_n = '0' then
          clk_50    <= '1';
          reset_n_i <= '0';
        elsif rising_edge(clk_100) then  -- rising clock edge
          clk_50    <= not clk_50;
          reset_n_i <= '1';
        end if;
      end process;
    end generate BRS;
    BRP : if simulation /= '1' generate
      
      u3_pll : entity work.systemPLL
        port map (
          clk_100   => clk_100,
          clk_50_0  => clk_50,
          clk_100_0 => open,
          clk_19_0  => open,
          reset     => reset_ex,
          locked    => reset_n_i);
    end generate BRP;
    reset        <= not reset_n_i;
    mem_pause_in <= '0';
    ex_ram_wbe2  <= ex_ram_wbe when ex_ram_address(29 downto EX_RAM_ADDR_WIDTH+2) = ZEROS32(29 downto EX_RAM_ADDR_WIDTH+2) else (others => '0');

    ddr_d_a     <= (others => '0');
    ddr_d_ck_n  <= '1';
    ddr_d_we_n  <= '1';
    ddr_d_dm    <= '1';
    ddr_d_ba    <= (others => '0');
    ddr_d_cas_n <= '1';
    ddr_d_ras_n <= '1';
    ddr_d_ck    <= '0';
    ddr_d_cke   <= '0';
    ddr_d_odt   <= '0';
    ddr_d_udm   <= '0';
    
  end generate BLOCK_RAM;

  DDR_RAM : if ATLYS_DDR = '1' generate
    
    u2_memory : entity work.ddr2_1Gb_wrapper
      generic map (
        DO_SIMULATION => simulation)
      port map (
        clk100           => clk_100,
        reset_n          => reset_ex_n,
        clk50            => clk_50,
        clk_mem          => open,       -- using clk_mem isn't implementable...
        reset            => reset,
        mcb3_dram_dq     => ddr_d_dq,
        mcb3_dram_a      => ddr_d_a,
        mcb3_dram_ba     => ddr_d_ba,
        mcb3_dram_ras_n  => ddr_d_ras_n,
        mcb3_dram_cas_n  => ddr_d_cas_n,
        mcb3_dram_we_n   => ddr_d_we_n,
        mcb3_dram_odt    => ddr_d_odt,
        mcb3_dram_cke    => ddr_d_cke,
        mcb3_dram_dm     => ddr_d_dm,
        mcb3_dram_udqs   => ddr_d_udqs,
        mcb3_dram_udqs_n => ddr_d_udqs_n,
        mcb3_rzq         => ddr_d_rzq,
        mcb3_zio         => ddr_d_zio,
        mcb3_dram_udm    => ddr_d_udm,
        mcb3_dram_dqs    => ddr_d_dqs,
        mcb3_dram_dqs_n  => ddr_d_dqs_n,
        mcb3_dram_ck     => ddr_d_ck,
        mcb3_dram_ck_n   => ddr_d_ck_n,


        -- port 0
        cmd_0_clk       => clk_50,
        cmd_0_en        => cmd_0_en,
        cmd_0_instr     => cmd_0_instr,
        cmd_0_bl        => cmd_0_bl,
        cmd_0_byte_addr => cmd_0_byte_addr,
        cmd_0_empty     => open,
        cmd_0_full      => open,
        wr_0_clk        => clk_50,
        wr_0_en         => wr_0_en,
        wr_0_mask       => wr_0_mask,
        wr_0_data       => wr_0_data,
        wr_0_full       => wr_0_full,
        rd_0_clk        => clk_50,
        rd_0_en         => rd_0_en,
        rd_0_data       => rd_0_data,
        rd_0_empty      => rd_0_empty
        );
    reset_n_i <= not reset;

    u3_memCache : entity work.ddr2_cache
      port map (
        sys_clk            => clk_50,
        reset              => reset,
        mig_cmd_en         => cmd_0_en,
        mig_cmd_bl         => cmd_0_bl,
        mig_cmd_instr      => cmd_0_instr,
        mig_cmd_byte_addr  => cmd_0_byte_addr,
        mig_wr_data        => wr_0_data,
        mig_wr_en          => wr_0_en,
        mig_wr_mask        => wr_0_mask,
        mig_rd_clk         => clk_50,
        mig_rd_data        => rd_0_data,
        mig_rd_en          => rd_0_en,
        mig_rd_empty       => rd_0_empty,
        addr(28 downto 0)  => ex_ram_address(28 downto 0),
        addr(31 downto 29) => "000",
        din                => bus_din,
        wbe                => ex_ram_wbe2,
        en                 => ex_ram_en,
        dout               => ex_ram_dout,
        readBusy           => ex_ram_busy,
        hitcount           => cache_hitcount,
        readcount          => cache_readcount,
        debug              => ex_ram_debug);

    mem_pause_in <= ex_ram_busy;

    ex_ram_wbe2 <= ex_ram_wbe when ex_ram_address(29 downto DDR_RAM_ADDR_WIDTH+2) = ZEROS32(29 downto DDR_RAM_ADDR_WIDTH+2) else (others => '0');
    
  end generate DDR_RAM;
-------------------------------------------------------------------------------
-- Peripherals
-------------------------------------------------------------------------------


  REGISTERS : process (clk_50, reset)
  begin  -- process REG_ADDR
    if reset = '1' then                 -- asynchronous reset (active high)
      periph_address <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      periph_address <= bus_address;
    end if;
  end process REGISTERS;

  PERIPH_MUX : process (periph_address, uart_dout, switches_reg, buttons_reg,
                        leds_reg, pmod_reg, irq_mask, irq_status, rand_reg,
                        intr_vector, counter1, counter1_ps,
                        counter1_tc, cache_hitcount, cache_readcount,
                        flash_dq_in, flash_sclk, flash_tris, flash_cs,
                        fifoFull_i, fifoEmpty_i, fifoDout_i)
  begin  -- process PERIPH_MUX
    if periph_address(31 downto UART_OFFSET'right) = UART_OFFSET then
      periph_dout <= ZEROS32(31 downto uart_dout'length) & uart_dout;
    elsif periph_address(31 downto LEDS_OFFSET'right) = LEDS_OFFSET then
      periph_dout <= leds_reg;
    elsif periph_address = SWITCHES_ADDR then
      periph_dout <= ZEROS32(31 downto switches'length) & switches_reg;
    elsif periph_address = BUTTONS_ADDR then
      periph_dout <= ZEROS32(31 downto buttons'length) & buttons_reg;
    elsif periph_address(31 downto PMOD_OFFSET'right) = PMOD_OFFSET then
      periph_dout <= ZEROS32(31 downto pmod'length) & pmod_reg;
    elsif periph_address = RAND_ADDR then
      periph_dout <= rand_reg;
    elsif periph_address = IRQ_STATUS_ADDR then
      periph_dout <= irq_status;
    elsif periph_address = IRQ_MASK_ADDR then
      periph_dout <= irq_mask;
    elsif periph_address = IRQ_VECTOR_ADDR then
      periph_dout <= intr_vector;
    elsif periph_address = COUNTER1_ADDR then
      periph_dout <= counter1;
    elsif periph_address = COUNTER1_PS_ADDR then
      periph_dout <= counter1_ps;
    elsif periph_address = COUNTER1_TC then
      periph_dout <= counter1_tc;
    elsif periph_address = CACHE_HITCOUNT_ADDR then
      periph_dout <= cache_hitcount;
    elsif periph_address = CACHE_READCOUNT_ADDR then
      periph_dout <= cache_readcount;
    elsif periph_address = FLASH_CON_ADDR then
      periph_dout <= X"0000000" & "00" & flash_cs & flash_sclk;
    elsif periph_address = FLASH_DATA_ADDR then
      periph_dout <= X"0000000" & flash_dq_in;
    elsif periph_address = FLASH_TRIS_ADDR then
      periph_dout <= X"0000000" & flash_tris;
    elsif periph_address = FIFO_DOUT_ADDR then
      periph_dout <= fifoDout_i;
    elsif periph_address = FIFO_CON_ADDR then
      periph_dout <= X"0000000" & "00" & not fifoEmpty_i & fifoFull_i;
    else
      periph_dout <= X"DEADC0DE";
    end if;
  end process PERIPH_MUX;

  leds_we <= periph_we when
             bus_address(31 downto LEDS_OFFSET'right) = LEDS_OFFSET else '0';
  
  pmod_we <= periph_we when
             bus_address(31 downto PMOD_OFFSET'right) = PMOD_OFFSET else '0';

  uart_re <= periph_re when
             bus_address(31 downto UART_OFFSET'right) = UART_OFFSET else '0';
  uart_we <= periph_we when
             bus_address(31 downto UART_OFFSET'right) = UART_OFFSET else '0';

  rand_re <= periph_re when bus_address = RAND_ADDR else '0';
  rand_we <= periph_we when bus_address = RAND_ADDR else '0';

  leds <= leds_reg(leds'left downto 0);


  PERIPH_DEBUG : process(clk_50, reset)
  begin
    if reset = '1' then
      periph_din_debug  <= (others => '0');
      periph_dout_debug <= (others => '0');
      periph_re2        <= '0';
      periph_addr_read  <= (others => '0');
      periph_addr_write <= (others => '0');
    elsif rising_edge(clk_50) then
      periph_re2 <= periph_re;
      if periph_we = '1' then
        periph_addr_write <= bus_address;
        periph_din_debug  <= bus_din;
      end if;
      if periph_re = '1' then
        periph_addr_read <= bus_address;
      end if;
      if periph_re2 = '1' then
        periph_dout_debug <= periph_dout;
      end if;
    end if;
  end process PERIPH_DEBUG;

-----------------------------------------------------------------------------
-- Interrupts
-----------------------------------------------------------------------------

  SET_IRQ : process (clk_50, reset)
  begin  -- process SET_IRQ
    if reset = '1' then                 -- asynchronous reset (active high)
      irq_status   <= (others => '0');
      irq_mask     <= (others => '1');
      buttons_reg2 <= (others => '0');
    elsif rising_edge(clk_50) then      -- rising clock edge
      buttons_reg2 <= buttons_reg;
      if buttons_reg(0) = '1' and buttons_reg2(0) = '0' then
        irq_status(0) <= '1';
      end if;

      if periph_we = '1' then
        case bus_address is
          when IRQ_STATUS_CLR_ADDR => irq_status  <= irq_status and not bus_din;
          when IRQ_VECTOR_ADDR     => intr_vector <= bus_din;
          when IRQ_MASK_ADDR       => irq_mask    <= bus_din;
          when IRQ_MASK_CLR_ADDR   => irq_mask    <= irq_mask and not bus_din;
          when IRQ_MASK_SET_ADDR   => irq_mask    <= irq_mask or bus_din;
          when others              =>
        end case;
      end if;
    end if;
  end process SET_IRQ;

  periph_irq <= '1' when irq_status /= X"00000000" else '0';

-------------------------------------------------------------------------------
-- Flash
-------------------------------------------------------------------------------

  FlashMemDq(0) <= flash_dq_out(0) when flash_tris(0) = '0' else 'Z';
  FlashMemDq(1) <= flash_dq_out(1) when flash_tris(1) = '0' else 'Z';
  FlashMemDq(2) <= flash_dq_out(2) when flash_tris(2) = '0' else 'Z';
  FlashMemDq(3) <= flash_dq_out(3) when flash_tris(3) = '0' else 'Z';
  FlashCS       <= Flash_cs;
  FlashCLK      <= Flash_sclk;
  FlashTris     <= flash_tris;

  SET_FLASH : process (clk_50, reset)
  begin  -- process SET_FLASH
    if reset = '1' then                 -- asynchronous reset (active high)
      flash_tris   <= (others => '1');
      flash_dq_out <= (others => '0');
      flash_dq_in  <= (others => '0');
      flash_sclk   <= '0';
      flash_cs     <= '1';
    elsif rising_edge(clk_50) then      -- rising clock edge
      flash_dq_in <= FlashMemDq;
      if periph_we = '1' then
        if bus_address = FLASH_CON_ADDR then
          flash_cs   <= bus_din(1);
          flash_sclk <= bus_din(0);
        elsif bus_address = FLASH_DATA_ADDR then
          flash_dq_out <= bus_din(3 downto 0);
        elsif bus_address = FLASH_TRIS_ADDR then
          flash_tris <= bus_din(3 downto 0);
        end if;
      end if;
    end if;
  end process SET_FLASH;

-------------------------------------------------------------------------------
-- Counters
-------------------------------------------------------------------------------
  DO_COUNTERS : process (clk_50, reset)
  begin  -- process DO_COUNTERS
    if reset = '1' then                 -- asynchronous reset (active high)
      counter1     <= (others => '0');
      counter1_ps  <= (others => '0');
      counter1_psc <= (others => '0');
      counter1_tc  <= (others => '1');
    elsif rising_edge(clk_50) then      -- rising clock edge
      if counter1_psc = counter1_ps then
        counter1_psc <= (others => '0');
        if counter1 = counter1_tc then
          counter1 <= (others => '0');
        else
          counter1 <= counter1 + 1;
        end if;
      else
        counter1_psc <= counter1_psc + 1;
      end if;
      if periph_we = '1' then
        case bus_address is
          when COUNTER1_ADDR    => counter1 <= bus_din;
          when COUNTER1_TC_ADDR =>
            counter1     <= (others => '0');
            counter1_psc <= (others => '0');
            counter1_tc  <= bus_din;
          when COUNTER1_PS_ADDR =>
            counter1     <= (others => '0');
            counter1_psc <= (others => '0');
            counter1_ps  <= bus_din;
          when others => null;
        end case;
      end if;
    end if;
  end process DO_COUNTERS;

  u4_uart : entity work.uartTopLevel
    generic map (
      DEFAULT_DIVIDER => X"07",
      PRESCALE_DIV    => X"35",         -- 50 MHz / 921.6 kHz = 54.
      log_file        => log_file)
    port map (
      clk_uart         => clk_50,
      reset            => reset,
      tx               => uartTx,
      rx               => uartRx,
      sys_clk          => clk_50,
      reg_addr         => bus_address(UART_OFFSET'right-1 downto 2),
      reg_din          => bus_din(7 downto 0),
      reg_dout         => uart_dout,
      reg_we           => uart_we,
      reg_re           => uart_re,
      irq              => uart_irq,
      bypassRx         => Uart_bypassRx,
      bypassRxWeToggle => bypassRxWeToggle_sim,
      bypassTx         => Uart_bypassTx,
      bypassTxDv       => Uart_bypassTxDv);

  u5_leds : entity work.OutputPort
    generic map (
      W => 32)
    port map (
      clk      => clk_50,
      reset    => reset,
      port_o   => leds_reg,
      reg_din  => bus_din,
      reg_we   => leds_we,
      reg_addr => bus_address(LEDS_OFFSET'right-1 downto 2));

  u6_pmod : entity work.BidirPort
    generic map (
      W => pmod'length,
      D => 1)
    port map (
      clk      => clk_50,
      reset    => reset,
      reg_din  => bus_din(pmod'left downto 0),
      reg_we   => pmod_we,
      reg_addr => bus_address(PMOD_OFFSET'right-1 downto 2),
      reg_dout => pmod_reg(pmod'left downto 0),
      port_io  => pmod);


  u7_switches : entity work.InputPort
    generic map (
      W => switches'length,
      D => 8)
    port map (
      clk    => clk_50,
      reset  => reset,
      port_i => switches,
      reg_i  => switches_reg);

  u8_buttons : entity work.InputPort
    generic map (
      W => buttons'length,
      D => 12)
    port map (
      clk    => clk_50,
      reset  => reset,
      port_i => buttons,
      reg_i  => buttons_reg);

  u9_random : entity work.random
    generic map (
      WIDTH => 32)
    port map (
      clk   => clk_50,
      reset => reset,
      dout  => rand_reg,
      we    => rand_we,
      re    => rand_re,
      din   => bus_din);


  SIM : if SIMULATION = '1' generate
    bypassRxWeToggle_sim <= uart_bypassRxWeToggle;
  end generate SIM;


end;  --architecture logic

