module bruh_top # (
    parameter int DATA_WIDTH = 32
) (
  input logic [15:0] SW,
  output logic [15:0] LED
);

wire a = SW[0];
wire b = SW[1];
reg c = LED[0];

always_comb
begin
  c = a && b;
end

endmodule

