// Bohdan Purtell, UF, Astera Interview Question

module mux2 # (
  parameter int width = 5
) (
  input logic [width - 1 : 0] a, 
  input logic [width - 1 : 0] b,
  input logic sel,
  output logic [width - 1 : 0] out1
);

always_comb
begin
  // case (sel)
  //   'd0 : begin
  //     out1 = a;
  //   end
  //   'd1 : begin
  //     out1 = b;
  //   end
  //
  //   default : begin
  //     out1 = 8'x;
  //   end
  // endcase

  out1 = (sel) ? a : b;
end

endmodule

