// Bohdan Purtell
// University of Florida
// Description: Test sink pour ethernet transmissions

module test_sink_v1 #(
  parameter int WIDTH = 64
) (
  // control
  input logic clk, rst,

  // Avalon-ST
  output logic ready,
  input logic [31:0] data,
  input logic valid,
  input logic sop,
  input logic eop,
  input logic empty
);




endmodule

