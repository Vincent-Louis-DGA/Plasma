----------------------------------------------------------------------------------
-- Wrapper for DD2 1Gb 64Mx16 part on ATLYS board.
--
-- Makes available one 32-bit wide fully functional bidirectional interface
-- that includes full cmd, wr, rd fifo access.
--
-- Simplifies two 32-bit ports to be fixed as read and write mode, burst length
-- of 1, hopefully fixed read latency.
-- Major flaw with the read path: pipelining isn't implemented. I know! Horrible!
-- This means that initiating a read while rd32_busy will fail or be ignored.
-- 
--
-- All user ports operate on the same clock, which is 50 MHz.
-- RAM running at 300 MHz.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.GeneralPurposeFunctions.all;
use work.txt_util.all;

entity ddr2_1Gb_wrapper is
  generic (
    DO_SIMULATION : std_logic := '0');
  port (clk100  : in  std_logic;        -- from pin
        reset_n : in  std_logic;        -- from pin
        clk_50   : out std_logic;        -- sys_clk
        clk_125 : out std_logic;        -- 125 MHz clk for ethernet
        clk_mem : out std_logic;        -- memory clock
        reset   : out std_logic;        -- active high sys_reset

        -- To DDR2 device pins
        mcb3_dram_dq     : inout std_logic_vector(15 downto 0);
        mcb3_dram_a      : out   std_logic_vector(12 downto 0);
        mcb3_dram_ba     : out   std_logic_vector(2 downto 0);
        mcb3_dram_ras_n  : out   std_logic;
        mcb3_dram_cas_n  : out   std_logic;
        mcb3_dram_we_n   : out   std_logic;
        mcb3_dram_odt    : out   std_logic;
        mcb3_dram_cke    : out   std_logic;
        mcb3_dram_dm     : out   std_logic;
        mcb3_dram_udqs   : inout std_logic;
        mcb3_dram_udqs_n : inout std_logic;
        mcb3_rzq         : inout std_logic;
        mcb3_zio         : inout std_logic;
        mcb3_dram_udm    : out   std_logic;
        mcb3_dram_dqs    : inout std_logic;
        mcb3_dram_dqs_n  : inout std_logic;
        mcb3_dram_ck     : out   std_logic;
        mcb3_dram_ck_n   : out   std_logic;

        -- To user design (32-bit port is raw MIG interface width)
        calib_done : out std_logic;

        -- Inital values mean these can be left unconnected.
        cmd_0_clk       : in  std_logic                     := '0';
        cmd_0_en        : in  std_logic                     := '0';
        cmd_0_instr     : in  std_logic_vector(2 downto 0)  := "000";
        cmd_0_bl        : in  std_logic_vector(5 downto 0)  := "000000";
        cmd_0_byte_addr : in  std_logic_vector(29 downto 0) := (X"0000000" & "00");
        cmd_0_empty     : out std_logic;
        cmd_0_full      : out std_logic;
        wr_0_clk        : in  std_logic                     := '0';
        wr_0_en         : in  std_logic                     := '0';
        wr_0_mask       : in  std_logic_vector(3 downto 0)  := X"0";
        wr_0_data       : in  std_logic_vector(31 downto 0) := X"00000000";
        wr_0_full       : out std_logic;
        wr_0_empty      : out std_logic;
        wr_0_count      : out std_logic_vector(6 downto 0);
        wr_0_underrun   : out std_logic;
        wr_0_error      : out std_logic;
        rd_0_clk        : in  std_logic                     := '0';
        rd_0_en         : in  std_logic                     := '0';
        rd_0_data       : out std_logic_vector(31 downto 0);
        rd_0_full       : out std_logic;
        rd_0_empty      : out std_logic;
        rd_0_count      : out std_logic_vector(6 downto 0);
        rd_0_overflow   : out std_logic;
        rd_0_error      : out std_logic;

        -- Inital values mean these can be left unconnected.
        cmd_1_clk       : in  std_logic                     := '0';
        cmd_1_en        : in  std_logic                     := '0';
        cmd_1_instr     : in  std_logic_vector(2 downto 0)  := "000";
        cmd_1_bl        : in  std_logic_vector(5 downto 0)  := "000000";
        cmd_1_byte_addr : in  std_logic_vector(29 downto 0) := (X"0000000" & "00");
        cmd_1_empty     : out std_logic;
        cmd_1_full      : out std_logic;
        wr_1_clk        : in  std_logic                     := '0';
        wr_1_en         : in  std_logic                     := '0';
        wr_1_mask       : in  std_logic_vector(3 downto 0)  := X"0";
        wr_1_data       : in  std_logic_vector(31 downto 0) := X"00000000";
        wr_1_full       : out std_logic;
        wr_1_empty      : out std_logic;
        wr_1_count      : out std_logic_vector(6 downto 0);
        wr_1_underrun   : out std_logic;
        wr_1_error      : out std_logic;
        rd_1_clk        : in  std_logic                     := '0';
        rd_1_en         : in  std_logic                     := '0';
        rd_1_data       : out std_logic_vector(31 downto 0);
        rd_1_full       : out std_logic;
        rd_1_empty      : out std_logic;
        rd_1_count      : out std_logic_vector(6 downto 0);
        rd_1_overflow   : out std_logic;
        rd_1_error      : out std_logic;

        -- Inital values mean these can be left unconnected.
        cmd_2_clk       : in  std_logic                     := '0';
        cmd_2_en        : in  std_logic                     := '0';
        cmd_2_instr     : in  std_logic_vector(2 downto 0)  := "000";
        cmd_2_bl        : in  std_logic_vector(5 downto 0)  := "000000";
        cmd_2_byte_addr : in  std_logic_vector(29 downto 0) := (X"0000000" & "00");
        cmd_2_empty     : out std_logic;
        cmd_2_full      : out std_logic;
        wr_2_clk        : in  std_logic                     := '0';
        wr_2_en         : in  std_logic                     := '0';
        wr_2_mask       : in  std_logic_vector(3 downto 0)  := X"0";
        wr_2_data       : in  std_logic_vector(31 downto 0) := X"00000000";
        wr_2_full       : out std_logic;
        wr_2_empty      : out std_logic;
        wr_2_count      : out std_logic_vector(6 downto 0);
        wr_2_underrun   : out std_logic;
        wr_2_error      : out std_logic;
        rd_2_clk        : in  std_logic                     := '0';
        rd_2_en         : in  std_logic                     := '0';
        rd_2_data       : out std_logic_vector(31 downto 0);
        rd_2_full       : out std_logic;
        rd_2_empty      : out std_logic;
        rd_2_count      : out std_logic_vector(6 downto 0);
        rd_2_overflow   : out std_logic;
        rd_2_error      : out std_logic
        );
