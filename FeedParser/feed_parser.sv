// Bohdan Purtell
// University of Florida
// Feed Parser CMAC Interactive Layer

module feed_parser # (
  parameter int DATA_WIDTH = 512,
  parameter int KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int USER_SIZE_WIDTH = 16,
  parameter int USER_SRC_WIDTH = 16,
  parameter int USER_DST_WIDTH = 16
) (
  // clk and rst
  input logic clk, rst,
  input logic tx_clk,
  input logic rx_clk,

  // CMAC AXI4-Stream Signals
  input logic [DATA_WIDTH - 1 : 0]        s_axis_tdata,
  input logic [KEEP_WIDTH - 1 : 0]        s_axis_tkeep,
  input logic [USER_SIZE_WIDTH - 1 : 0]   s_axis_tuser_size,
  input logic [USER_DST_WIDTH  - 1 : 0]   s_axis_tuser_dst,
  input logic [USER_SRC_WIDTH  - 1 : 0]   s_axis_tuser_src,

  input logic s_axis_tlast,
  input logic s_axis_tvalid,
  output logic s_axis_tready,

  // feed parser internals
  
  output logic [31:0] order_id
);






endmodule
