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

  rbzero rbzero(
    .clk    (clk),
    .reset  (~rst_n),
    .i_sclk (ui_in[0]),
    .i_mosi (ui_in[1]),
    .i_ss_n (ui_in[2]),
    .hsync_n(uo_out[0]),
    .vsync_n(uo_out[1]),
    .rgb    (uo_out[7:2])
  );

  // All bidir pins configured as inputs for now. Not using them yet:
  assign uio_oe   = 8'b0;
  assign uio_out  = 8'b0;

endmodule
