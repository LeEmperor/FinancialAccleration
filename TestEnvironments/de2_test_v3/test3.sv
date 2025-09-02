// Bohdan Purtell
// University of Florida
// Description: Test of Pluggable Debounce Circuit

module test3 (
  input logic clk_hifreq, rst,
  output logic [15:0] LEDS_RED
);

debounce_circuit_v1 debounce1 (
  .clk_hifreq(),
  .rst(),
  .out1()
);


endmodule

