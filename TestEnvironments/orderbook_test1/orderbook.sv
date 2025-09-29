// Bohdan Purtell
// University of Florida

module orderbook # (
  parameter int data_width = 64
) (
  input logic clk, rst, en,

  input  logic valid,
  output logic rdy,
  input logic sop,
  input logic eop,

  input logic [data_width - 1 : 0] indata,
);

// beat 0
// [63:60] msg_type     4   (ADD=1, MOD=2, CAN=3, EXEC=4, SNAP=5)
// [59]    side         1   (0=bid, 1=ask)    // for ADD/MOD reprice
// [58:56] reserved     3
// [55:48] level_hint   8   (optional fast path; else compute from price)
// [47:32] qty          16  (or 32 if you can spare bits; see below)
// [31:0]  order_id_h   32  (upper half or whole id if 32-bit)

// beat 1
// [63:32] order_id_l   32  (lower half; or zeros if 32-bit ids)
// [31:0]  price_ticks  32  (unsigned ticks)

// beat 2
// [63]    reprice_en   1
// [62:48] reserved     15
// [47:16] qty_delta    32  (signed)
// [15:0]  user_tag     16

// beat 0 wires
logic [3:0] wire_msg_type;
logic wire_side;
logic [2:0] wire_reserved1;
logic [7:0] wire_level_hint;
logic [15:0] wire_qty;
logic [31:0] wire_order_id_h;

// beat 1 wires
logic [31:0] wire_order_id_l;
logic [31:0] wire_price_ticks;

// beat 2
logic wire_reprice_en; 
logic [14:0] wire_reserved2;
logic [31:0] wire_qty_delta;
logic [15:0] wire_user_tag;

// wire ties
always_comb
begin
  // beat 0
  wire_msg_type = indata[63:60];
  wire_side = indata[59];
  wire_reserved1 = indata[58:56];
  wire_level_hint = indata[55:48];
  wire_qty = indata[47:32];
  wire_order_id_h = indata[31:0];

  // beat 1
  wire_order_id_l = indata[63:32];
  wire_price_ticks = indata[31:0];

  // beat 2
  wire_reprice_en = indata[63];
  wire_reserved2 = indata[62:48];
  wire_qty_delta = indata[47:16];
  wire_user_tag = indata[15:0];
end



endmodule

