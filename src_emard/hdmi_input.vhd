-- TODO input delay control missing?

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity hdmi_input is
    Port (
        system_clk      : in  std_logic;
        
        clk_pixel       : in  std_logic; -- input to PLL from hdmi_in_clk
        clk_pixel_x1    : in  std_logic; -- output from PLL
        clk_pixel_x5    : in  std_logic; -- output from PLL
        locked          : in  std_logic; -- '1' when PLL locked to hdmi_in_clk

        debug           : out std_logic_vector(5 downto 0);        
        hdmi_detected   : out std_logic;
    
        pixel_clk       : out std_logic;  -- Driven by BUFG
        pixel_io_clk_x1 : out std_logic;  -- Driven by BUFFIO
        pixel_io_clk_x5 : out std_logic;  -- Driven by BUFFIO
    
        -- HDMI input signals
        hdmi_in_clk   : in    std_logic;
        hdmi_in_ch0   : in    std_logic;
        hdmi_in_ch1   : in    std_logic;
        hdmi_in_ch2   : in    std_logic;
    
        -- Status
        pll_locked   : out std_logic;
        symbol_sync  : out std_logic;
    
        -- Raw data signals
        raw_blank : out std_logic;
        raw_hsync : out std_logic;
        raw_vsync : out std_logic;
        raw_ch0   : out std_logic_vector(7 downto 0);
        raw_ch1   : out std_logic_vector(7 downto 0);
        raw_ch2   : out std_logic_vector(7 downto 0);
        -- ADP data
        adp_data_valid      : out std_logic;
        adp_header_bit      : out std_logic;
        adp_frame_bit       : out std_logic;
        adp_subpacket0_bits : out std_logic_vector(1 downto 0);
        adp_subpacket1_bits : out std_logic_vector(1 downto 0);
        adp_subpacket2_bits : out std_logic_vector(1 downto 0);
        adp_subpacket3_bits : out std_logic_vector(1 downto 0);
        -- For later reuse
        symbol_ch0   : out std_logic_vector(9 downto 0);
        symbol_ch1   : out std_logic_vector(9 downto 0);
        symbol_ch2   : out std_logic_vector(9 downto 0)
        
    );
end hdmi_input;

