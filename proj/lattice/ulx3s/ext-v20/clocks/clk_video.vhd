--
-- AUTHOR=EMARD
-- LICENSE=BSD
--

-- VHDL Wrapper

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity clk_video is
  port
  (
    clki: in std_logic;
    clko, clks1, clks2, clks3: out std_logic;
    locked: out std_logic
  );
end;

architecture syn of clk_video is
  component clk_video_v -- verilog name and its parameters
  port
  (
    clki: in std_logic;
    clko, clks1, clks2, clks3: out std_logic;
    locked: out std_logic
  );
  end component;

begin
  clk_video_v_inst: clk_video_v
  port map
  (
    clki => clki,
    clko => clko,
    clks1 => clks1,
    clks2 => clks2,
    clks3 => clks3,
    locked => locked
  );
end syn;
