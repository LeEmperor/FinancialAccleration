// Bohdan Purtell
// University of Florida
// Clk Div w/ half-Second Pulse on Trigger

module clk_div2 (
  input logic clk50, rst,
  output logic clk1,
  output logic pulse
);

localparam int DIV_COUNT = 12_500_000;
localparam int SPECIAL_VAL = 12_400_000;
// localparam int DIV_COUNT = 25;
// localparam int SPECIAL_VAL = 15;
logic [$clog2(DIV_COUNT):0] counter;

always_ff @(posedge clk50)
begin
  if (rst) begin
    counter <= 0;
    clk1 <= 0;
    pulse <= 0;
  end else begin
    pulse <= 0;
    if (counter == DIV_COUNT) begin
      counter <= 0;
      clk1 <= ~clk1;
    end else if (counter == SPECIAL_VAL) begin
      pulse <= 1;
      counter <= counter + 1;
    end else begin
      counter <= counter + 1;
    end
  end
end

endmodule

