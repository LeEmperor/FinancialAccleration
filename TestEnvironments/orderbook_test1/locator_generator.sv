// Bohdan Purtell
// University of Florida

module locator_generator # (
  parameter int data_width = 32,
  parameter int addr_width = 10,
  parameter int level_width = 3,
  parameter int slot_width = 3,
  parameter int orderid_width = 10,
  parameter int price_width = 32,
  parameter int version_width = 5,

  parameter int n_levels = 8,  
  parameter int n_slots = 5
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

// typedef struct packed {
//   logic valid;
//   logic [version_width - 1 : 0] version;
//   logic [orderid_width - 1 : 0] order_id;
//   logic [31:0] qty;
//   logic [5:0] next;
//   logic [5:0] prev;
// } slot_t;
//
// slot_t slots[10][10];

typedef struct packed {
  logic [31:0] price;
  logic [31:0] quantity;
  logic [63:0] epoch;
} order_t;

order_t orders[n_levels * n_slots];

logic [31:0] fast_locator_table [];
// assign locator_entry = fast_locator_table[order_id];

// logic [price_width - 1 : 0] level_idx = price_data;

always_comb
begin

  // locator_entry = {};


  // locator_entry = {};

end

// always_ff @(posedge bruh)
// begin
//   if (bruh) begin
//
//   end
// end

endmodule

