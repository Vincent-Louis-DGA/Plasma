-------------------------------------------------------------------------------
-- Attach in between a 32-bit wide bidirectional DDR2 MIG Port and system.
-- System side reads first check the Cache, and if the entry is in there
-- we can save a read from SDRAM.
-- Burst length of all transactions on system side are restricted to 1.
-- (Just like Single Port BlockRAM)
-- Writes essentially pass straight through.
-- Cache is Coherent by routing Write commands to the cache as well if
-- appropriate. 
--
-- Cache is 16 kBits (512 32-bit words), and each read burst is 64 words.
-------------------------------------------------------------------------------
-- Adrian Jongenelen
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity ddr2_cache is
  
  port (
    sys_clk : in std_logic;             -- system clock, eg, 50 MHz
    reset   : in std_logic;

    -- MIG side
    mig_cmd_en        : out std_logic;
    mig_cmd_bl        : out std_logic_vector(5 downto 0);
    mig_cmd_instr     : out std_logic_vector(2 downto 0);
    mig_cmd_byte_addr : out std_logic_vector(29 downto 0);

    mig_wr_data : out std_logic_vector(31 downto 0);
    mig_wr_en   : out std_logic;
    mig_wr_mask : out std_logic_vector(3 downto 0);

    mig_rd_clk   : in  std_logic;       -- DDR clock of read port
    mig_rd_data  : in  std_logic_vector(31 downto 0);
    mig_rd_en    : out std_logic;
    mig_rd_empty : in  std_logic;

    -- System Side
    addr      : in  std_logic_vector(31 downto 0);  -- system side byte address
    din       : in  std_logic_vector(31 downto 0);
    wbe       : in  std_logic_vector(3 downto 0);   -- write byte enable
    en        : in  std_logic;          -- enable. Read = enable when wbe = 0
    dout      : out std_logic_vector(31 downto 0);
    readBusy  : out std_logic;
    hitCount  : out std_logic_vector(31 downto 0);
    readCount : out std_logic_vector(31 downto 0);
    debug : out std_logic_vector(7 downto 0)
    );

end ddr2_cache;

architecture logic of ddr2_cache is

  constant CACHE_WIDTH : integer := 20;
  constant TABLE_WIDTH : integer := 4;
  
  -- sys_clk domain signals
  signal cache_wbe            : std_logic_vector(3 downto 0);
  signal cacheHit             : std_logic;
  signal cache_addr_offset    : std_logic_vector(TABLE_WIDTH-1 downto 0);
  signal prev_addr_offset     : std_logic_vector(TABLE_WIDTH-1 downto 0);
  signal ddr_wbe              : std_logic_vector(3 downto 0);
  signal ddr_wbe2             : std_logic_vector(3 downto 0);
  signal re                   : std_logic;
  signal ddr_re               : std_logic;
  signal ddr_re2              : std_logic;
  signal ddr_hold             : std_logic_vector(2 downto 0);
  signal cache_din            : std_logic_vector(31 downto 0);
  signal cache_dout           : std_logic_vector(31 downto 0);
  signal cache_addr           : std_logic_vector(TABLE_WIDTH+5 downto 0);
  signal insertAddr           : std_logic;
  signal addrToInsert         : std_logic_vector(CACHE_WIDTH-1 downto 0);
  signal busy                 : std_logic;
  signal addr_reg             : std_logic_vector(31 downto 0);
  signal cache_offset_changed : std_logic;

  signal hitCounter  : std_logic_vector(31 downto 0);
  signal readCounter : std_logic_vector(31 downto 0);

  -- mig_rd_clk domain signals
  signal cache_we         : std_logic_vector(3 downto 0);
  signal cache_write_addr : std_logic_vector(TABLE_WIDTH+5 downto 0);
  signal mig_re           : std_logic;
  signal mig_read_busy    : std_logic;
  signal ddr_re_cmd2      : std_logic;
  signal mig_rd_count     : std_logic_vector(7 downto 0);
  signal mig_rd_dout : std_logic_vector(31 downto 0);


  -- domain crossing signals
  signal mig_read_busy_sys : std_logic;
  signal mig_addr_offset   : std_logic_vector(TABLE_WIDTH-1 downto 0);
  signal ddr_re_cmd        : std_logic;

