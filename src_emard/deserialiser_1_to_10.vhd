-- TODO this code is incomplete and untested

library IEEE;
use IEEE.std_logic_1164.ALL;

entity deserialiser_1_to_10 is
    Port
    (
           delay_ce    : in  std_logic;
           delay_count : in  std_logic_vector (4 downto 0); -- sub-bit delay
           
           ce          : in  STD_LOGIC;
           clk         : in  std_logic; -- delay refclk 200 MHz
           clk_x1      : in  std_logic; -- pixel clock
           bitslip     : in  std_logic; -- skips one bit
           clk_x5      : in  std_logic; -- 5x pixel clock in DDR mode (or 10x in SDR mode)
           serial      : in  std_logic; -- input serial data
           reset       : in  std_logic;
           data        : out std_logic_vector (9 downto 0) -- output data
    );
end deserialiser_1_to_10;

architecture Behavioral of deserialiser_1_to_10 is
    signal delayed : std_logic := '0';
    signal clkb    : std_logic := '1';
    signal R_shift, R_latch, R_data : std_logic_vector(9 downto 0);
    constant C_shift_clock_initial: std_logic_vector(9 downto 0) := "0000011111";
    signal R_clock : std_logic_vector(9 downto 0) := C_shift_clock_initial;
begin
    -- TODO implement fine-grained delay using "delay_count"
    delayed <= serial;

    process(clk_x5)
    begin
      if rising_edge(clk_x5) then
        if bitslip = '0' then
          R_shift <= R_shift(R_shift'high-1 downto 0) & delayed;
        end if;
        R_clock <= R_clock(0) & R_clock(R_clock'high downto 1);
        if R_clock(5 downto 4) = C_shift_clock_initial(5 downto 4) then
          R_latch <= R_shift;
        end if;
      end if;
    end process;
    
    process(clk_x1)
    begin
      if rising_edge(clk_x1) then
        R_data <= R_latch;
      end if;
    end process;

    data <= R_data;

end Behavioral;
