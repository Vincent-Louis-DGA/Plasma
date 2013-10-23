-------------------------------------------------------------------------------
-- Modified by Adrian Jongenelen, 2012.
-- Original Author, see below.
---------------------------------------------------------------------
-- TITLE: Plasma (CPU core with memory)
-- AUTHOR: Adrian Jongenelen
-- DATE CREATED: 6/4/02
-- FILENAME: plasma.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity combines the CPU core with program and general
--    purpose memory.
-------------------------------------------------------------------------------
-- Memory Map:
--   0x00000000 - 0x1fffffff   Memory mapped peripherals
--   0x20000000 - 0x3fffffff   Internal RAM (Up to 512 MB, actually 16 KB)
--   0x40000000 - 0x7fffffff   External RAM (Up to 1024 MB)
--   0x80000000 - 0xffffffff   Unused space
-- See plasmaPeriphRegisters.vhd for peripheral addresses.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

use work.plasmaPeriphRegisters.all;

entity PlasmaCore is
  generic(memory_type : string    := "XILINX_X16";
          SIMULATION  : std_logic := '0');
  port(clk   : in std_logic;
       reset : in std_logic;

       bus_address : out std_logic_vector(31 downto 2);
       bus_din     : out std_logic_vector(31 downto 0);

       ex_ram_addr : out std_logic_vector(31 downto 0);
       ex_ram_dout : in  std_logic_vector(31 downto 0);
       ex_ram_wbe  : out std_logic_vector(3 downto 0);
       ex_ram_en   : out std_logic;

       periph_dout : in  std_logic_vector(31 downto 0);
       periph_we   : out std_logic;
       periph_wbe  : out std_logic_vector(3 downto 0);
       periph_re   : out std_logic;
       periph_irq  : in  std_logic;

       mem_pause_in : in  std_logic;
       intr_vector  : in  std_logic_vector(31 downto 0);
       line_number  : out std_logic_vector(31 downto 0)
       );
end;  --entity plasma

architecture logic of PlasmaCore is


  signal mem_address_reg : std_logic_vector(31 downto 2);
  signal mem_pause       : std_logic;
  signal mem_pause_int   : std_logic;

  signal mem_address    : std_logic_vector(31 downto 0);
  signal mem_data_read  : std_logic_vector(31 downto 0);
  signal mem_data_write : std_logic_vector(31 downto 0);

  signal mem_wbe     : std_logic_vector(3 downto 0);
  signal mem_wbe_reg : std_logic_vector(3 downto 0);
  signal mem_re      : std_logic;
  signal in_ram_din  : std_logic_vector(31 downto 0);
  signal in_ram_wbe  : std_logic_vector(3 downto 0);
  signal in_ram_dout : std_logic_vector(31 downto 0);

  signal in_ram_en     : std_logic;
  signal bulk_ram_wbe  : std_logic_vector(3 downto 0);
  signal bulk_ram_dout : std_logic_vector(31 downto 0);

  signal ex_ram_en1 : std_logic;
  signal ex_ram_en2 : std_logic;

  constant ZEROS : std_logic_vector(31 downto 0) := (others => '0');
  
  

