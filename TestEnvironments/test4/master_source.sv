// Bohdan Purtell
// University of Florida

module master_source (
  // clk and rst
  input logic clk_hifreq, rst,

  // avalon ports
  input logic avalon_ready,
  output logic [31:0] avalon_data,
  output logic avalon_valid,

  // eth connectivity
  output logic [3:0] tx_d,
  output logic tx_en,
  output logic tx_err

);

logic [31:0] wire_memdata_out;
logic wire_pulse;
logic wire_ready;

logic [31:0] wire_avalonMM_data;
logic [7:0]  wire_avalonMM_addr;
logic        wire_avalonMM_wren;
logic        wire_avalonMM_busy;

memory_source mem (
  .rd_en(wire_pulse),
  .rst(rst),
  .data_out(wire_memdata_out),
);

// chaque half-second, mettre un value nouveau dans le data_bus
clk_div2 half_second (
  .clk50(clk_hifreq),
  .rst(rst),
  .clk1(),
  .pulse(wire_pulse)
);

eth0_config ise0 (
  .clk_hifreq(clk_hifreq),
  .rst(rst),
  .reg_addr(wire_avalonMM_addr),
  .busy(wire_avalonMM_busy),
  .data_out(wire_avalonMM_data),
  .wren(wire_avalonMM_wren)
);

eth_ip_folder eth0_ip (
  .reg_addr(wire_avalonMM_addr),
  .reg_data_in(wire_avalonMM_data),
  .reg_wr(wire_avalonMM_wren),

  .m_tx_d(tx_d),
  .m_tx_en(tx_en),
  .m_tx_err(tx_err),

  .ff_tx_clk(), // ?
  .ff_tx_data(wire_memdata_out),
  .ff_tx_eop(),
  .ff_tx_err(),
  .ff_tx_mod(),
  .ff_tx_rdy(), // de eth à ça
  .ff_tx_sop(),
  .ff_tx_wren()
);

always_ff @(posedge wire_pulse)
begin
  if (rst) begin
    wire_memdata_out <= 0;
  end else begin
    if (wire_ready) begin
      //handshake

    end
  end
end

endmodule

