// typedef struct packed {
//   logic event_type;
//   logic [31:0] id;
//   logic [31:0] price;
//   logic [31:0] qty;
// } event_t;

module dummy_top (
  input logic clk, rst,
  output logic bruh
);

//(* keep = "true" *) wire debug_status;

feed_parser bruh (
  .clk(), 
  .rst(),
  .tx_clk(),
  .rx_clk(),

  .s_axis_tdata(),
  .s_axis_tkeep(),
  .s_axis_tuser_size(),
  .s_axis_tuser_dst(),
  .s_axis_tuser_src(),

  .s_axis_tlast(),
  .s_axis_tvalid(),
  .s_axis_tready(),

  .order_id(),

  .event1(),
  .event2(),
  .event3(),
  .event4(),
  .event5(),
  .event6(),
  .event7(),
  .event8(),
  .event9(),
  .event10()
);


endmodule

