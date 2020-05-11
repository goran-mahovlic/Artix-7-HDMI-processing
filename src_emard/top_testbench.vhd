library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ecp5u;
use ecp5u.components.all;

entity top_testbench is
Port
( 
  clk_25mhz    : in STD_LOGIC;
  -- Control signals
  led           : out   std_logic_vector(7 downto 0) :=(others => '0');
  sw            : in    std_logic_vector(3 downto 0) :=(others => '0');
  btn           : in    std_logic_vector(6 downto 0) :=(others => '0');
        
  wifi_gpio0: out  std_logic;

  -- Digital Video monitor output
  -- picture to be analyzed will be displayed here
  gpdi_dp, gpdi_dn: out std_logic_vector(3 downto 0);

  -- control lines as input with pullups to activate hotplug autodetection
  -- to enable hotplug, gpdi_ethn capacitor should be bypassed by 470 ohm resistor
  -- it's a C closest to the DIP switch
  gpdi_ethp, gpdi_ethn: inout std_logic;
  gpdi_cec: in std_logic;

  -- i2c shared for digital video and RTC
  gpdi_scl: in std_logic;
  gpdi_sda: inout std_logic;
  gn8: inout std_logic;
  gp: inout std_logic_vector(27 downto 13);
  gpa: in std_logic_vector(12 downto 9);
  gpb: inout std_logic_vector(8 downto 0); 
  gn: inout std_logic_vector(27 downto 13);
  -- For dumping symbols
  ftdi_rxd : out std_logic      
);
end;

architecture Behavioral of top_testbench is
    constant C_internal_pll: boolean := true;
    constant C_hamsterz: boolean := true;
    signal clk_100, locked, locked1 : std_logic;
    signal clk_250, clk_125, clk_25: std_logic; -- to video generator
    signal clk_pixel, clk_shift: std_logic;
    signal debug, blink : std_logic_vector(7 downto 0);
    signal reset: std_logic;
    signal rec_blank, rec_hsync, rec_vsync, test_blank, test_hsync, test_vsync: std_logic;
    signal rec_red, rec_green, rec_blue, test_red, test_green, test_blue: std_logic_vector(7 downto 0);
    signal outp_red, outp_green, outp_blue: std_logic_vector(9 downto 0); -- TMDS encoded 10-bit
    signal des_red, des_green, des_blue: std_logic_vector(9 downto 0); -- deserialized 10-bit TMDS
    signal vga_red, vga_green, vga_blue: std_logic_vector(7 downto 0); -- 8-bit RGB color decoded
    signal vga_hsync, vga_vsync, vga_blank: std_logic; -- frame control
    signal fin_clock, fin_red, fin_green, fin_blue: std_logic_vector(1 downto 0); -- VGA back to final TMDS
    signal tmds_p, tmds_n: std_logic_vector(3 downto 0); -- internally generated TMDS
begin
  --  led <= rec_red;
    wifi_gpio0 <= btn(0);
    gpdi_ethn <= '1' when btn(0) = '1' else '0';
    gn(13) <= '1' when btn(1) = '0' else '1'; -- eth- hotplug
    reset <= not btn(0);

    -- clock for video generator and logic
    clk_25_inst: entity work.clk_25
    port map
    (
      CLKI=> clk_25mhz,
      CLKOP => clk_250,
      CLKOS => clk_125,
      CLKOS2 => clk_25,
      CLKOS3 => clk_100,
      LOCK => locked1
    );
    
    -- video generator

--    videotest_inst: entity work.videotest640x480
--    port map
--    (
--      clk_pixel  => clk_25,
--      clk_shift  => clk_250,
--      out_blank  => test_blank,
--      out_hsync  => test_hsync,
--      out_vsync  => test_vsync,
--      out_red    => test_red,
--      out_green  => test_green,
--      out_blue   => test_blue,
--      outp_red   => outp_red,
--      outp_green => outp_green,
--      outp_blue  => outp_blue,
--      out_p      => open,
--      out_n      => open
--    );
    
    -- connect output to monitor
