----------------------------------------------------------------------------------
-- Engineer:    Mike Field <hamster@snap.net.nz> 
-- 
-- Create Date: 22.07.2015 21:10:34
-- Module Name: hdmi_design - Behavioral
-- Project Name: 
--
-- Description: Top level of a video processing design 
-- 
------------------------------------------------------------------------------------
-- The MIT License (MIT)
-- 
-- Copyright (c) 2015 Michael Alan Field
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
------------------------------------------------------------------------------------
----- Want to say thanks? ----------------------------------------------------------
------------------------------------------------------------------------------------
--
-- This design has taken many hours - with the industry metric of 30 lines
-- per day, it is equivalent to about 6 months of work. I'm more than happy
-- to share it if you can make use of it. It is released under the MIT license,
-- so you are not under any onus to say thanks, but....
-- 
-- If you what to say thanks for this design how about trying PayPal?
--  Educational use - Enough for a beer
--  Hobbyist use    - Enough for a pizza
--  Research use    - Enough to take the family out to dinner
--  Commercial use  - A weeks pay for an engineer (I wish!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hdmi_design is
    Port ( 
        clk100    : in STD_LOGIC;
        clk_pixel : in STD_LOGIC; -- 25 MHz
        clk_pixel_shift : in STD_LOGIC; -- 250 MHz
        clk_locked : in STD_LOGIC; -- 1 when locked

        -- Control signals
        led           : out   std_logic_vector(7 downto 0) :=(others => '0');
        sw            : in    std_logic_vector(7 downto 0) :=(others => '0');
        btn           : in    std_logic_vector(6 downto 0) :=(others => '0');
        debug_pmod    : out   std_logic_vector(7 downto 0) :=(others => '0');

        --input  test picture signal to bypass HDMI during btn(1) press
        test_blank    : std_logic;
        test_hsync    : std_logic;
        test_vsync    : std_logic;
        test_red      : std_logic_vector(7 downto 0);
        test_green    : std_logic_vector(7 downto 0);
        test_blue     : std_logic_vector(7 downto 0);

        --HDMI input signals
        hdmi_rx_cec   : inout std_logic;
        hdmi_rx_hpa   : out   std_logic;
        hdmi_rx_scl   : in    std_logic;
        hdmi_rx_sda   : inout std_logic;
        hdmi_rx_txen  : out   std_logic;
        hdmi_rx_clk_n : in    std_logic;
        hdmi_rx_clk_p : in    std_logic;
        hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        hdmi_rx_p     : in    std_logic_vector(2 downto 0);

        --- HDMI out
        hdmi_tx_cec   : inout std_logic;
        hdmi_tx_clk_n : out   std_logic;
        hdmi_tx_clk_p : out   std_logic;
        hdmi_tx_hpd   : in    std_logic;
        hdmi_tx_rscl  : inout std_logic;
        hdmi_tx_rsda  : inout std_logic;
        hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        hdmi_tx_n     : out   std_logic_vector(2 downto 0);
        -- For dumping symbols
        rs232_tx     : out std_logic      
    );
end hdmi_design;

architecture Behavioral of hdmi_design is
    signal symbol_sync  : std_logic;
    signal symbol_ch0   : std_logic_vector(9 downto 0);
    signal symbol_ch1   : std_logic_vector(9 downto 0);
    signal symbol_ch2   : std_logic_vector(9 downto 0);

    signal pixel_clk : std_logic;

    signal in_blank  : std_logic;
    signal in_hsync  : std_logic;
    signal in_vsync  : std_logic;
    signal in_red    : std_logic_vector(7 downto 0);
    signal in_green  : std_logic_vector(7 downto 0);
    signal in_blue   : std_logic_vector(7 downto 0);
    signal is_interlaced   : std_logic;
    signal is_second_field : std_logic;
    -- switched between internal VGA test picture and recovered input picture
    signal sw_blank  : std_logic;
    signal sw_hsync  : std_logic;
    signal sw_vsync  : std_logic;
    signal sw_red    : std_logic_vector(7 downto 0);
    signal sw_green  : std_logic_vector(7 downto 0);
    signal sw_blue   : std_logic_vector(7 downto 0);
    signal sw_interlaced   : std_logic;
    signal sw_second_field : std_logic;

    signal out_blank : std_logic;
    signal out_hsync : std_logic;
    signal out_vsync : std_logic;
    signal out_red   : std_logic_vector(7 downto 0);
    signal out_green : std_logic_vector(7 downto 0);
    signal out_blue  : std_logic_vector(7 downto 0);

    signal audio_channel : std_logic_vector(2 downto 0);
    signal audio_de      : std_logic;
    signal audio_sample  : std_logic_vector(23 downto 0);

    signal btn_sample    : std_logic_vector(23 downto 0);

    signal debug : std_logic_vector(7 downto 0);
begin
    debug_pmod <= debug;    
    led        <= debug;
    
i_hdmi_io: entity work.hdmi_io port map ( 
        clk100           => clk100,
        clk_pixel        => clk_pixel,
        clk_pixel_shift  => clk_pixel_shift,
        clk_locked       => clk_locked,
        ---------------------
        -- Control signals
        ---------------------
        clock_locked     => open,
        data_synced      => open,
        debug            => debug,
        ---------------------
        -- HDMI input signals
        ---------------------
        hdmi_rx_cec   => hdmi_rx_cec,
        hdmi_rx_hpa   => hdmi_rx_hpa,
        hdmi_rx_scl   => hdmi_rx_scl,
        hdmi_rx_sda   => hdmi_rx_sda,
        hdmi_rx_txen  => hdmi_rx_txen,
        hdmi_rx_clk_n => hdmi_rx_clk_n,
        hdmi_rx_clk_p => hdmi_rx_clk_p,
        hdmi_rx_p     => hdmi_rx_p,
        hdmi_rx_n     => hdmi_rx_n,

        ----------------------
        -- HDMI output signals
        ----------------------
        hdmi_tx_cec   => hdmi_tx_cec,
        hdmi_tx_clk_n => hdmi_tx_clk_n,
        hdmi_tx_clk_p => hdmi_tx_clk_p,
        hdmi_tx_hpd   => hdmi_tx_hpd,
        hdmi_tx_rscl  => hdmi_tx_rscl,
        hdmi_tx_rsda  => hdmi_tx_rsda,
        hdmi_tx_p     => hdmi_tx_p,
        hdmi_tx_n     => hdmi_tx_n,     
        
        pixel_clk => pixel_clk,
        -------------------------------
        -- VGA data recovered from HDMI
        -------------------------------
        in_blank        => in_blank,
        in_hsync        => in_hsync,
        in_vsync        => in_vsync,
        in_red          => in_red,
        in_green        => in_green,
        in_blue         => in_blue,
        is_interlaced   => is_interlaced,
        is_second_field => is_second_field,

        -----------------------------------
        -- For symbol dump or retransmit
        -----------------------------------
        audio_channel => audio_channel,
        audio_de      => audio_de,
        audio_sample  => audio_sample,
        
        -----------------------------------
        -- VGA data to be converted to HDMI
        -----------------------------------
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue,
        
        symbol_sync  => symbol_sync, 
        symbol_ch0   => symbol_ch0,
        symbol_ch1   => symbol_ch1,
        symbol_ch2   => symbol_ch2
    );
    
-- switched test or input picture
process(pixel_clk)
begin
  if rising_edge(pixel_clk) then
    if btn(1) = '1' then
        sw_blank <= test_blank;
        sw_hsync <= test_hsync;
        sw_vsync <= test_vsync;
        sw_red   <= test_red;
        sw_green <= test_green;
        sw_blue  <= test_blue;
        sw_interlaced   <= '0';
        sw_second_field <= '0';
    else
        sw_blank <= in_blank;
        sw_hsync <= in_hsync;
        sw_vsync <= in_vsync;
        sw_red   <= in_red;
        sw_green <= in_green;
        sw_blue  <= in_blue;
        sw_interlaced   <= is_interlaced;
        sw_second_field <= is_second_field;
    end if;
  end if;
end process;

        btn_sample <= x"00" & btn(4 downto 1) & x"000";

i_processing: entity work.pixel_processing Port map ( 
        clk => pixel_clk,
        switches => sw,
        ------------------
        -- Incoming pixels
        ------------------
        in_blank        => sw_blank,
        in_hsync        => sw_hsync,
        in_vsync        => sw_vsync,
        in_red          => sw_red,
        in_green        => sw_green,
        in_blue         => sw_blue,    
        is_interlaced   => sw_interlaced,
        is_second_field => sw_second_field,
        audio_channel   => audio_channel,
        audio_de        => audio_de,
        audio_sample    => audio_sample,
        --audio_de        => btn(0),
        --audio_sample    => btn_sample,
        -------------------
        -- Processed pixels
        -------------------
        out_blank => out_blank,
        out_hsync => out_hsync,
        out_vsync => out_vsync,
        out_red   => out_red,
        out_green => out_green,
        out_blue  => out_blue
    );

    -- Swap to this if you want to capture the HDMI symbols
    -- and send them up the RS232 port
    --rs232_tx <= '1';
i_symbol_dump: entity work.symbol_dump port map (
            clk         => pixel_clk,
            clk100      => clk100,
            symbol_sync => symbol_sync,
            symbol_ch0  => symbol_ch0,
            symbol_ch1  => symbol_ch1,
            symbol_ch2  => symbol_ch2, 
            rs232_tx    => rs232_tx);        
    
end Behavioral;
