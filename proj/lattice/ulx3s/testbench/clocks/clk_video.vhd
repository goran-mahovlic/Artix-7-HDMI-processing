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
    clkin: in std_logic;
    clkout: out std_logic_vector(3 downto 0);
    locked: out std_logic
  );
end;

architecture syn of clk_video is
  component clk_video_v -- verilog name and its parameters
  port
  (
    clkin: in std_logic;
    clkout: out std_logic_vector(3 downto 0);
    locked: out std_logic
  );
  end component;

begin
  clk_video_v_inst: clk_video_v
  port map
  (
    clkin => clkin,
    clkout => clkout,
    locked => locked
  );
end syn;