--    gpdi_dp(2 downto 0) <= gpa(11 downto 9); --tmds_p;

    -- gpdi_dn <= tmds_n;
   -- gn8 <= gpdi_scl;
   -- gpb(8) <= gpdi_sda;
    
    -- clock recovery PLL
    g_yes_internal_pll: if C_internal_pll generate
    clk_video_inst: entity work.clk_video
    port map
    (
      CLKI => gpa(12), -- take tmds clock as input
      CLKOP => clk_shift,
      CLKOS2 => clk_pixel,
      LOCK => locked
    );
    end generate;

    g_not_internal_pll: if not C_internal_pll generate
    clk_pixel <= clk_25;
    clk_shift <= clk_250;
    locked <= locked1;
    end generate;

    blink_inst: entity work.blink
    port map
    (
--      clk => clk_shift,
      clk => clk_250,
      led(3) => led(4)
    );
    
    blink_shift_inst: entity work.blink
    port map
    (
      clk => clk_shift,
      led(3) => led(6)
    );

    led(7) <= locked;
    led(5) <= locked1;

    led(3 downto 0) <= debug(3 downto 0);

    g_yes_hamsterz: if C_hamsterz generate
    hdmi_design_inst: entity work.hdmi_design
    port map
    (
      clk100     => clk_100,
      clk_pixel  => clk_pixel,
      clk_pixel_shift => clk_shift,
      clk_locked => locked,

      led        => debug,
      sw(3 downto 0) => sw(3 downto 0),
      btn        => btn,
      debug_pmod => open,
      
      -- VGA in
      test_blank => test_blank,
      test_hsync => test_hsync,
      test_vsync => test_vsync,
      test_red   => test_red,
      test_green => test_green,
      test_blue  => test_blue,

      -- VGA out
      rec_blank  => rec_blank,
      rec_hsync  => rec_vsync,
      rec_vsync  => rec_vsync,
      rec_red  => rec_red,
      rec_green  => rec_green,
      rec_blue  => rec_blue,

      -- HDMI in
      hdmi_rx_clk_n => not gpa(12), 
      hdmi_rx_clk_p => gpa(12),
      hdmi_rx_n => not gpa(11 downto 9), 
      hdmi_rx_p => gpa(11 downto 9),
      hdmi_rx_txen => open,
      hdmi_rx_scl => gn8,
      hdmi_rx_sda => gpb(8),
      
      -- HDMI out
      hdmi_tx_clk_n => gpdi_dn(3),
      hdmi_tx_clk_p => gpdi_dp(3),
      hdmi_tx_n => gpdi_dn(2 downto 0),
      hdmi_tx_p => gpdi_dp(2 downto 0),
      hdmi_tx_hpd => '1',

      rs232_tx => ftdi_rxd
    );
    end generate;

    g_not_hamsterz: if not C_hamsterz generate
    -- deserialize tmds_p to parallel 10-bit
    -- clk_pixel and clk_shift must be phase aligned with tmds_p(3) clock
    tmds_deserializer_inst: entity work.tmds_deserializer
    port map
    (
      clk_pixel => clk_pixel,
      clk_shift => clk_shift,
      tmds_p => gpa(12 downto 9),
      outp_red => des_red,
      outp_green => des_green,
      outp_blue => des_blue
    );
    -- led <= des_red(9 downto 2);
    -- debug <= outp_blue(7 downto 0);
    -- parallel 10-bit TMDS to 8-bit RGB VGA converter
    dvi2vga_inst: entity work.dvi2vga
    port map
    (
      clk => clk_pixel,
      dvi_red => des_red,
      dvi_green => des_green,
      dvi_blue => des_blue,
      --dvi_blue => outp_blue, -- original blue contains syncs. monitor should show picture
      vga_red => vga_red,
      vga_green => vga_green,
      vga_blue => vga_blue,
      vga_hsync => vga_hsync,
      vga_vsync => vga_vsync,
      vga_blank => vga_blank
    );
    -- VGA back to DVI-D
    vga2dvid_inst: entity work.vga2dvid
    port map
    (
      clk_pixel => clk_pixel,
      clk_shift => clk_shift,
      in_red => vga_red,
      in_green => vga_green,
      in_blue => vga_blue,
      in_blank => vga_blank,
      in_hsync => vga_hsync,
      in_vsync => vga_vsync,
      out_red => fin_red,
      out_green => fin_green,
      out_blue => fin_blue,
      out_clock => fin_clock
    );
    -- DVI-D to differential
    fake_differential_inst: entity work.fake_differential
    port map
    (
      clk_shift => clk_shift,
      in_red => fin_red,
      in_green => fin_green,
      in_blue => fin_blue,
      in_clock => fin_clock,
      out_p => gpdi_dp,
      out_n => gpdi_dn
--      out_p => open,
--      out_n => open
    );
    end generate;

end Behavioral;
