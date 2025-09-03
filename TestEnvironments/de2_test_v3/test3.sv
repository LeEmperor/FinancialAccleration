// Bohdan Purtell
// University of Florida
// Description: Test de écrire data à display unit

module test3 (
  input logic clk_hifreq, rst,
  input logic ready,
  output logic valid,
  output logic [31:0] data_out
);

logic [9:0] wire_ram_addr;
logic [31:0] wire_ram_data_out;

ram_v1 ram1 (
  .address(wire_ram_addr),
  .clock(clk_hifreq),
  .data(0),
  .wren(0),
  .q(wire_ram_data_out)
);

assign wire_ram_addr = 10'h3;

always_ff @(posedge clk_hifreq)
begin
  if (rst) begin
    valid <= 0;
    data_out <= 0;
  end else begin
    data_out <= 0;
    if (ready) begin
      data_out <= wire_ram_data_out;
      valid <= 1;
    end
  end
end

endmodule

