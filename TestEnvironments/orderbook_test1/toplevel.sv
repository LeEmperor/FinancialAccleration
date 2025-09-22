// Bohdan Purtell
// University of Florida
// Toplevel for Orderbook

module toplevel # (
  parameter int width = 32
) (
  input logic clk, rst, en,

  input logic [width - 1 : 0] t_data,
  output logic tx
);

// buyside orderbook
orderbook # (
  .data_width(32),
  .book_depth(5)
) buy1 (
  .clk(clk),
  .rst(rst),
  .en(),

  .new_price(),
  .valid(),
  .rdy(),

  .occupied_mask(),

  .bid1_price(),
  .bid2_price(),
  .bid3_price(),
  .bid4_price(),
  .bid5_price()
);

// sellside orderbook
orderbook # (
  .data_width(32),
  .book_depth(5)
) sell1 (
  .clk(clk),
  .rst(rst),
  .en(),

  .new_price(),
  .valid(),
  .rdy(),

  .occupied_mask(),

  .bid1_price(),
  .bid2_price(),
  .bid3_price(),
  .bid4_price(),
  .bid5_price()
);

// controller
controller # (
  .packet_width(32)
) controller (
  .clk(clk),
  .rst(rst),
  .en(),

  .indata(),
  .sop(),
  .eop(),
  .wren(),

  .buyside_valid_array(),
  .sellside_valid_array()
);

endmodule

