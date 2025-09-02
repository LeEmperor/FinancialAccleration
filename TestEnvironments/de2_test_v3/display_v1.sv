// Bohdan Purtell
// University of Florida
// Description: Pour le Display (recevoir de Avalon-ST)

module display_v1 (
  // clk and rst
  input logic clk, rst,

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
  output logic [6:0] hex7,
);

logic clk_1hz;

clk_div_v1 clk1 (
  .rst(rst),
  .clk50(clk),
  .clk1(clk_1hz)
);

logic reg_ready;

// display updates
always_ff @(posedge clk_1hz)
begin
  reg_ready <= ~reg_ready;
end



endmodule

