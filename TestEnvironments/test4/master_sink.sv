// Bohdan Purtell
// University of Florida

module master_sink (
  input logic clk_hifreq, rst,

  input logic [3:0] rx_d, 
  input logic rx_en,
  input logic rx_err,
  input logic rx_valid,

  // sorties
  input logic [16:0] switches,
  input logic [3:0] buttons,
  output logic [7:0] leds_green,
  output logic [17:0] leds_red,

  output logic [6:0] hex0,
  output logic [6:0] hex1,
  output logic [6:0] hex2,
  output logic [6:0] hex3,
  output logic [6:0] hex4,
  output logic [6:0] hex5,
  output logic [6:0] hex6,
  output logic [6:0] hex7

);

logic wire_pulse;

logic [31:0] wire_avalonMM_data;
logic [7:0]  wire_avalonMM_addr;
logic        wire_avalonMM_wren;
logic        wire_avalonMM_busy;

logic [31:0] wire_avalonST_data;

clk_div1 full_second (
  .clk50(clk_hifreq),
  .rst(rst),
  .clk1(),
  .pulse(wire_pulse)
);

eth1_config ise1 (
  .clk_hifreq(clk_hifreq),
  .rst(rst),
  .reg_addr(wire_avalonMM_addr),
  .busy(wire_avalonMM_busy),
  .data_out(wire_avalonMM_data),
  .wren(wire_avalonMM_wren)
);

ethernet_ip_folder eth1_ip (
  .reg_addr(wire_avalonMM_addr),
  .reg_data_in(wire_avalonMM_data),
  .reg_wr(wire_avalonMM_wren),

  .m_rx_d(rx_d),
  .m_rx_en(rx_en),
  .m_rx_err(rx_err),
  .m_rx_dval(),

  .ff_rx_clk(),
  .ff_rx_data(wire_avalonST_data),
  .ff_rx_dval(),
  .ff_rx_rdy(wire_pulse), // speciale
  .rx_err(),
  .ff_rx_mod(),
  .ff_rx_sop(),
  .ff_rx_eop()
);

assign leds_red[15:0] = wire_avalonST_data[15:0];

endmodule

