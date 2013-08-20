---------------------------------------------------------------------
-- TITLE: Random Access Memory for Xilinx
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 11/06/05
-- FILENAME: ram_xilinx.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the RAM for Spartan 3 Xilinx FPGA
--
--    Compile the MIPS C and assembly code into "text.exe".
--    Run convert.exe to change "text.exe" to "code.txt" which
--    will contain the hex values of the opcodes.
--    Next run "run_image ram_xilinx.vhd code.txt ram_image.vhd",
--    to create the "ram_image.vhd" file that will have the opcodes
--    corectly placed inside the INIT_00 => strings.
--    Then include ram_image.vhd in the simulation/synthesis.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.mlite_pack.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity ram_PlasmaBootLoader is
   generic(memory_type : string := "DEFAULT");
   port(clk               : in std_logic;
        enable            : in std_logic;
        write_byte_enable : in std_logic_vector(3 downto 0);
        address           : in std_logic_vector(31 downto 2);
        data_write        : in std_logic_vector(31 downto 0);
        data_read         : out std_logic_vector(31 downto 0));
end; --entity ram

architecture logic of ram_PlasmaBootLoader is
begin

   RAMB16_S9_inst0 : RAMB16_S9
   generic map (
INIT_00 => X"afafafafafafafafaf23ac033c08000cac3c243c241400ac273c243c243c273c",
INIT_01 => X"8f8f8f8f8f8f8f8f8f2300008c8c8c3caf00af00af2340afafafafafafafafaf",
INIT_02 => X"acacacacacacacacacacac40034040033423038f038f8f8f8f8f8f8f8f8f8f8f",
INIT_03 => X"ac303c00100090000300ac0300000034038c8c8c8c8c8c8c8c8c8c8c8c3403ac",
INIT_04 => X"02260c9002001a0000afafafaf272703008f240c3c000caf2700030014009024",
INIT_05 => X"8c343c0003001400a024008c001030008d343c353c001827038f8f8f8f020214",
INIT_06 => X"ac033c001430008c343c301030008c343c30038c343c1030008c343c3c143000",
INIT_07 => X"8f8f02142a26ae0000000c3c0200afafafaf270003ac03343cac24343cac343c",
INIT_08 => X"ae00000c00ae0002ae0c003c0cae24363cac24343cafafafafafaf2727038f8f",
INIT_09 => X"af0000ae008f000caf0000ae008f000caf0000008fae00ae0c0000ae00000c00",
INIT_0A => X"8fac0c24343c00140226ac00aeae00008f000c3602021aaeaf0000ae008f000c",
INIT_0B => X"3c10008f000c0010000c001030008e363cac24343cafafaf2727038f8f8f8f8f",
INIT_0C => X"000000000000000000000000000000000a0000000000002703008f8fac002434",
INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
      DO   => data_read(31 downto 24),
      DOP  => open, 
      ADDR => address(12 downto 2),
      CLK  => clk, 
      DI   => data_write(31 downto 24),
      DIP  => ZERO(0 downto 0),
      EN   => enable,
      SSR  => ZERO(0),
      WE   => write_byte_enable(3));

   RAMB16_S9_inst1 : RAMB16_S9
   generic map (
INIT_00 => X"a9a8a7a6a5a4a3a2a1bd44e00200000062034202a560a4a0bd1d8404a5059c1c",
INIT_01 => X"a9a8a7a6a5a4a3a2a1a5a086c6c5c406bb00bb00ba5a1abfb9b8afaeadacabaa",
INIT_02 => X"9d9c9e979695949392919084e0029b401bbd60bb60bbbabfb9b8afaeadacabaa",
INIT_03 => X"6242030040008200e000c4e0000085a2e09f9d9c9e979695949392919002e09f",
INIT_04 => X"11100044508020a000b0b1b2bfbdbde000bf8400040000bfbd00e00040008284",
INIT_05 => X"424202c0e00040c543c686e30040420002e707080800a0bde0b0b1b2bf205040",
INIT_06 => X"44e002004042006263038440420042420242e042420240420062630302404200",
INIT_07 => X"b2bf004022315062100000120000b0b1b2bfbd00e044e0420262026303404202",
INIT_08 => X"124072000312404012004010002202311162026303b0b1b2b3b4bfbdbde0b0b1",
INIT_09 => X"8372031240830000837203124083000082520200821240340052141240520014",
INIT_0A => X"bf62000263030040545273721233821383000010006080238372031240830000",
INIT_0B => X"03800084000000000000004042000210106202630380b0bfbdbde0b0b1b2b3b4",
INIT_0C => X"000000000000000000000000000000000d000000000000bde000b0bf62800263",
INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
      DO   => data_read(23 downto 16),
      DOP  => open, 
      ADDR => address(12 downto 2),
      CLK  => clk, 
      DI   => data_write(23 downto 16),
      DIP  => ZERO(0 downto 0),
      EN   => enable,
      SSR  => ZERO(0),
      WE   => write_byte_enable(2));

   RAMB16_S9_inst2 : RAMB16_S9
   generic map (
INIT_00 => X"000000000000000000ff0000200000010020000000ff18000800080006008600",
INIT_01 => X"00000000000000000000f8200000002000d800d800ff70000000000000000000",
INIT_02 => X"0000000000000000000000600060600000000000000000000000000000000000",
INIT_03 => X"0000200000000000000000002010000000000000000000000000000000000000",
INIT_04 => X"10000000109000888000000000ff00000000060000000000ff000000ff000000",
INIT_05 => X"000020100000ff100000100000000000000020002030000000000000001010ff",
INIT_06 => X"00002000ff0000000020000000000000200000000020ff000000002020000000",
INIT_07 => X"000010ff000000801a000020888000000000ff00000000002000000020000020",
INIT_08 => X"0090a0001a00901800009020000000002000000020000000000000ff00000000",
INIT_09 => X"80181a009080000080181a0090809800801012008000900000a0120090a00012",
INIT_0A => X"00000000002000ff1000001800009822800000008890000080181a0090800000",
INIT_0B => X"20ff00800000000000010000000000002000000020800000ff00000000000000",
INIT_0C => X"0000000000000000000000000000000000000000000000000010000000f80000",
INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
      DO   => data_read(15 downto 8),
      DOP  => open, 
      ADDR => address(12 downto 2),
      CLK  => clk, 
      DI   => data_write(15 downto 8),
      DIP  => ZERO(0 downto 0),
      EN   => enable,
      SSR  => ZERO(0),
      WE   => write_byte_enable(1));

   RAMB16_S9_inst3 : RAMB16_S9
   generic map (
INIT_00 => X"302c2824201c181410984408001200674c004c0004fd2a003800500040002f01",
INIT_01 => X"302c2824201c181410000924504c400060125c1058fc0054504c4844403c3834",
INIT_02 => X"2824201c1814100c080400000800000801681360115c5854504c4844403c3834",
INIT_03 => X"00ff000009000000080c000810121900082c2824201c1814100c08040000082c",
INIT_04 => X"2a01cf0021250825251014181ce0180800103c7900007910e8000800fa000001",
INIT_05 => X"000800250800f52a00012100000808000004000800251120081014181c2521fb",
INIT_06 => X"00080000fc0100000800ff080100000800ff08000400fc080000080000080800",
INIT_07 => X"181c25f8040100210000bd0025251014181ce000080008400000fa8000009400",
INIT_08 => X"002521bd0000252500bd2500bd00aa6000000110001014181c2024d820081014",
INIT_09 => X"15210000251500bd15210000251525bd1521000015002500bd2100002521bd00",
INIT_0A => X"2400bdff600000f42a010021000021001500bd602525100015210000251500bd",
INIT_0B => X"00f2001500eb000300040005080000740000556000151014e828081014181c20",
INIT_0C => X"000000000000000000000000000000000000000000000018082510140009ff60",
INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000")
   port map (
      DO   => data_read(7 downto 0),
      DOP  => open, 
      ADDR => address(12 downto 2),
      CLK  => clk, 
      DI   => data_write(7 downto 0),
      DIP  => ZERO(0 downto 0),
      EN   => enable,
      SSR  => ZERO(0),
      WE   => write_byte_enable(0));

end; --architecture logic
