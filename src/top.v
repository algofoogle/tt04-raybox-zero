`default_nettype none
`timescale 1ns / 1ps

// `define USE_MAP_OVERLAY
// `define USE_DEBUG_OVERLAY
// `define TRACE_STATE_DEBUG  // Trace state is represented visually per each line on-screen.

module tt_um_algofoogle_raybox_zero(
  input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
  output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
  input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
  output wire [7:0] uio_out,  // IOs: Bidirectional Output path
  output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // will go high when the design is enabled
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  wire [5:0]  rgb;
  wire        vsync_n, hsync_n;
  wire [7:0]  unregistered_vga_output = {rgb, vsync_n, hsync_n};
  reg [7:0]   registered_vga_output;

  always @(posedge clk) registered_vga_output <= unregistered_vga_output;

  wire i_reg = ui_in[6];
  assign uo_out = i_reg ? registered_vga_output : unregistered_vga_output;

  rbzero rbzero(
    .clk      (clk),
    .reset    (~rst_n),

    // SPI slave interface.
    //NOTE: These are internally synchronised.
    .i_sclk   (ui_in[0]),
    .i_mosi   (ui_in[1]),
    .i_ss_n   (ui_in[2]),

    // Debug/demo signals:
    //SMELL: These are NOT internally synchronised. Should they be?
    // Since they're just for simple demo purposes, and not typically used, I think they're fine as-is:
    .i_debug  (ui_in[3]),
    .i_inc_px (ui_in[4]),
    .i_inc_py (ui_in[5]),

    // VGA output signals:
    .hsync_n  (hsync_n),
    .vsync_n  (vsync_n),
    .rgb      (rgb),

    // Other outputs:
    .o_hblank (uio_out[0]),
    .o_vblank (uio_out[1])
  );

  assign uio_oe       = 8'b0000_0011; // 1 = output, 0 = input.
  assign uio_out[7:2] = 6'b0000_00; // Unused.

endmodule