architecture Behavioral of hdmi_input is
    signal clk_pixel_raw     : std_logic;
    
    --signal clk_pixel         : std_logic;
    --signal clk_pixel_x1      : std_logic;
    --signal clk_pixel_x5      : std_logic;

    signal clk_pixel_x1_raw  : std_logic;
    signal clk_pixel_x5_raw  : std_logic;
    signal clk_200_raw       : std_logic; -- for delay derived from system clk
    signal clk_200           : std_logic; -- for delay derived from system clk
    signal clkfb_1           : std_logic;
    signal clkfb_2           : std_logic;
    -- signal locked            : std_logic;
    signal reset             : std_logic;
    signal ser_reset         : std_logic;
    signal ser_ce            : std_logic;
    -------------------------------------------------------------
    -- The raw 10-bit received symbols
    -------------------------------------------------------------
    signal ch0_symbol  : std_logic_vector(9 downto 0);
    signal ch1_symbol  : std_logic_vector(9 downto 0);
    signal ch2_symbol  : std_logic_vector(9 downto 0);
    
    -------------------------------------------------------------
    -- For the decoded TMDS data
    -------------------------------------------------------------
    signal ch0_invalid_symbol  : std_logic;
    signal ch0_ctl_valid       : std_logic;
    signal ch0_ctl             : std_logic_vector(1 downto 0);
    signal ch0_terc4_valid     : std_logic;
    signal ch0_terc4           : std_logic_vector (3 downto 0);
    signal ch0_data_valid      : std_logic;
    signal ch0_data            : std_logic_vector(7 downto 0);
    signal ch0_guardband_valid : std_logic;
    signal ch0_guardband       : std_logic_vector (0 downto 0);
    signal ch0_delay_count     : std_logic_vector (4 downto 0);
    signal ch0_delay_ce        : STD_LOGIC;
    signal ch0_bitslip         : STD_LOGIC;
    signal ch0_symbol_sync     : STD_LOGIC;

    signal ch0_invalid_symbol_1  : std_logic;
    signal ch0_ctl_valid_1       : std_logic;
    signal ch0_ctl_1             : std_logic_vector(1 downto 0);
    signal ch0_terc4_valid_1     : std_logic;
    signal ch0_terc4_1           : std_logic_vector (3 downto 0);
    signal ch0_data_valid_1      : std_logic;
    signal ch0_data_1            : std_logic_vector(7 downto 0);
    
    signal ch1_invalid_symbol  : std_logic;
    signal ch1_ctl_valid       : std_logic;
    signal ch1_ctl             : std_logic_vector(1 downto 0);
    signal ch1_terc4_valid     : std_logic;
    signal ch1_terc4           : std_logic_vector (3 downto 0);
    signal ch1_data_valid      : std_logic;
    signal ch1_data            : std_logic_vector(7 downto 0);
    signal ch1_guardband_valid : std_logic;
    signal ch1_guardband       : std_logic_vector (0 downto 0);
    signal ch1_delay_count     : std_logic_vector (4 downto 0);
    signal ch1_delay_ce        : STD_LOGIC;
    signal ch1_bitslip         : STD_LOGIC;
    signal ch1_symbol_sync     : STD_LOGIC;

    signal ch1_invalid_symbol_1  : std_logic;
    signal ch1_ctl_valid_1       : std_logic;
    signal ch1_ctl_1             : std_logic_vector(1 downto 0);
    signal ch1_terc4_valid_1     : std_logic;
    signal ch1_terc4_1           : std_logic_vector (3 downto 0);
    signal ch1_data_valid_1      : std_logic;
    signal ch1_data_1            : std_logic_vector(7 downto 0);
    
    signal ch2_invalid_symbol  : std_logic;
    signal ch2_ctl_valid       : std_logic;
    signal ch2_ctl             : std_logic_vector(1 downto 0);
    signal ch2_terc4_valid     : std_logic;
    signal ch2_terc4           : std_logic_vector (3 downto 0);
    signal ch2_data_valid      : std_logic;
    signal ch2_data            : std_logic_vector(7 downto 0);
    signal ch2_guardband_valid : std_logic;
    signal ch2_guardband       : std_logic_vector (0 downto 0);
    signal ch2_delay_count     : std_logic_vector (4 downto 0);
    signal ch2_delay_ce        : STD_LOGIC;
    signal ch2_bitslip         : STD_LOGIC;
    signal ch2_symbol_sync     : STD_LOGIC;

    signal ch2_invalid_symbol_1  : std_logic;
    signal ch2_ctl_valid_1       : std_logic;
    signal ch2_ctl_1             : std_logic_vector(1 downto 0);
    signal ch2_terc4_valid_1     : std_logic;
    signal ch2_terc4_1           : std_logic_vector (3 downto 0);
    signal ch2_data_valid_1      : std_logic;
    signal ch2_data_1            : std_logic_vector(7 downto 0);
    
    
    signal reset_counter  : unsigned(7 downto 0) := (others => '1');

    signal vdp_prefix_detect    : std_logic_vector(7 downto 0) := (others => '0');
    signal vdp_guardband_detect : std_logic := '0';
    signal vdp_prefix_seen      : std_logic := '0';
    signal in_vdp               : std_logic := '0';

    signal adp_prefix_detect    : std_logic_vector(7 downto 0) := (others => '0');
    signal adp_guardband_detect : std_logic := '0'; 
    signal adp_prefix_seen      : std_logic := '0';
    signal in_adp               : std_logic := '0';
    signal dvid_mode            : std_logic := '1';
    signal last_was_ctl         : std_logic := '0';
    
    signal in_dvid              : std_logic := '0';
    signal symbol_sync_i        : std_logic := '0';
