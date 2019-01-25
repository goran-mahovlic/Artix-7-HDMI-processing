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

        --HDMI input signals
        --hdmi_rx_cec   : inout std_logic;
        --hdmi_rx_hpa   : out   std_logic;
        --hdmi_rx_scl   : in    std_logic;
        --hdmi_rx_sda   : inout std_logic;
        --hdmi_rx_txen  : out   std_logic;
        --hdmi_rx_clk_n : in    std_logic;
        --hdmi_rx_clk_p : in    std_logic;
        --hdmi_rx_n     : in    std_logic_vector(2 downto 0);
        --hdmi_rx_p     : in    std_logic_vector(2 downto 0);

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

  gp, gn: inout std_logic_vector(27 downto 0);
  
        --- HDMI out
        --hdmi_tx_cec   : inout std_logic;
        --hdmi_tx_clk_n : out   std_logic;
        --hdmi_tx_clk_p : out   std_logic;
        --hdmi_tx_hpd   : in    std_logic;
        --hdmi_tx_rscl  : inout std_logic;
        --hdmi_tx_rsda  : inout std_logic;
        --hdmi_tx_p     : out   std_logic_vector(2 downto 0);
        --hdmi_tx_n     : out   std_logic_vector(2 downto 0);
        -- For dumping symbols
  ftdi_rxd : out std_logic      
);
end;

architecture Behavioral of top_testbench is
    signal clk_100, locked : std_logic;
    signal clk_250, clk_125, clk_25: std_logic; -- to video generator
    signal clk_pixel, clk_shift: std_logic;
    signal debug, blink : std_logic_vector(7 downto 0);
    signal reset: std_logic;
    signal tmds_p, tmds_n: std_logic_vector(3 downto 0);
begin
    led <= debug;
    wifi_gpio0 <= btn(0);
    gpdi_ethn <= '1' when btn(0) = '1' else '0';
    gp(7) <= '1' when btn(0) = '1' else '0'; -- eth- hotplug
    reset <= not btn(0);

    -- clock for video generator and logic
    clk_25_inst: entity work.clk_25
    port map
    (
      clkin => clk_25mhz,
      clkout(0) => clk_250,
      clkout(1) => clk_125,
      clkout(2) => clk_25,
      clkout(3) => clk_100,
      locked => open
    );
    
    -- video generator
    videotest_inst: entity work.videotest640x480
    port map
    (
      clk_pixel => clk_25,
      clk_shift => clk_250,
      out_p => tmds_p,
      out_n => tmds_n
    );
    
    -- connect output to monitor
    gpdi_dp <= tmds_p;
    gpdi_dn <= tmds_n;
    
    -- clock recovery PLL
    clk_video_inst: entity work.clk_video
    port map
    (
      clkin => tmds_p(3), -- take tmds clock as input
      clkout(0) => clk_shift,
      clkout(2) => clk_pixel,
      locked => locked
    );

    blink_inst: entity work.blink
    port map
    (
      clk => clk_shift,
      led => blink
    );
    
    debug(6) <= blink(7);
    debug(7) <= locked;

    edid_rom_inst: entity work.edid_rom
    port map
    (
      clk        => clk_100,
      sclk_raw   => gp(8), -- gpdi_scl,
      sdat_raw   => gn(8), -- gpdi_sda,
      edid_debug => debug(2 downto 0)
    );

end Behavioral;