end ddr2_1Gb_wrapper;

architecture Behavioral of ddr2_1Gb_wrapper is

  signal c3_sys_rst_i : std_logic;
  signal reset_i      : std_logic;
  signal calib_done_i : std_logic;

  
begin

  c3_sys_rst_i <= not reset_n;
  reset        <= reset_i or not calib_done_i;
  calib_done   <= calib_done_i;

  SIMULATING : if DO_SIMULATION = '1' generate

    u0_sdram_model : entity work.atlys_ddr2_sim_model
      port map (
        c3_sys_clk    => clk100,
        c3_sys_rst_i  => c3_sys_rst_i,
        c3_calib_done => calib_done_i,
        c3_clk0       => clk_50,
        c3_rst0       => reset_i,
        clk_mem       => clk_mem,

        -- 32 bit bidirectional port 0
        c3_p0_cmd_clk       => cmd_0_clk,
        c3_p0_cmd_en        => cmd_0_en,
        c3_p0_cmd_instr     => cmd_0_instr,
        c3_p0_cmd_bl        => cmd_0_bl,
        c3_p0_cmd_byte_addr => cmd_0_byte_addr,
        c3_p0_wr_clk        => wr_0_clk,
        c3_p0_wr_en         => wr_0_en,
        c3_p0_wr_mask       => wr_0_mask,
        c3_p0_wr_data       => wr_0_data,
        c3_p0_wr_full       => wr_0_full,
        c3_p0_wr_empty      => wr_0_empty,
        c3_p0_wr_count      => wr_0_count,
        c3_p0_rd_clk        => rd_0_clk,
        c3_p0_rd_en         => rd_0_en,
        c3_p0_rd_data       => rd_0_data,
        c3_p0_rd_full       => rd_0_full,
        c3_p0_rd_empty      => rd_0_empty,
        c3_p0_rd_count      => rd_0_count,

        -- 32 bit bidirectional port 
        c3_p1_cmd_clk       => cmd_1_clk,
        c3_p1_cmd_en        => cmd_1_en,
        c3_p1_cmd_instr     => cmd_1_instr,
        c3_p1_cmd_bl        => cmd_1_bl,
        c3_p1_cmd_byte_addr => cmd_1_byte_addr,
        c3_p1_wr_clk        => wr_1_clk,
        c3_p1_wr_en         => wr_1_en,
        c3_p1_wr_mask       => wr_1_mask,
        c3_p1_wr_data       => wr_1_data,
        c3_p1_wr_full       => wr_1_full,
        c3_p1_wr_empty      => wr_1_empty,
        c3_p1_wr_count      => wr_1_count,
        c3_p1_rd_clk        => rd_1_clk,
        c3_p1_rd_en         => rd_1_en,
        c3_p1_rd_data       => rd_1_data,
        c3_p1_rd_full       => rd_1_full,
        c3_p1_rd_empty      => rd_1_empty,
        c3_p1_rd_count      => rd_1_count
        );

    cmd_0_full  <= '0';
    cmd_0_empty <= '1';
    cmd_1_full  <= '0';
    cmd_1_empty <= '1';

  end generate SIMULATING;


  NOT_SIM : if DO_SIMULATION /= '1' generate
    

    u1_sdram : entity work.atlys_ddr2
      generic map (
        C3_CALIB_SOFT_IP => "TRUE",
        C3_SIMULATION    => "FALSE")
      port map (
        mcb3_dram_dq     => mcb3_dram_dq,
        mcb3_dram_a      => mcb3_dram_a,
        mcb3_dram_ba     => mcb3_dram_ba,
        mcb3_dram_ras_n  => mcb3_dram_ras_n,
        mcb3_dram_cas_n  => mcb3_dram_cas_n,
        mcb3_dram_we_n   => mcb3_dram_we_n,
        mcb3_dram_odt    => mcb3_dram_odt,
        mcb3_dram_cke    => mcb3_dram_cke,
        mcb3_dram_dm     => mcb3_dram_dm,
        mcb3_dram_udqs   => mcb3_dram_udqs,
        mcb3_dram_udqs_n => mcb3_dram_udqs_n,
        mcb3_rzq         => mcb3_rzq,
        mcb3_zio         => mcb3_zio,
        c3_sys_clk       => clk100,
        c3_sys_rst_i     => c3_sys_rst_i,
        c3_calib_done    => calib_done_i,
        c3_clk0          => clk_50,
        c3_rst0          => reset_i,
        clk_mem          => clk_mem,
        mcb3_dram_udm    => mcb3_dram_udm,
        mcb3_dram_dqs    => mcb3_dram_dqs,
        mcb3_dram_dqs_n  => mcb3_dram_dqs_n,
        mcb3_dram_ck     => mcb3_dram_ck,
        mcb3_dram_ck_n   => mcb3_dram_ck_n,

        -- 32 bit bidirectional port 0
        c3_p0_cmd_clk       => cmd_0_clk,
        c3_p0_cmd_en        => cmd_0_en,
        c3_p0_cmd_instr     => cmd_0_instr,
        c3_p0_cmd_bl        => cmd_0_bl,
        c3_p0_cmd_byte_addr => cmd_0_byte_addr,
        c3_p0_cmd_empty     => cmd_0_empty,
        c3_p0_cmd_full      => cmd_0_full,
        c3_p0_wr_clk        => wr_0_clk,
        c3_p0_wr_en         => wr_0_en,
        c3_p0_wr_mask       => wr_0_mask,
        c3_p0_wr_data       => wr_0_data,
        c3_p0_wr_full       => wr_0_full,
        c3_p0_wr_empty      => wr_0_empty,
        c3_p0_wr_count      => wr_0_count,
        c3_p0_wr_underrun   => wr_0_underrun,
        c3_p0_wr_error      => wr_0_error,
        c3_p0_rd_clk        => rd_0_clk,
        c3_p0_rd_en         => rd_0_en,
        c3_p0_rd_data       => rd_0_data,
        c3_p0_rd_full       => rd_0_full,
        c3_p0_rd_empty      => rd_0_empty,
        c3_p0_rd_count      => rd_0_count,
        c3_p0_rd_overflow   => rd_0_overflow,
        c3_p0_rd_error      => rd_0_error,
        -- 32 bit bidirectional port 1
        c3_p1_cmd_clk       => cmd_1_clk,
        c3_p1_cmd_en        => cmd_1_en,
        c3_p1_cmd_instr     => cmd_1_instr,
        c3_p1_cmd_bl        => cmd_1_bl,
        c3_p1_cmd_byte_addr => cmd_1_byte_addr,
        c3_p1_cmd_empty     => cmd_1_empty,
        c3_p1_cmd_full      => cmd_1_full,
        c3_p1_wr_clk        => wr_1_clk,
        c3_p1_wr_en         => wr_1_en,
        c3_p1_wr_mask       => wr_1_mask,
        c3_p1_wr_data       => wr_1_data,
        c3_p1_wr_full       => wr_1_full,
        c3_p1_wr_empty      => wr_1_empty,
        c3_p1_wr_count      => wr_1_count,
        c3_p1_wr_underrun   => wr_1_underrun,
        c3_p1_wr_error      => wr_1_error,
        c3_p1_rd_clk        => rd_1_clk,
        c3_p1_rd_en         => rd_1_en,
        c3_p1_rd_data       => rd_1_data,
        c3_p1_rd_full       => rd_1_full,
        c3_p1_rd_empty      => rd_1_empty,
        c3_p1_rd_count      => rd_1_count,
        c3_p1_rd_overflow   => rd_1_overflow,
        c3_p1_rd_error      => rd_1_error,
        -- 32 bit bidirectional port 2
        c3_p2_cmd_clk       => cmd_2_clk,
        c3_p2_cmd_en        => cmd_2_en,
        c3_p2_cmd_instr     => cmd_2_instr,
        c3_p2_cmd_bl        => cmd_2_bl,
        c3_p2_cmd_byte_addr => cmd_2_byte_addr,
        c3_p2_cmd_empty     => cmd_2_empty,
        c3_p2_cmd_full      => cmd_2_full,
        c3_p2_wr_clk        => wr_2_clk,
        c3_p2_wr_en         => wr_2_en,
        c3_p2_wr_mask       => wr_2_mask,
        c3_p2_wr_data       => wr_2_data,
        c3_p2_wr_full       => wr_2_full,
        c3_p2_wr_empty      => wr_2_empty,
        c3_p2_wr_count      => wr_2_count,
        c3_p2_wr_underrun   => wr_2_underrun,
        c3_p2_wr_error      => wr_2_error,
        c3_p2_rd_clk        => rd_2_clk,
        c3_p2_rd_en         => rd_2_en,
        c3_p2_rd_data       => rd_2_data,
        c3_p2_rd_full       => rd_2_full,
        c3_p2_rd_empty      => rd_2_empty,
        c3_p2_rd_count      => rd_2_count,
        c3_p2_rd_overflow   => rd_2_overflow,
        c3_p2_rd_error      => rd_2_error);

  end generate NOT_SIM;



end Behavioral;

