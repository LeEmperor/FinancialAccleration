// Bohdan Purtell
// University of Florida
// Description: Orderbook

module orderbook (
  // clk, rst, en
  input logic clk_hifreq,
  input logic rst,
  input logic en,

  // bus
  // input logic [31:0] in_data,
  input logic valid,
  output logic rdy,

  // price data
  input logic [31:0] new_price,

  output logic [31:0] bid1_price,
  output logic [31:0] bid2_price,
  output logic [31:0] bid3_price,
  output logic [31:0] bid4_price,
  output logic [31:0] bid5_price,
  // output logic [31:0] bid6_price,
  // output logic [31:0] bid7_price,
  // output logic [31:0] bid8_price,
  // output logic [31:0] bid9_price,
  // output logic [31:0] bid10_price,

  output logic [9:0] occupied_mask
);

logic lessthan_bitmask [0:9];
logic [31:0] orderbook [10];

always_comb
begin
  for (int i = 0; i < 5; i++) begin
    // lessthan_bitmask[i] = (new_price > books[i].tick) ? 0 : 1;
    if (new_price > orderbook[i]) begin
      lessthan_bitmask[i] = 1;
    end else begin
      lessthan_bitmask[i] = 0;
    end
  end
end

// int insertion_index;
logic [4:0] insertion_index;

// set the insertion index
always_comb
begin
  for (int i = 0; i < 5; i++) begin
    if (lessthan_bitmask[i] == 1) begin
      insertion_index = i;
    end
  end
end

// occupied
always_comb
begin
  for(int i = 0; i < 5; i++) begin
    if (orderbook[i] != 0) begin
      // occupied_mask[10'b1 << i] = 1;
      occupied_mask[i] = 1;
    end else begin
      // occupied_mask[10'b1 << i] = 0;
      occupied_mask[i] = 0;
    end

  end
end

// description: 1 process model??
// vs 2 process model pour ça
always_ff @(posedge clk_hifreq)
begin
  if (rst) begin
    for (int i = 0; i < 5; i++) begin
      orderbook[i] <= 0;
    end
  end else if (valid) begin
    for (int i = 0; i < insertion_index; i++) begin
      orderbook[i] <= orderbook[i + 1];
      // 1 process modele pour ća, mais un 2 process avec current et next état
      // pour chaque price reg? space est double? je sais pas
    end

    orderbook[insertion_index] <= new_price;
  end
end

endmodule

