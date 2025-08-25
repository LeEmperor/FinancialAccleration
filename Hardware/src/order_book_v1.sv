// Bohdan Purtell
// University of Florida

module order_book_v1 # (
  parameter int WIDTH = 64,
  parameter int PRICE_STARTING_INDEX = 62, // 32 bit inte
  parameter int PRICE_ENDING_INDEX = 31
) (
  input clk, rst,

  input logic [63:0] slave_tdata,
  input logic slave_tvalid,

  output logic [63:0] bruh,

  output logic [9:0][31:0] bidprices_out,
  output logic [9:0][31:0] bidquantities_out,

  output logic [31:0] bid0_price,
  output logic [31:0] bid1_price,
  output logic [31:0] bid2_price,
  output logic [31:0] bid3_price,
  output logic [31:0] bid4_price,
  output logic [31:0] bid5_price,
  output logic [31:0] bid6_price,
  output logic [31:0] bid7_price,
  output logic [31:0] bid8_price,
  output logic [31:0] bid9_price,

  output logic [31:0] bid0_quantity,
  output logic [31:0] bid1_quantity,
  output logic [31:0] bid2_quantity,
  output logic [31:0] bid3_quantity,
  output logic [31:0] bid4_quantity,
  output logic [31:0] bid5_quantity,
  output logic [31:0] bid6_quantity,
  output logic [31:0] bid7_quantity,
  output logic [31:0] bid8_quantity,
  output logic [31:0] bid9_quant
);

// priority encoding
function automatic int firstTrue (input logic [9 : 0] in_arr);
  for (int i = 0; i < 9; i++) begin
    if (in_arr[i] == 1'b1)
      return i;
  end

  return 15; // not found
endfunction

typedef struct { // packed?
  // logic side;
  logic [31:0] tick;
  logic [31:0] quantity;
} level_t;

typedef enum {
  IDLE

} state_t;

logic side;
logic [31:0] new_tick_price;
logic [31:0] new_tick_quantity;

localparam int N = 10;
state_t current_state, next_state;
level_t bids [N];
level_t asks [N];
int equal_pos_bid; // voudrait-être registré
int insert_pos_bid;

int splice_index;
int replace_index;

logic [31:0] best_ask_tick;
logic [31:0] best_buy_tick;

logic [N-1:0] better_mask_buy; // better than
logic [N-1:0] equal_mask_buy; // equal to

logic [N-1:0] better_mask_ask;
logic [N-1:0] equal_mask_ask;

logic [3:0] n_bids;

// diagnostique -------------------------------------
always_comb
begin
  for(int i = 0; i < N; i++) begin
    bidprices_out[i] = bids[i].tick;
    bidquantities_out[i] = bids[i].quantity;
  end
end
// diagnostique -------------------------------------

assign insert_pos_bid = firstTrue(better_mask_buy);
assign equal_pos_bid = firstTrue(equal_mask_buy);
assign new_tick_price = slave_tdata[63:32];
assign new_tick_quantity = slave_tdata[31:0];

// reg block
// always_ff @(posedge clk)
// begin
//   if (rst) begin
//     current_state <= IDLE;
//     best_ask_tick <= 0;
//     best_buy_tick <= 0;
//     for(int i = 0; i < N; i++) begin
//       bids[i].tick = 0;
//       bids[i].quantity = 0;
//     end
//   end else begin
//     current_state <= next_state;
//   end
// end

// bid mask logic
always_comb
begin
  for (int i = 0; i < N; i++) begin
    better_mask_buy[i] = (new_tick_price >= bids[i].tick);
    equal_mask_buy[i] = (new_tick_price == bids[i].tick);
  end
end

// ask mask logic
always_comb 
begin
  for (int i = 0; i < N; i++) begin
    better_mask_ask[i] = (new_tick_price <= asks[i].tick);
    equal_mask_ask[i] = (new_tick_price == asks[i].tick);
  end
end

always_ff @(posedge clk)
begin
  if (rst) begin
    for(int i = 0; i < N; i++) begin
      bids[i].tick <= 0;
      bids[i].quantity <= 0;
      n_bids <= 0;
    end
  end else begin
    if (slave_tvalid) begin
      if (insert_pos_bid < N) begin
        // int last = (n_bids < N) ? n_bids : (N-1);
        
        splice_index = (n_bids < N) ? n_bids : (N-1);

        // shift 
        for (int j = splice_index; j < N; j++) begin
          bids[j] <= bids[j-1];
        end

        // new item
        bids[insert_pos_bid].tick <= new_tick_price;
        bids[insert_pos_bid].quantity <= new_tick_quantity;

        if (n_bids < N) n_bids <= n_bids + 1;
      end
    end
  end
end

endmodule

