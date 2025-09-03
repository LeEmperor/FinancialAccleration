// Bohdan Purtell
// University of Florida

module display (
  // clk and rst
  input logic clk_hifreq, rst,

  // avalon-st bus
  input logic [15:0] data_in,
  input logic valid,
  output logic ready,

  // peripherals
  input logic [16:0] switches,
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

logic wire_pulse;
logic wire_clk1;

clk_div1 pulse_generator (
  .rst(rst),
  .clk50(clk_hifreq),
  .clk1(wire_clk1),
  .pulse(wire_pulse)
);

assign ready = wire_pulse;

always_ff @(posedge clk_hifreq)
begin
  if (rst) begin
    leds_red <= 0;
    leds_green <= 0;
  end else begin
    if (valid) begin
      leds_red[15:0] <= data_in[15:0];
    end
  end
end

endmodule

