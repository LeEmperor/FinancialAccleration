// Bohdan Purtell
// University of Florida
// Description: Test Source

module source (
  // clk and rst
  input logic clk_hifreq, rst,

  // avalon-st bus
  output logic [15:0] data_out,
  output logic valid,
  input logic ready
);

logic [31:0] wire_ram_data_out;
logic [9:0] counter;

ram_v2 ram (
  .address(counter),
  .clock(clk_hifreq),
  .data(0),
  .wren(0),
  .q(wire_ram_data_out)
);

always_ff @(posedge clk_hifreq)
begin
  valid <= 0;
  data_out <= 0;

  if (rst) begin
    counter <= 0;
  end else begin
    if (ready) begin
      data_out <= wire_ram_data_out[15:0];
      valid <= 1;
      counter <= counter + 1;
    end
  end
end

endmodule

