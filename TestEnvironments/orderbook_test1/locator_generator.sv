// Bohdan Purtell
// University of Florida

module locator_generator # (
  parameter int data_width = 32,
  parameter int addr_width = 10,
  parameter int level_width = 3,
  parameter int slot_width = 3,
  parameter int orderid_width = 10
) (
  input logic clk, rst, en,

  input logic [order_id - 1 : 0] order_id,

  input logic [addr_width - 1 : 0] ram_addr,
  input logic [level_width - 1 : 0] level,
  input logic [slot_width - 1 : 0] slot,

  output logic [31:0] locator_entry
);

always_comb
begin

  locator_entry = 

end

endmodule

