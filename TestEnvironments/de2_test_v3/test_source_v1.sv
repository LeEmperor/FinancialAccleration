// Bohdan Purtell
// University of Florida
// Description: Test Source pour ethernet transmissions
// STATUS: pas functionelle

module test_source_v1 #(
  parameter int WIDTH = 32
) (
  // control
  input logic clk, rst,

  // Avalon-ST
  input logic ready,
  output logic [WIDTH - 1 : 0] data,
  output logic valid,
  output logic sop,
  output logic eop,
  output logic empty
);

// REG/WIRE Declarations
// logic[WIDTH / 8 - 1 : 0] cycle_counter;
logic[9:0] cycle_counter;
logic ram_wren;
logic wire_ram_data_in;
logic wire_ram_data_out;

// Structural Coding




// Behavioural Coding
assign ram_wren = 1;
assign ready = 1;

// cycle counter
always_ff @(posedge clk)
begin
  if (rst)
    cycle_counter <= 0;
  else
    cycle_counter <= cycle_counter + 4;
end

// send
always_ff @(posedge clk)
begin
  if (rst) begin

  end else if (valid && ready) begin

  end

end

endmodule

