library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ecp5u;
use ecp5u.components.all;

entity top_edid_test is
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

  -- Digital Video (differential inputs)
  gpdi_dp, gpdi_dn: in std_logic_vector(3 downto 0);
  -- control lines as input with pullups to activate hotplug autodetection
  -- to enable hotplug, gpdi_ethn capacitor should be bypassed by 470 ohm resistor
  -- it's a C closest to the DIP switch
  gpdi_ethp, gpdi_ethn: inout std_logic;
  gpdi_cec: in std_logic;

  -- i2c shared for digital video and RTC
  gpdi_scl: in std_logic;
  gpdi_sda: inout std_logic;

  gp, gn: in std_logic_vector(27 downto 0);
  
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

architecture Behavioral of top_edid_test is
    signal pixel_clk : std_logic;
    signal clk100, locked : std_logic;
    signal clk_pixel_cable, clk_pixel, clk_shift: std_logic;
    signal clk_raw_cable: std_logic;
    signal debug, blink : std_logic_vector(7 downto 0);
begin
    led <= debug;
    wifi_gpio0 <= btn(0);
    gpdi_ethn <= '1' when btn(0) = '1' else '0';

    clk_25_inst: entity work.clk_25
    port map
    (
        clki => clk_25mhz,
        clks3 => clk100,
        locked => open
    );
    
    diff_in_inst: ilvds
    port map
    (
      a  => gp(12),
      an => gn(12),
      z  => clk_pixel_cable
    );

    -- clk_raw_cable <= not gpdi_dn(3); -- emulate differential, force insertion of fpga fabric
    -- clk_raw_cable <= gpdi_dp(3) and not gpdi_dn(3); -- emulate differential, force insertion of fpga fabric

    clk_video_inst: entity work.clk_25
    port map
    (
        clki => clk_pixel_cable, -- trying to use single ended mode
        clks1 => clk_shift,
        clks2 => clk_pixel,
        locked => locked
    );
    
    blink_inst: entity work.blink
    port map
    (
      clk => clk_shift,
      led => blink
    );
    
    --gpdi_ethp <= blink(0);
    --gpdi_ethn <= not blink(0);
    debug(6) <= blink(7);
    debug(7) <= locked;

    edid_rom_inst: entity work.edid_rom
    port map
    (
        clk        => clk100,
        sclk_raw   => gpdi_scl,
        sdat_raw   => gpdi_sda,
        edid_debug => debug(2 downto 0)
    );

end Behavioral;
