// Bohdan Purtell
// University of Florida

module locator_generator # (
  parameter int width = 32
) (
  input logic clk, rst, en,

  input logic [orderid_width - 1 : 0] order_id,

  input logic [addr_width - 1 : 0] ram_addr,
  input logic [level_width - 1 : 0] level,
  input logic [slot_width - 1 : 0] slot,

  input logic [price_width - 1 : 0] price_data,

  input logic [31:0] verison,

  output logic [31:0] locator_entry
);

free_list # (

) free_list (

);

endmodule

