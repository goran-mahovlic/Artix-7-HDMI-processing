library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga_generator is
  port(clk25     : in std_logic;
       red_out   : out std_logic_vector(7 downto 0);
       green_out : out std_logic_vector(7 downto 0);
       blue_out  : out std_logic_vector(7 downto 0);
       hs_out    : out std_logic;
       vs_out    : out std_logic;
       blank_out : out std_logic
);
end vga_generator;

architecture Behavioral of vga_generator is

signal horizontal_counter : std_logic_vector (9 downto 0);
signal vertical_counter   : std_logic_vector (9 downto 0);

begin

process (clk25)
begin
  if clk25'event and clk25 = '1' then
    if (horizontal_counter >= "0010010000" ) -- 144
    and (horizontal_counter < "1100010000" ) -- 784
    and (vertical_counter >= "0000100111" ) -- 39
    and (vertical_counter < "1000000111" ) -- 519
    then

     --here you paint!!
      red_out <= "11111111";
      green_out <= "11111111";
      blue_out <= "00000000";
      blank_out <= '0';

    else
      red_out <= "00000000";
      green_out <= "00000000";
      blue_out <= "00000000";
      blank_out <= '1';
    end if;
    if (horizontal_counter > "0000000000" )
      and (horizontal_counter < "0001100001" ) -- 96+1
    then
      hs_out <= '0';
    else
      hs_out <= '1';
    end if;
    if (vertical_counter > "0000000000" )
      and (vertical_counter < "0000000011" ) -- 2+1
    then
      vs_out <= '0';
    else
      vs_out <= '1';
    end if;
    horizontal_counter <= horizontal_counter+"0000000001";
    if (horizontal_counter="1100100000") then
      vertical_counter <= vertical_counter+"0000000001";
      horizontal_counter <= "0000000000";
    end if;
    if (vertical_counter="1000001001") then
      vertical_counter <= "0000000000";
    end if;
  end if;
end process;

end Behavioral;
