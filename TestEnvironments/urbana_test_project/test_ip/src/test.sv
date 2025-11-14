module bruh_top # (
    parameter int DATA_WIDTH = 32
) (
  input logic a,
  input logic b,
  output logic c
);

always_comb
begin
  c = a && b; 
end

endmodule