begin
    pll_locked  <= locked;
    symbol_sync <= symbol_sync_i;
    reset       <= std_logic(reset_counter(reset_counter'high));    
    symbol_ch0  <= ch0_symbol;
    symbol_ch1  <= ch1_symbol;
    symbol_ch2  <= ch2_symbol;
    
--    debug       <= ch2_invalid_symbol & ch1_invalid_symbol & ch0_invalid_symbol & dvid_mode & locked & symbol_sync_i;
--    debug <= raw_ch0(5 downto 0);
    debug <= ch0_data(0) & ch0_ctl_valid & hdmi_detected & raw_ch0(2) & raw_ch0(1) & raw_ch0(0);

    pixel_clk       <= clk_pixel;
    pixel_io_clk_x1 <= clk_pixel_x1;
    pixel_io_clk_x5 <= clk_pixel_x5;

ch0: entity work.input_channel Port map ( 
        clk             => clk_pixel,
        ce              => ser_ce,
        clk_x1          => clk_pixel_x1,
        clk_x5          => clk_pixel_x5,
        serial          => hdmi_in_ch0,
        invalid_symbol  => ch0_invalid_symbol,
        symbol          => ch0_symbol,
        ctl_valid       => ch0_ctl_valid,
        ctl             => ch0_ctl,
        terc4_valid     => ch0_terc4_valid,
        terc4           => ch0_terc4,
        guardband_valid => ch0_guardband_valid,
        guardband       => ch0_guardband,
        data_valid      => ch0_data_valid,
        data            => ch0_data,
        reset           => ser_reset,
        symbol_sync     => ch0_symbol_sync);

ch1: entity work.input_channel Port map ( 
        clk             => clk_pixel,
        ce              => ser_ce,
        clk_x1          => clk_pixel_x1,
        clk_x5          => clk_pixel_x5,
        serial          => hdmi_in_ch1,
        symbol          => ch1_symbol,
        invalid_symbol  => ch1_invalid_symbol,
        ctl_valid       => ch1_ctl_valid,
        ctl             => ch1_ctl,
        terc4_valid     => ch1_terc4_valid,
        terc4           => ch1_terc4,
        guardband_valid => ch1_guardband_valid,
        guardband       => ch1_guardband,
        data_valid      => ch1_data_valid,
        data            => ch1_data,
        reset           => ser_reset,
        symbol_sync     => ch1_symbol_sync);

ch2: entity work.input_channel Port map ( 
        clk             => clk_pixel,
        ce              => ser_ce,
        clk_x1          => clk_pixel_x1,
        clk_x5          => clk_pixel_x5,
        serial          => hdmi_in_ch2,
        invalid_symbol  => ch2_invalid_symbol,
        symbol          => ch2_symbol,
        ctl_valid       => ch2_ctl_valid,
        ctl             => ch2_ctl,
        terc4_valid     => ch2_terc4_valid,
        terc4           => ch2_terc4,
        guardband_valid => ch2_guardband_valid,
        guardband       => ch2_guardband,
        data_valid      => ch2_data_valid,
        data            => ch2_data,
        reset           => ser_reset,
        symbol_sync     => ch2_symbol_sync);

    symbol_sync_i <= ch0_symbol_sync and ch1_symbol_sync and ch2_symbol_sync;
    
    hdmi_detected <= not dvid_mode;
hdmi_section_decode: process(clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            -------------------------------------------------------------------
            -- Output the values depending on what sort of data block we are in
            -------------------------------------------------------------------
            if ch0_ctl_valid = '1' and ch1_ctl_valid = '1' and ch2_ctl_valid = '1' then
                -------------------------------------------------------------------
                -- As soon as we see avalid CTL symbols we are no longer in the   
                -- video or aux data period it doesn't have any trailing guard band
                -------------------------------------------------------------------
                in_vdp    <= '0';
                in_adp    <= '0';
                in_dvid   <= '0';
                raw_vsync <= ch0_ctl(1);
                raw_hsync <= ch0_ctl(0);
                raw_blank <= '1';            
                raw_ch2   <= (others => '0');
                raw_ch1   <= (others => '0');
                raw_ch0   <= (others => '0');
                last_was_ctl   <= '1';
                adp_data_valid <= '0';
            else
                last_was_ctl <= '0';
                adp_data_valid <= '0';
                if in_vdp = '1' then
                    raw_vsync <= '0';
                    raw_hsync <= '0';
                    raw_blank <= '0';            
                    raw_ch2   <= ch2_data;
                    raw_ch1   <= ch1_data;
                    raw_ch0   <= ch0_data;
                    if ch2_invalid_symbol = '1' or ch2_invalid_symbol = '1' or ch2_invalid_symbol = '1' then
                        raw_ch2   <= x"EF";
                        raw_ch1   <= x"16";
                        raw_ch0   <= x"16";
                    end if;
            
                elsif in_dvid = '1' then
                    -- In the Video data period
                    raw_vsync <= '0';
                    raw_hsync <= '0';
                    raw_blank <= '0';            
                    raw_ch2   <= ch2_data;
                    raw_ch1   <= ch1_data;
                    raw_ch0   <= ch0_data;
                elsif in_adp = '1' then
                    -- In the Aux Data Period Period
                    raw_vsync <= ch0_terc4(1);
                    raw_hsync <= ch0_terc4(0);
                    raw_blank <= '1';            
                    raw_ch0   <= (others => '0');
                    raw_ch1   <= (others => '0');
                    raw_ch2   <= (others => '0');
                    -- ADP data extraction
                    adp_data_valid      <= '1';
                    adp_header_bit      <= ch0_terc4(2);
                    adp_frame_bit       <= ch0_terc4(3);
                    adp_subpacket0_bits <= ch2_terc4(0) & ch1_terc4(0);
                    adp_subpacket1_bits <= ch2_terc4(1) & ch1_terc4(1);
                    adp_subpacket2_bits <= ch2_terc4(2) & ch1_terc4(2);
                    adp_subpacket3_bits <= ch2_terc4(3) & ch1_terc4(3);
                end if;
            end if;
               
            ------------------------------------------------------------
            -- We need to detect 8 ADP or VDP prefix characters in a row
            ------------------------------------------------------------
            vdp_prefix_detect <= vdp_prefix_detect(6 downto 0) & '0';
            vdp_prefix_seen <= '0';
            if ch0_ctl_valid = '1' and ch1_ctl_valid = '1' and ch1_ctl_valid = '1' then
                if ch1_ctl = "01" and ch2_ctl = "00" then
                    vdp_prefix_detect(0) <=  '1';
                    if vdp_prefix_detect = "01111111" then
                        vdp_prefix_seen <= '1';
                    end if;
                end if;
            end if;
                
            ---------------------------------------------
            -- See if we can detect the ADP guardband
            --
            -- The ADP guardband includes HSYNC and VSYNC
            -- encoded in TERC4 coded in Ch0.
            ---------------------------------------------
            adp_prefix_detect <= adp_prefix_detect(6 downto 0) & '0';
            adp_prefix_seen <= '0';
            if ch0_ctl_valid = '1' and ch1_ctl_valid = '1' and ch1_ctl_valid = '1' then
                if ch1_ctl = "01" and ch2_ctl = "01" then
                    adp_prefix_detect(0) <= '1';
                    if adp_prefix_detect = "01111111" then
                        adp_prefix_seen <= '1';
                    end if;
                end if;
            end if;
            ---------------------------------------------
            -- See if we can detect the ADP guardband
            --
            -- The ADP guardband includes HSYNC and VSYNC
            -- encoded in TERC4 coded in Ch0 - annoying!
            ---------------------------------------------
            adp_guardband_detect <= '0';
            if in_vdp = '0' and ch0_terc4_valid = '1' and ch1_guardband_valid = '1' and ch1_guardband_valid = '1' then
                if ch0_terc4(3 downto 2) = "11" and ch1_guardband = "0" and ch2_guardband = "0" then
                    raw_vsync <= ch0_terc4(1);
                    raw_hsync <= ch0_terc4(0);
                    adp_guardband_detect <= adp_prefix_seen;
                    in_adp <= adp_guardband_detect AND (not in_adp) and (not in_vdp);
                end if;
            end if;
            -----------------------------------------
            -- See if we can detect the VDP guardband
            -- This is pretty nice as the guard
            -----------------------------------------
            vdp_guardband_detect <= '0';                        
            if ch0_guardband_valid = '1' and ch1_guardband_valid = '1' and ch2_guardband_valid = '1' then
                -- TERC Coded for the VDP guard band.
                if ch0_guardband = "1" and ch1_guardband = "0" and ch2_guardband = "1" then
                   vdp_guardband_detect <= vdp_prefix_seen;
                   in_vdp <= vdp_guardband_detect AND (not in_adp) and (not in_vdp);
                   dvid_mode <= '0';
                end if;
            end if;
            --------------------------------
            -- Is this some DVID video data?
            --------------------------------
            if dvid_mode = '1' and last_was_ctl = '1' and ch0_data_valid = '1' and ch1_data_valid = '1' and ch2_data_valid = '1' then
                in_dvid <= '1';
            end if;
            -------------------------------------------------------------
            -- Is this an un-announced video data? If so we receiving 
            -- DVI-D data, and not HDMI 
            -------------------------------------------------------------
            if ch0_data_valid = '1' and ch1_data_valid = '1' and ch2_data_valid = '1' 
                and last_was_ctl = '1' and vdp_prefix_seen = '0' and adp_prefix_seen = '0' then
               dvid_mode <= '1';
            end if;

            ch0_invalid_symbol_1 <= ch0_invalid_symbol;
            ch0_ctl_valid_1      <= ch0_ctl_valid;
            ch0_ctl_1            <= ch0_ctl;
            ch0_terc4_valid_1    <= ch0_terc4_valid;
            ch0_terc4_1          <= ch0_terc4;
            ch0_data_1           <= ch0_data;

            ch1_invalid_symbol_1 <= ch1_invalid_symbol;
            ch1_ctl_valid_1      <= ch1_ctl_valid;
            ch1_ctl_1            <= ch1_ctl;
            ch1_terc4_valid_1    <= ch1_terc4_valid;
            ch1_terc4_1          <= ch1_terc4;
            ch1_data_1           <= ch1_data;

            ch2_invalid_symbol_1 <= ch2_invalid_symbol;
            ch2_ctl_valid_1      <= ch2_ctl_valid;
            ch2_ctl_1            <= ch2_ctl;
            ch2_terc4_valid_1    <= ch2_terc4_valid;
            ch2_terc4_1          <= ch2_terc4;
            ch2_data_valid_1     <= ch2_data_valid;
            ch2_data_1           <= ch2_data;
        end if;
    end process;
    
------------------------------------------
-- Reset the receivers if PLL lock is lost
------------------------------------------
reset_proc: process(system_clk)
    begin
        if rising_edge(system_clk) then
            if locked = '1' then
                if reset_counter > 0 then
                    reset_counter <= reset_counter-1;
                end if;
            else
                reset_counter <= (others => '1');
            end if;
        end if;
    end process;

reset_proc2: process(clk_pixel)
    begin
        if rising_edge(clk_pixel) then
            ser_reset <= reset_counter(reset_counter'high);
            ser_ce    <= not ser_reset; 
        end if;
    end process;
end Behavioral;
