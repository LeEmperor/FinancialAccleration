// Bohdan Purtell
// University of Florida
// Descripion: Utiliser pour écrire chaque haut-second

module memory_source (
  input logic rd_en,
  input logic rst,
  // input logic ready,
  // output logic valid,
  output logic [31:0] data_out
);

logic [9:0] counter;

ram_v2 ram (
  .address(counter[9:0]),
  .clock(clk_hifreq),
  .data(0),
  .wren(0),
  .q(data_out)
);

always_ff @(posedge rd_en)
begin
  if (rst) begin
    counter <= 0;
  end else begin
    counter <= counter + 1; // timing profile lmao
  end
end

endmodule

