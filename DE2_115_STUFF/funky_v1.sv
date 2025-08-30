// Bohdan Purtell
// University of Florida
// Description Testing Module for DE2-115 Board

module funky_v1 (
  input logic a,
  input logic b,
  output logic c
);

always_comb
begin
  c = a && b;
end

endmodule

