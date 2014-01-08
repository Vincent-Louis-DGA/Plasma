-------------------------------------------------------------------------------
-- A simplified DDR2 RAM Wrapper model to speed up simulations.
-- Doesn't have any External RAM connecting signals, it stores everything
-- internally.
--
-- NOT SUITABLE for synthesis/implementation
-- (mostly because of improper/careless clock domain crossing)
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.txt_util.all;

entity atlys_ddr2_sim_model is
  
  port (
    c3_sys_clk          : in  std_logic;
    c3_sys_rst_i        : in  std_logic;
    c3_calib_done       : out std_logic;
    c3_clk4             : out std_logic;
    c3_clk0             : out std_logic;
    c3_rst0             : out std_logic;
    clk_mem             : out std_logic;
    c3_p0_cmd_clk       : in  std_logic;
    c3_p0_cmd_en        : in  std_logic;
    c3_p0_cmd_instr     : in  std_logic_vector(2 downto 0);
    c3_p0_cmd_bl        : in  std_logic_vector(5 downto 0);
    c3_p0_cmd_byte_addr : in  std_logic_vector(29 downto 0);
    c3_p0_wr_clk        : in  std_logic;
    c3_p0_wr_en         : in  std_logic;
    c3_p0_wr_mask       : in  std_logic_vector(3 downto 0);
    c3_p0_wr_data       : in  std_logic_vector(31 downto 0);
    c3_p0_wr_full       : out std_logic;
    c3_p0_wr_empty      : out std_logic;
    c3_p0_wr_count      : out std_logic_vector(6 downto 0);
    c3_p0_rd_clk        : in  std_logic;
    c3_p0_rd_en         : in  std_logic;
    c3_p0_rd_data       : out std_logic_vector(31 downto 0);
    c3_p0_rd_empty      : out std_logic;
    c3_p0_rd_full       : out std_logic;
    c3_p0_rd_count      : out std_logic_vector(6 downto 0);

    c3_p1_cmd_clk       : in  std_logic;
    c3_p1_cmd_en        : in  std_logic                     := '0';
    c3_p1_cmd_instr     : in  std_logic_vector(2 downto 0)  := "000";
    c3_p1_cmd_bl        : in  std_logic_vector(5 downto 0)  := "000000";
    c3_p1_cmd_byte_addr : in  std_logic_vector(29 downto 0) := "00" & X"0000000";
    c3_p1_wr_clk        : in  std_logic;
    c3_p1_wr_en         : in  std_logic                     := '0';
    c3_p1_wr_mask       : in  std_logic_vector(3 downto 0)  := X"F";
    c3_p1_wr_data       : in  std_logic_vector(31 downto 0) := X"00000000";
    c3_p1_wr_full       : out std_logic;
    c3_p1_wr_empty      : out std_logic;
    c3_p1_wr_count      : out std_logic_vector(6 downto 0);
    c3_p1_rd_clk        : in  std_logic;
    c3_p1_rd_en         : in  std_logic                     := '0';
    c3_p1_rd_data       : out std_logic_vector(31 downto 0);
    c3_p1_rd_empty      : out std_logic;
    c3_p1_rd_full       : out std_logic;
    c3_p1_rd_count      : out std_logic_vector(6 downto 0));

end atlys_ddr2_sim_model;

architecture model of atlys_ddr2_sim_model is

  signal resetCount : std_logic_vector(3 downto 0);
  signal clk50      : std_logic;
  signal clk125 : std_logic := '0';
  signal mem_clk    : std_logic := '0';
  signal reset      : std_logic;

  signal cmd0_eni : std_logic;
  signal cmd0_en  : std_logic;
  signal cmd1_eni : std_logic;
  signal cmd1_en  : std_logic;

  signal wf0_din   : std_logic_vector(39 downto 0);
  signal wf0_dout  : std_logic_vector(39 downto 0);
  signal wf0_empty : std_logic;
  signal wf0_re    : std_logic;
  signal wf0_bl    : std_logic_vector(6 downto 0);
  signal wf0_bl2   : std_logic_vector(6 downto 0);
  signal wf0_cnt   : std_logic_vector(5 downto 0);
  signal wf0_addr  : std_logic_vector(9 downto 0);
  signal wf0_we    : std_logic;
  signal wf0_wbe   : std_logic_vector(3 downto 0);

  signal wf1_din   : std_logic_vector(39 downto 0);
  signal wf1_dout  : std_logic_vector(39 downto 0);
  signal wf1_empty : std_logic;
  signal wf1_re    : std_logic;
  signal wf1_bl    : std_logic_vector(6 downto 0);
  signal wf1_bl2   : std_logic_vector(6 downto 0);
  signal wf1_cnt   : std_logic_vector(5 downto 0);
  signal wf1_addr  : std_logic_vector(9 downto 0);
  signal wf1_we    : std_logic;
  signal wf1_wbe   : std_logic_vector(3 downto 0);

  signal rf0_din  : std_logic_vector(31 downto 0);
  signal rf0_addr : std_logic_vector(9 downto 0);
  signal rf0_bl   : std_logic_vector(6 downto 0);
  signal rf0_re   : std_logic;
  signal rf0_we   : std_logic;

  signal rf1_din  : std_logic_vector(31 downto 0);
  signal rf1_addr : std_logic_vector(9 downto 0);
  signal rf1_bl   : std_logic_vector(6 downto 0);
  signal rf1_re   : std_logic;
  signal rf1_we   : std_logic;
  
