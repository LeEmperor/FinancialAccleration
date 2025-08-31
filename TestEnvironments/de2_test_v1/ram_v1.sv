// Bohdan Purtell
// University of Florida
// Simple Inferred Ram Block pour utiliser avec le test sink
// STATUS: verified que c'est functionnel

module ram_v1 # (
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 32
) (
  input logic clk, rst,
  input logic [ADDR_WIDTH - 1 : 0] addr,
  input logic wr_en,
  input logic [DATA_WIDTH - 1 : 0] data_in,
  output logic [DATA_WIDTH - 1 : 0] data_out
);

  logic [DATA_WIDTH - 1 : 0] mem[0:(1<<ADDR_WIDTH) - 1];

  always_ff @(posedge clk) begin
    if (wr_en) begin
      mem[addr] <= data_in;
    end

    data_out <= mem[addr];

  end

endmodule


