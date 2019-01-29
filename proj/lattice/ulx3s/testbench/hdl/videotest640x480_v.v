module videotest640x480_v
(
  input clk_pixel, //  25 MHz
  input clk_shift, // 250 MHz
  output reg [7:0] out_red, out_green, out_blue, // VGA test picture, pixel data
  output reg out_hsync, out_vsync, out_blank, // VGA test picture, signaling
  output [3:0] out_p, out_n // VGA test picture, TMDS encoded
);
    parameter C_ddr = 1'b0; // 0:SDR 1:DDR

    // VGA signal generator
    wire [7:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, vga_blank;
    vga
    vga_instance
    (
      .clk_pixel(clk_pixel),
      .test_picture(1'b1), // enable test picture generation
      .vga_r(vga_r),
      .vga_g(vga_g),
      .vga_b(vga_b),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_blank(vga_blank)
    );
    
    always @(posedge clk_pixel)
    begin
      out_hsync <= vga_hsync;
      out_vsync <= vga_vsync;
      out_blank <= vga_blank;
      out_red   <= vga_r;
      out_green <= vga_g;
      out_blue  <= vga_b;
    end

    // VGA to digital video converter
    wire [1:0] tmds[3:0];
    vga2dvid
    #(
      .C_ddr(C_ddr)
    )
    vga2dvid_instance
    (
      .clk_pixel(clk_pixel),
      .clk_shift(clk_shift),
      .in_red(vga_r),
      .in_green(vga_g),
      .in_blue(vga_b),
      .in_hsync(vga_hsync),
      .in_vsync(vga_vsync),
      .in_blank(vga_blank),
      .out_clock(tmds[3]),
      .out_red(tmds[2]),
      .out_green(tmds[1]),
      .out_blue(tmds[0])
    );

    // output TMDS SDR/DDR data to fake differential lanes
    fake_differential
    #(
      .C_ddr(C_ddr)
    )
    fake_differential_instance
    (
      .clk_shift(clk_shift),
      .in_clock(tmds[3]),
      .in_red(tmds[2]),
      .in_green(tmds[1]),
      .in_blue(tmds[0]),
      .out_p(out_p),
      .out_n(out_n)
    );

endmodule