begin  -- model

  clk125 <= not clk125 after 4 ns;
  c3_clk4 <= clk125;
  clk_mem <= mem_clk;
  c3_rst0 <= reset;
  c3_clk0 <= clk50;
  DO_RESET : process (c3_sys_clk, c3_sys_rst_i)
  begin  -- process DO_RESET
    if c3_sys_rst_i = '1' then          -- asynchronous reset (active high)
      resetCount    <= (others => '0');
      reset         <= '1';
      clk50         <= '0';
      c3_calib_done <= '0';
    elsif rising_edge(c3_sys_clk) then  -- rising clock edge
      clk50         <= not clk50;
      c3_calib_done <= not reset;
      if resetCount /= X"F" then
        resetCount <= resetCount + 1;
        reset      <= '1';
      else
        reset <= '0';
      end if;
    end if;
  end process DO_RESET;


  p0_WriteFifo : entity work.fifo64x8N
    generic map (
      N => 5)
    port map (
      rst           => reset,
      wr_clk        => c3_p0_wr_clk,
      rd_clk        => mem_clk,
      din           => wf0_din,
      wr_en         => c3_p0_wr_en,
      rd_en         => wf0_re,
      dout          => wf0_dout,
      full          => c3_p0_wr_full,
      empty         => wf0_empty,
      wr_data_count => wf0_cnt);

  p1_WriteFifo : entity work.fifo64x8N
    generic map (
      N => 5)
    port map (
      rst           => reset,
      wr_clk        => c3_p1_wr_clk,
      rd_clk        => mem_clk,
      din           => wf1_din,
      wr_en         => c3_p1_wr_en,
      rd_en         => wf1_re,
      dout          => wf1_dout,
      full          => c3_p1_wr_full,
      empty         => wf1_empty,
      wr_data_count => wf1_cnt);

  p0_ReadFifo : entity work.fifo64x8N
    generic map (
      N            => 4,
      FALL_THROUGH => '1')
    port map (
      rst           => reset,
      wr_clk        => mem_clk,
      rd_clk        => c3_p0_rd_clk,
      din           => rf0_din,
      wr_en         => rf0_we,
      rd_en         => c3_p0_rd_en,
      dout          => c3_p0_rd_data,
      full          => c3_p0_rd_full,
      empty         => c3_p0_rd_empty,
      rd_data_count => c3_p0_rd_count(5 downto 0));

  p1_ReadFifo : entity work.fifo64x8N
    generic map (
      N            => 4,
      FALL_THROUGH => '1')
    port map (
      rst           => reset,
      wr_clk        => mem_clk,
      rd_clk        => c3_p1_rd_clk,
      din           => rf1_din,
      wr_en         => rf1_we,
      rd_en         => c3_p1_rd_en,
      dout          => c3_p1_rd_data,
      full          => c3_p1_rd_full,
      empty         => c3_p1_rd_empty,
      rd_data_count => c3_p1_rd_count(5 downto 0));

  c3_p0_wr_count <= '0' & wf0_cnt;
  wf0_din        <= X"0" & c3_p0_wr_mask & c3_p0_wr_data;
  c3_p1_wr_count <= '0' & wf1_cnt;
  wf1_din        <= X"0" & c3_p1_wr_mask & c3_p1_wr_data;

  c3_p0_wr_empty <= wf0_empty;
  c3_p1_wr_empty <= wf1_empty;          --'1' when wf1_cnt = "000000" else '0';

  c3_p0_rd_count(6) <= '0';
  c3_p1_rd_count(6) <= '0';

  FIFO_CON100 : process (mem_clk, reset)
  begin  -- process FIFO_CON100
    if reset = '1' then                 -- asynchronous reset (active high)
      cmd0_eni <= '0';
      cmd0_en  <= '0';
      cmd1_eni <= '0';
      cmd1_en  <= '0';
      wf0_re   <= '0';
      wf0_bl   <= (others => '0');
      wf0_bl2  <= (others => '0');
      wf0_addr <= (others => '1');
      wf0_we   <= '0';
      wf1_re   <= '0';
      wf1_bl   <= (others => '0');
      wf1_bl2  <= (others => '0');
      wf1_addr <= (others => '1');
      wf1_we   <= '0';
      rf0_addr <= (others => '1');
      rf0_bl   <= (others => '0');
      rf0_re   <= '0';
      rf0_we   <= '0';
      rf1_addr <= (others => '1');
      rf1_bl   <= (others => '0');
      rf1_re   <= '0';
      rf1_we   <= '0';
    elsif rising_edge(mem_clk) then     -- rising clock edge
      -- Write Port 0
      wf0_re   <= '0';
      cmd0_eni <= c3_p0_cmd_en;
      cmd0_en  <= '0';
      if cmd0_eni = '0' and c3_p0_cmd_en = '1' then
        cmd0_en <= '1';
      end if;
      wf0_bl2 <= (others => '0');
      if cmd0_en = '1' and c3_p0_cmd_instr(0) = '0' then
        wf0_bl2 <= wf0_bl2(5 downto 0) & '1';  --'1' & c3_p0_cmd_bl;
      else
        wf0_bl2 <= wf0_bl2(5 downto 0) & '0';
      end if;
      if wf0_bl2(1) = '1' then
        wf0_bl   <= ('0' & c3_p0_cmd_bl) + 1;
        wf0_addr <= c3_p0_cmd_byte_addr(11 downto 2);
      end if;
      if wf0_bl /= "000000" then
        wf0_re <= '1';
        wf0_bl <= wf0_bl - 1;
      end if;
      wf0_we <= wf0_re;
      if wf0_we = '1' then
        --report "RAM Model: WRITE Port 0 @ " & hstr(wf0_addr) & " = " & hstr(wf0_dout);
        wf0_addr <= wf0_addr + 1;
      end if;

      -- Write Port 1
      wf1_re   <= '0';
      cmd1_eni <= c3_p1_cmd_en;
      cmd1_en  <= '0';
      if cmd1_eni = '0' and c3_p1_cmd_en = '1' then
        cmd1_en <= '1';
      end if;

      if cmd1_en = '1' and c3_p1_cmd_instr(0) = '0' then
        wf1_bl2 <= wf1_bl2(5 downto 0) & '1';  --'1' & c3_p0_cmd_bl;
      else
        wf1_bl2 <= wf1_bl2(5 downto 0) & '0';
      end if;
      if wf1_bl2(1) = '1' then
        wf1_bl   <= ('0' & c3_p1_cmd_bl) + 1;
        wf1_addr <= c3_p1_cmd_byte_addr(11 downto 2);
      end if;
      if wf1_bl /= "000000" then
        wf1_re <= '1';
        wf1_bl <= wf1_bl - 1;
      end if;
      wf1_we <= wf1_re;
      if wf1_we = '1' then
        --report "RAM Model: WRITE Port 1 @ " & hstr(wf1_addr) & " = " & hstr(wf1_dout);
        wf1_addr <= wf1_addr + 1;
      end if;

      -- Read Port 0
      rf0_re <= '0';
      rf0_we <= rf0_re;
      if cmd0_en = '1' and c3_p0_cmd_instr(0) = '1' then
        rf0_bl   <= ('0' & c3_p0_cmd_bl);
        rf0_addr <= c3_p0_cmd_byte_addr(11 downto 2);
        rf0_re   <= '1';
      end if;
      if rf0_bl /= "000000" then
        rf0_addr <= rf0_addr + 1;
        rf0_bl   <= rf0_bl - 1;
        rf0_re   <= '1';
      end if;

      -- Read Port 1
      rf1_re <= '0';
      rf1_we <= rf1_re;
      if cmd1_en = '1' and c3_p1_cmd_instr(0) = '1' then
        rf1_bl   <= ('0' & c3_p1_cmd_bl);
        rf1_addr <= c3_p1_cmd_byte_addr(11 downto 2);
        rf1_re   <= '1';
      end if;
      if rf1_bl /= "000000" then
        rf1_addr <= rf1_addr + 1;
        rf1_bl   <= rf1_bl - 1;
        rf1_re   <= '1';
      end if;
    end if;
  end process FIFO_CON100;
  wf1_wbe <= X"0" when wf1_we = '0' else not wf1_dout(35 downto 32);
  wf0_wbe <= X"0" when wf0_we = '0' else not wf0_dout(35 downto 32);


  ram : entity work.dualRamMx8N
    generic map (
      N          => 4,
      M          => 10,
      SIMULATION => '1')
    port map (
      clka   => mem_clk,
      wea    => wf0_wbe,
      addra  => wf0_addr,
      dina   => wf0_dout(31 downto 0),
      raddra => rf0_addr,
      douta  => rf0_din,
      clkb   => mem_clk,
      web    => wf1_wbe,
      addrb  => wf1_addr,
      dinb   => wf1_dout(31 downto 0),
      raddrb => rf1_addr,
      doutb  => rf1_din);

  mem_clk <= not mem_clk after 1.67 ns;

end model;
