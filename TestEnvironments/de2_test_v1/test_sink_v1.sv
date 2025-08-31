// Bohdan Purtell
// University of Florida
// Description: Test sink pour ethernet transmissions
// STATUS: pas functionelle

module test_sink_v1 #(
  parameter int WIDTH = 32
) (
  // peripherals for bruh
  input logic button0,
  input logic button1,
  output logic [15:0] LEDS,

  // control
  input logic clk, rst,

  // Avalon-ST
  output logic ready,
  input logic [WIDTH - 1 : 0] data,
  input logic valid,
  input logic sop,
  input logic eop,
  input logic empty
);

// REG/WIRE Declarations
// logic[WIDTH / 8 - 1 : 0] cycle_counter;
logic[9:0] cycle_counter;
logic ram_wren;
logic wire_ram_data_in;
logic wire_ram_data_out;

// Structural Coding
ram_v1 # (
  .ADDR_WIDTH(10),
  .DATA_WIDTH(32)
) ram1 (
  .clk(clk),
  .rst(rst),
  .addr(cycle_counter),
  .wr_en(ram_wren),
  .data_in(wire_ram_data_in),
  .data_out(wire_ram_data_out)
);

// Behavioural Coding
assign ram_wren = 1;
assign ready = 1;

// cycle counter
always_ff @(posedge clk)
begin
  if (rst)
    cycle_counter <= 0;
  else
    cycle_counter <= cycle_counter + 1;
end

// capture
always_ff @(posedge clk)
begin
  if (rst) begin

  end else if (valid && ready) begin
    wire_ram_data_in <= data;
    if (button0)
      LEDS[15:0] <= data[15:0];
    else
      LEDS[15:0] <= 16'b0101_0101_0101_0101;
  end

end

endmodule