begin  --architecture

  bus_din <= mem_data_write;

  mem_re <= '1' when mem_address(31 downto 29) /= IN_RAM_OFFSET and mem_wbe = "0000"
            else '0';

  periph_we <= '1' when mem_address_reg(31 downto 29) = PERIPH_OFFSET
               and mem_wbe_reg /= "0000" else '0';
  periph_wbe <= mem_wbe_reg when mem_address_reg(31 downto 29) = PERIPH_OFFSET
                else X"0";

  periph_re <= '1' when (mem_address(31 downto 29) = PERIPH_OFFSET and
                         mem_wbe = X"0") else '0';

  --ex_ram_en1 <= '1' when mem_address(31 downto 29) = EX_RAM_OFFSET else '0';
  ex_ram_en <= ex_ram_en1 and mem_pause_int;  --not ex_ram_en2;

  ex_ram_wbe <= mem_wbe_reg when mem_address_reg(31 downto 29) = EX_RAM_OFFSET
                else (others => '0');

  bus_address <= mem_address_reg;

  mem_pause <= mem_pause_int or mem_pause_in;
  --ex_ram_addr <= "000" & mem_address(28 downto 0);

  REGISTERS : process (clk, reset)
  begin  -- process REG_ADDR
    if reset = '1' then                 -- asynchronous reset (active high)
      --mem_address_reg <= (others => '0');
      mem_pause_int <= '0';
      mem_wbe_reg   <= (others => '0');
      ex_ram_en2    <= '0';
      ex_ram_en1    <= '0';
      ex_ram_addr   <= (others => '0');
    elsif rising_edge(clk) then         -- rising clock edge
      ex_ram_en1    <= '0';
      ex_ram_en2    <= '0';
      mem_pause_int <= '0';
      if mem_address(31 downto 29) = EX_RAM_OFFSET then
        ex_ram_en1  <= '1';
        ex_ram_addr <= mem_address;
        if mem_pause = '0' then
          mem_pause_int <= '1';
        end if;
      end if;
      if mem_address_reg(31 downto 29) = EX_RAM_OFFSET then
        ex_ram_en2 <= '1';
      end if;
      mem_address_reg <= mem_address(31 downto 2);
      mem_wbe_reg     <= mem_wbe;
      if mem_re = '1' and mem_pause = '0' then
        mem_pause_int <= '1';
      end if;
    end if;
  end process REGISTERS;



  SET_MEM_READ : process (mem_address_reg, ex_ram_dout, in_ram_dout, periph_dout, bulk_ram_dout)
  begin  -- process SET_MEM_READ
    case mem_address_reg(31 downto 29) is
      when IN_RAM_OFFSET =>
        if mem_address_reg(28 downto 13) = ZEROS(28 downto 13) then
          mem_data_read <= in_ram_dout;
        else
          mem_data_read <= bulk_ram_dout;
        end if;
      when PERIPH_OFFSET => mem_data_read <= periph_dout;
      when EX_RAM_OFFSET => mem_data_read <= ex_ram_dout;
      when others        => mem_data_read <= (others => '0');
    end case;
  end process SET_MEM_READ;


  u1_cpu : entity work.mlite_cpu
    generic map (memory_type => memory_type)
    port map (
      clk         => clk,
      reset_in    => reset,
      intr_in     => periph_irq,
      intr_vector => intr_vector,
      mem_address => mem_address,
      mem_data_w  => mem_data_write,
      mem_data_r  => mem_data_read,
      mem_byte_we => mem_wbe,
      mem_re      => open,
      mem_pause   => mem_pause,
      line_number => line_number);

  in_ram_din <= mem_data_write;
  in_ram_wbe <= mem_wbe;

  process (mem_address, mem_wbe)
  begin  -- process
    if mem_address(31 downto 13) = ZEROS(31 downto 13) then
      bulk_ram_wbe <= (others => '0');
      in_ram_en    <= '1';
    elsif mem_address(31 downto 13) = (ZEROS(31 downto 14) & '1') then
      bulk_ram_wbe <= mem_wbe;
      in_ram_en    <= '0';
    elsif mem_address(31 downto 14) = (ZEROS(31 downto 15) & '1') then
      bulk_ram_wbe <= mem_wbe;
      in_ram_en    <= '0';
    else
      bulk_ram_wbe <= (others => '0');
      in_ram_en    <= '0';
    end if;
  end process;

  NOT_SIM : if SIMULATION /= '1' generate
    u2_prog_ram : entity work.ram_PlasmaBootLoader
      generic map (memory_type => memory_type)
      port map (
        clk               => clk,
        enable            => in_ram_en,
        write_byte_enable => in_ram_wbe,
        address           => mem_address(31 downto 2),
        data_write        => in_ram_din,
        data_read         => in_ram_dout);
  end generate NOT_SIM;
  SIM : if SIMULATION = '1' generate
    u2_prog_ram : entity work.ram_Program
      generic map (memory_type => memory_type)
      port map (
        clk               => clk,
        enable            => in_ram_en,
        write_byte_enable => in_ram_wbe,
        address           => mem_address(31 downto 2),
        data_write        => in_ram_din,
        data_read         => in_ram_dout);
  end generate SIM;

  u3_ram : entity work.dualRamMx8N
    generic map (
      N => 4,
      M => 13)
    port map (
      clka   => clk,
      wea    => bulk_ram_wbe,
      addra  => mem_address(14 downto 2),
      dina   => in_ram_din,
      raddra => mem_address(14 downto 2),
      douta  => bulk_ram_dout,
      clkb   => '1',
      web    => X"0",
      addrb  => "1111111111111",
      dinb   => X"00000000",
      doutb  => open
      );


end;  --architecture logic
