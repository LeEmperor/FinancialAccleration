// Bohdan Purtell
// University of Florida

module orderbook # (
  parameter int data_width = 32
) (
  input logic clk, rst, en
  output logic [data_width - 1 : 0] dataout
);

orderbook_storage # (
  .data_width(data_width)
  .book_depth(5)
) storage1 (
  .clk(),
  .rst(),
  .en(),

  .valid(),
  .rdy(),

  .new_price(),
  .occupied_mask()
);



endmodule

