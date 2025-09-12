module reg_v1 #(
  parameter width = 32
) (
  input logic clk,
  input logic rst, 
  input logic wren,
  input logic [width - 1 : 0] data,
  output logic [width - 1 : 0] q
);

always_ff @(posedge clk, posedge rst)
begin
  if (rst) begin
    q <= 0;
  end else if (wren) begin
    q <= data;
  end
end

endmodule

