module toplevel_v1 (
  input logic a,
  input logic b,
  output logic c
);

always_comb
begin
  c = a && b;
end

endmodule

