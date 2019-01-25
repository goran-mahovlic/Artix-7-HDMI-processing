# ******* project, board and chip name *******
PROJECT = dvicapture
BOARD = ulx3s
# 12 25 45 85
FPGA_SIZE = 25

FPGA_PACKAGE = 6bg381c
# config flash: 1:SPI (standard), 4:QSPI (quad)
FLASH_SPI = 4
# chip: is25lp032d is25lp128f s25fl164k
FLASH_CHIP = is25lp128f

# ******* design files *******
CONSTRAINTS = ../constraints/ulx3s_v20.lpf
TOP_MODULE = top_testbench
TOP_MODULE_FILE = hdl/$(TOP_MODULE).vhd
# ../../../../src/hdmi_design.vhd

CLK0_NAME = clk_25_v
CLK0_FILE_NAME = clocks/$(CLK0_NAME).v
CLK0_OPTIONS = \
  --input=25 \
  --output=250 \
  --s1=125 \
  --p1=0 \
  --s2=25 \
  --p2=0 \
  --s3=100

CLK1_NAME = clk_video_v
CLK1_FILE_NAME = clocks/$(CLK1_NAME).v
CLK1_OPTIONS = \
  --input=25 \
  --output=250 \
  --s1=125 \
  --p1=0 \
  --s2=25 \
  --p2=0 \
  --s3=25 \
  --p3=0

VERILOG_FILES = \
  $(CLK0_FILE_NAME) \
  $(CLK1_FILE_NAME) \
  hdl/fake_differential.v \
  hdl/videotest640x480_v.v

VHDL_FILES = \
  $(TOP_MODULE_FILE) \
  clocks/clk_25.vhd \
  clocks/clk_video.vhd \
  hdl/blink.vhd \
  hdl/vga.vhd \
  hdl/tmds_encoder.vhd \
  hdl/vga2dvid.vhd \
  hdl/videotest640x480.vhd \
  ../../../../src/edid_rom.vhd

# ../../../../src/hdmi_design.vhd

SCRIPTS = ../scripts
include $(SCRIPTS)/ulx3s_diamond.mk