begin  -- logic

  re   <= en when wbe = X"0" else '0';
  busy <= ddr_re2 or (ddr_re and cache_offset_changed)
          or ddr_hold(0) or ddr_hold(1) or mig_read_busy_sys;
  readBusy  <= busy;
  --ddr_re <= en when ddr_wbe = X"0" else '0'; 
  mig_rd_en <= not mig_rd_empty;
  mig_re    <= not mig_rd_empty;

  mig_wr_mask <= not wbe;
  mig_wr_en   <= en when wbe /= X"0" else '0';
  mig_wr_data <= din;

  CACHE_MIG_READ : process (mig_rd_clk, reset)
  begin  -- process CACHE_MIG_WRITE
    if reset = '1' then                 -- asynchronous reset (active high)
      cache_we         <= (others => '0');
      cache_write_addr <= (others => '0');
      mig_read_busy    <= '0';
      mig_rd_count     <= (others => '0');
      mig_rd_dout <= (others => '0');
    elsif rising_edge(mig_rd_clk) then  -- rising clock edge
      if ddr_re_cmd = '1' and ddr_re_cmd2 = '0' then
        mig_read_busy <= '1';
        mig_rd_count  <= (others => '0');
      end if;
      if mig_rd_count = X"40" then
        mig_read_busy <= '0';
      end if;
      if mig_re = '1' then
        cache_we     <= X"F";
        mig_rd_count <= mig_rd_count + 1;
      else
        cache_we <= X"0";
      end if;
      if mig_read_busy = '0' then
        mig_rd_count <= (others => '0');
      end if;
      cache_write_addr <= mig_addr_offset & mig_rd_count(5 downto 0);
      mig_rd_dout <= mig_rd_data;
    end if;
  end process CACHE_MIG_READ;

  MIG_COMMANDS : process (sys_clk, reset)
  begin  -- process MIG_COMMANDS
    if reset = '1' then                 -- asynchronous reset (active high)
      mig_cmd_en        <= '0';
      mig_cmd_bl        <= "000000";
      mig_cmd_instr     <= "000";
      mig_cmd_byte_addr <= (others => '0');
      addr_reg          <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      mig_cmd_en        <= '0';
      mig_cmd_bl        <= "000000";
      mig_cmd_byte_addr <= addr_reg(29 downto 0);
      mig_cmd_instr     <= "000";
      addr_reg          <= addr;
      if ddr_re2 = '1' then
        mig_cmd_bl        <= "111111";
        mig_cmd_en        <= '1';
        mig_cmd_byte_addr <= addr_reg(29 downto 8) & "00000000";
        mig_cmd_instr     <= "001";
      end if;
      if ddr_wbe /= X"0" then
        mig_cmd_en <= '1';
      end if;
    end if;
  end process MIG_COMMANDS;

  CACHE_AND_MIG_WRITE : process (sys_clk, reset)
  begin  -- process MIG_WRITE
    if reset = '1' then                 -- asynchronous reset (active high)
      ddr_wbe          <= (others => '0');
      ddr_wbe2         <= (others => '0');
      ddr_re           <= '0';
      cache_din        <= (others => '0');
      addrToInsert     <= (others => '0');
      prev_addr_offset <= (others => '0');
      ddr_hold         <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      ddr_wbe          <= wbe;
      ddr_wbe2         <= ddr_wbe;
      cache_din        <= din;
      addrToInsert     <= addr(CACHE_WIDTH+7 downto 8);
      ddr_re           <= re;
      prev_addr_offset <= cache_addr_offset;
      ddr_hold         <= ddr_hold(ddr_hold'left-1 downto 0) & ddr_re2;
    end if;
  end process CACHE_AND_MIG_WRITE;

  cache_offset_changed <= '1'     when prev_addr_offset /= cache_addr_offset else '0';
  cache_wbe            <= ddr_wbe when cacheHit = '1'                        else X"0";
  cache_addr           <= cache_addr_offset & addr(7 downto 2);
  insertAddr           <= ddr_re  when cacheHit = '0'                        else '0';
  ddr_re2              <= insertAddr;
  dout                 <= cache_dout;

  CROSS_MIG_TO_SYS : process (sys_clk, reset)
  begin  -- process CROSS_MIG_TO_SYS
    if reset = '1' then                 -- asynchronous reset (active high)
      mig_read_busy_sys <= '0';
    elsif rising_edge(sys_clk) then     -- rising clock edge
      mig_read_busy_sys <= mig_read_busy;
    end if;
  end process CROSS_MIG_TO_SYS;

  CROSS_SYS_TO_MIG : process (mig_rd_clk, reset)
  begin  -- process CROSS_SYS_TO_MIG
    if reset = '1' then                 -- asynchronous reset (active high)
      mig_addr_offset <= (others => '0');
      ddr_re_cmd      <= '0';
      ddr_re_cmd2     <= '0';
    elsif rising_edge(mig_rd_clk) then  -- rising clock edge
      mig_addr_offset <= cache_addr_offset;
      ddr_re_cmd      <= ddr_re2;
      ddr_re_cmd2     <= ddr_re_cmd;
    end if;
  end process CROSS_SYS_TO_MIG;

  STATS : process (sys_clk, reset)
  begin  -- process STATS
    if reset = '1' then                 -- asynchronous reset (active high)
      hitCounter  <= (others => '0');
      readCounter <= (others => '0');
    elsif rising_edge(sys_clk) then     -- rising clock edge
      if ddr_re = '1' then
        readCounter <= readCounter + 1;
        if cacheHit = '1' then
          hitCounter <= hitCounter + 1;
        end if;
      end if;
    end if;
  end process STATS;

  hitCount  <= hitCounter;
  readCount <= readCounter;

  debug <= mig_rd_dout(3 downto 0) & cache_write_addr(3 downto 0);

  u1_cache : entity work.dualRamMx8N
    generic map (
      N => 4,
      M => TABLE_WIDTH+6)
    port map (
      clka   => sys_clk,
      wea    => cache_wbe,
      addra  => cache_addr,
      dina   => cache_din,
      raddra => cache_addr,
      douta  => cache_dout,
      clkb   => mig_rd_clk,
      web    => cache_we,
      addrb  => cache_write_addr,
      dinb   => mig_rd_dout,
      raddrb => cache_write_addr,
      doutb  => open
      );

  u2_cacheTable : entity work.cache_table
    generic map (
      TABLE_WIDTH => TABLE_WIDTH,
      ADDR_WIDTH  => CACHE_WIDTH)
    port map (
      clk          => sys_clk,
      reset        => reset,
      addrToFind   => addr(CACHE_WIDTH+7 downto 8),
      cacheHit     => cacheHit,
      foundAddress => cache_addr_offset,
      insertAddr   => insertAddr,
      addrToInsert => addrToInsert);

end logic;
