module toplevel (
  input logic clk,
  input logic rst,
  input logic en,
  output logic [31:0] tx_d,
  output logic tx_err,
  output logic tx_en
);

// wires
logic wire_regwren;
logic wire_wren;
logic wire_sop;
logic wire_eop;
logic [31:0] wire_data;
logic wire_rdy;
logic wire_err;
logic wire_mod;

logic wire_clk1second;
logic wire_rden;

logic wire_mtxdata;
logic wire_mtxerr;
logic wire_mtxen;

// logic wire_regwren_to_tse;

// // structures
//
// reg_v1 reg_wren # (
//   .width(1)
// ) (
//   .clk(clk),
//   .rst(rst),
//   .wren(wire_regwren)
//   .data(wire_wren),
//   .q(wire_regwren_to_tse)
// );

memory_source mem (
  .rd_en(wire_rden),
  .rst(rst),
  .data_out(wire_data)
);

clk_div1 clk1 (
  .clk50(clk),
  .rst(rst),
  .clk1(wire_clk1second),
  .pulse()
);

eth_ip transmit_ip (
  .clk(clk),
  .reset(rst),

  .reg_addr(),
  .reg_data_out(),
  .reg_wr(),

  .m_tx_d(tx_d),
  .m_tx_en(tx_en),
  .m_tx_err(tx_err),

  .ff_tx_data(wire_data),
  .ff_tx_sop(wire_sop),
  .ff_tx_eop(wire_eop),
  .ff_tx_err(wire_err),
  .ff_tx_mod(wire_mod),
  .ff_tx_rdy(wire_rdy),
  .ff_tx_wren(wire_wren)
);

controller control (
  .clk_1(),
  .clk_half(),
  .clk_hifreq(clk),
  .rst(rst),
  .en(en),

  .rdy(wire_rdy),
  .sop(wire_sop),
  .eop(wire_eop),
  .wren(wire_wren),
  
  .rd_en(wire_rden)
);

endmodule

