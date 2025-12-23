module and_gate (
  input logic sw[1:0],
  output logic led[3:0]
);

assign led[0] = sw[0] && sw[1];

endmodule

