// Bohdan Purtell
// University of Florida
// Clock Div 3s

module clock_div3 (
  input logic clk50,
  input logic rst,
  output logic clk3
);

localparam int DIV_COUNT = 16_666_666;
logic [$clog2(DIV_COUNT):0] counter;

always_ff @(posedge clk50)
begin
  if (rst) begin
    counter <= 0;
    clk3 <= 0;
  end else begin
    if (counter == DIV_COUNT) begin
      counter <= 0;
      clk3 <= ~clk3;
    end else begin
      counter <= counter + 1;
    end
  end
end

endmodule

