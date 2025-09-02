// Bohdan Purtell
// University of Florida
// Description: Clock Divider Circuit pour Testing

module clock_div_v1 (
  input logic clk50, rst,
  output logic clk1
);

localparam int DIV_COUNT = 25_000_000;
logic [$clog2(DIV_COUNT):0] counter;

always_ff @(posedge clk50)
begin
  if (rst) begin
    counter <= 0;
    clk1 <= 0;
  end else begin
    if (counter == DIV_COUNT) begin
      counter <= 0;
      clk1 <= ~clk1;
    end else begin
      counter <= counter + 1;
    end
  end
end

endmodule

