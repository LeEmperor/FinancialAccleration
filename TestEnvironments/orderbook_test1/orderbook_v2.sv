// Bohdan Purtell
// University of Florida
// Description: Orderbook 2

module orderbook_v2 (
  // clk, rst, en
  input logic clk_hifreq,
  input logic rst,
  input logic en,

  // bus
  input logic [31:0] in_data,
  input logic valid,
  output logic rdy,

  // price data
  input logic [31:0] new_price,

  output logic [31:0] bid1_price,
  output logic [31:0] bid2_price,
  output logic [31:0] bid3_price,
  output logic [31:0] bid4_price,
  output logic [31:0] bid5_price,
  output logic [31:0] bid6_price,
  output logic [31:0] bid7_price,
  output logic [31:0] bid8_price,
  output logic [31:0] bid9_price,
  output logic [31:0] bid10_price

);

typedef struct {
  logic [31:0] tick;
} level_t;
logic [9:0] lessthan_bitmask;
level_t books [10];

logic [31:0] orderbook2 [0:4];

always_comb
begin
  for (int i = 0; i < 10; i++) begin
    // lessthan_bitmask[i] = (new_price > books[i].tick) ? 0 : 1;
    if (in_data > books[i].tick) begin
      lessthan_bitmask[i] = 1;
    end else begin
      lessthan_bitmask[i] = 0;
    end
  end
end

int insertion_index;

// set the insertion index
always_comb
begin
  for (int i = 0; i < 10; i++) begin
    if (lessthan_bitmask[i] == 1) begin
      insertion_index = i;
    end
  end
end

level_t new_item;

always_comb
begin
  // setup an insertable item
  new_item.tick = in_data;
end

// description: 1 process model??
// vs 2 process model pour ça
always_ff @(posedge clk_hifreq)
begin
  if (valid) begin
    orderbook2[insertion_index] <= in_data;
    // books[insertion_index] <= new_item;
  end
end

endmodule

