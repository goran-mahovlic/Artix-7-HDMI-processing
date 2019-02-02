-- VHDL Wrapper for vgatest640x480_v

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity videotest640x480 is
port
(
  clk_pixel, clk_shift: in std_logic;
  out_red, out_green, out_blue: out std_logic_vector(7 downto 0);
  out_hsync, out_vsync, out_blank: out std_logic;
  outp_red, outp_green, outp_blue: out std_logic_vector(9 downto 0);
  out_p, out_n: out std_logic_vector(3 downto 0)
);
end;

architecture syn of videotest640x480 is
  component videotest640x480_v -- verilog name and its parameters
  port
  (
    clk_pixel, clk_shift: in std_logic;
    out_red, out_green, out_blue: out std_logic_vector(7 downto 0);
    out_hsync, out_vsync, out_blank: out std_logic;
    outp_red, outp_green, outp_blue: out std_logic_vector(9 downto 0);
    out_p, out_n: out std_logic_vector(3 downto 0)
  );
  end component;

begin
  videotest640x480_v_inst: videotest640x480_v
  port map
  (
    clk_pixel  => clk_pixel,
    clk_shift  => clk_shift,
    out_red    => out_red,
    out_green  => out_green,
    out_blue   => out_blue,
    out_hsync  => out_hsync,
    out_vsync  => out_vsync,
    out_blank  => out_blank,
    outp_red   => outp_red,
    outp_green => outp_green,
    outp_blue  => outp_blue,
    out_p => out_p,
    out_n => out_n
  );
end syn;
