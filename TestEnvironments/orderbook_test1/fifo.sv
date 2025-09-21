// Bohdan Purtell
// University of Florida
// Fifo Pour les Interactions

module fifo # (
  parameter int width = 32,
  parameter int depth = 8
) (
  input logic clk,
  input logic rst,
  input logic en,

  input logic wren,
  input logic rden,

  input logic [width - 1 : 0] indata,
  output logic [width - 1 : 0] outdata,

  output logic empty,
  output logic almost_empty,
  output logic full,
  output logic almost_full
);

logic [$clog2(depth) - 1 : 0] write_ptr;
logic [$clog2(depth) - 1 : 0] read_ptr;

logic [width - 1 : 0] fifo_storage [depth];

// write proc
always_ff @(posedge clk)
begin
  if (rst) begin
    write_ptr <= 0;
  end else begin
    if (wren & !full) begin
      fifo_storage[write_ptr] <= indata;
      write_ptr <= write_ptr + 1;
    end
  end
end

// read proc
always_ff @(posedge clk)
begin
  if (rst) begin
    read_ptr <= 0;
  end else begin
    if (rden & !empty) begin
      outdata <= fifo_storage[read_ptr];
      read_ptr <= read_ptr + 1;
    end
  end
end

assign full = (write_ptr + 1) == read_ptr;
assign empty = write_ptr == read_ptr;

endmodule

