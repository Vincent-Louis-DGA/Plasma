-------------------------------------------------------------------------------
-- A fifo with adjustable width as a number of bytes.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fifo64x8N is
  
  generic (
    N            : integer   := 4;
    FALL_THROUGH : std_logic := '0'     -- First-word Fall Through or Standard
    );

  port (
    rst           : in  std_logic;
    wr_clk        : in  std_logic;
    rd_clk        : in  std_logic;
    din           : in  std_logic_vector(8*N-1 downto 0);
    wr_en         : in  std_logic;
    rd_en         : in  std_logic;
    dout          : out std_logic_vector(8*N-1 downto 0);
    full          : out std_logic;
    empty         : out std_logic;
    rd_data_count : out std_logic_vector(5 downto 0);
    wr_data_count : out std_logic_vector(5 downto 0));

end fifo64x8N;

architecture logic of fifo64x8N is

  signal fulls    : std_logic_vector(N-1 downto 0);
  signal empties  : std_logic_vector(N-1 downto 0);
  type   counts is array (0 to N-1) of std_logic_vector(5 downto 0);
  signal wrCounts : counts;
  signal rdCounts : counts;
  
begin  -- logic

  full          <= fulls(0);
  empty         <= empties(0);
  rd_data_count <= rdCounts(0);
  wr_data_count <= wrCounts(0);

  MAKE_FIFOS : for i in 0 to N-1 generate
    FT : if FALL_THROUGH = '1' generate
      uN_fifo : entity work.fallThroughFifo64x8
        port map (
          rst           => rst,
          wr_clk        => wr_clk,
          rd_clk        => rd_clk,
          din           => din(8*i+7 downto 8*i),
          wr_en         => wr_en,
          rd_en         => rd_en,
          dout          => dout(8*i+7 downto 8*i),
          full          => fulls(i),
          empty         => empties(i),
          rd_data_count => rdCounts(i),
          wr_data_count => wrCounts(i));
    end generate FT;
    ST : if FALL_THROUGH /= '1' generate
      uN_fifo : entity work.fifo64x8
        port map (
          rst           => rst,
          wr_clk        => wr_clk,
          rd_clk        => rd_clk,
          din           => din(8*i+7 downto 8*i),
          wr_en         => wr_en,
          rd_en         => rd_en,
          dout          => dout(8*i+7 downto 8*i),
          full          => fulls(i),
          empty         => empties(i),
          rd_data_count => rdCounts(i),
          wr_data_count => wrCounts(i));
    end generate ST;
  end generate MAKE_FIFOS;
  

end logic;
