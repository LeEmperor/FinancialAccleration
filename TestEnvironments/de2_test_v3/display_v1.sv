// Bohdan Purtell
// University of Florida
// Description: Pour le Display (recevoir de Avalon-ST)

module display_v1 (
  // clk and rst
  input logic clk_hifreq, rst,

  // avalon-st bus
  input logic [31:0] data_in,
  input logic valid,
  output logic ready,

  // peripherals
  input logic [17:0] switches,
  input logic [3:0] buttons,
  output logic [7:0] leds_green,
  output logic [17:0] leds_red,

  output logic [6:0] hex0,
  output logic [6:0] hex1,
  output logic [6:0] hex2,
  output logic [6:0] hex3,
  output logic [6:0] hex4,
  output logic [6:0] hex5,
  output logic [6:0] hex6,
  output logic [6:0] hex7
);

logic wire_clk_1s;
logic [15:0] internal_buffer;
logic wire_pulse;

// 1s clkdiv
clk_div_1s clk_1hz (
  .rst(rst),
  .clk50(clk_hifreq),
  .clk1(wire_clk_1s),
  .pulse(ready)
);

// assign ready = wire_pulse;

always_ff @(posedge wire_clk_1s)
begin
  if (valid) begin
    leds_red[15:0] <= internal_buffer;
  end
end

always_ff @(posedge clk_hifreq)
begin
  if (valid) begin
    internal_buffer <= data_in[15:0];
  end
end

endmodule

