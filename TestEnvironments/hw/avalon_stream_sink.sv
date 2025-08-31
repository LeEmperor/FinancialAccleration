// Bohdan Purtell
// University of Florida
// Avalon Sink Test
// STATUS: complete

module avalon_st_sink #(
  parameter int WIDTH = 64,
  parameter int EMPTY_WIDTH = $clog2(WIDTH/8)
) (
  input logic clk, rst,

  input logic [WIDTH - 1 : 0] data,
  input logic valid,

  output logic ready,

  input logic sop,
  input logic eop,

  input logic [EMPTY_WIDTH - 1 : 0] empty,

  output logic [3:0][63:0] reg_out
);

logic[2:0] cycle_counter;

always_ff @(posedge clk)
begin
  if (rst)
    cycle_counter <= 0;
  else
    cycle_counter <= cycle_counter + 1;
end

assign ready = (cycle_counter != 3'd4);

// logic[191:0] reg_out_bruh;
// assign reg_out = reg_out_bruh;
// logic[2:0][63:0] reg_out_bruh;

// capture
always_ff @(posedge clk)
begin
  if(rst) begin
    reg_out <= 0;
  end else if (valid && ready) begin
    if (sop) begin

    end

    // $diplay("SINK: DATA=0x%h", data);
    reg_out[cycle_counter] <= data;

    if (eop) begin

    end
  end
end

endmodule

