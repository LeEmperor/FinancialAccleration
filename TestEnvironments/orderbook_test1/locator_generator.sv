// Bohdan Purtell
// University of Florida

module locator_generator # (
  parameter int width = 32,
  parameter int index_width = 10,
  parameter int level_width = 5
) (
  input logic clk, rst,

  input logic generate_locator,

  input logic [31:0] order_id,

  input logic [level_width - 1 : 0] level, // 32 price levels
  input logic [2 : 0] slot, // 8 slots
  input logic [31:0] verison, // 32 bit time stamp (per item)

  output logic [63:0] hashtable_value, // possible de le reducer?

  input logic [index_width - 1 : 0] alloq_idx,
  output logic [index_width - 1 : 0] free_idx
);

typedef enum {
  idle_s,
  compute_s,
  done_s
} state_e;

always_ff @(posedge clk, posedge rst)
begin
  if (rst) begin

  end else if (en) begin

  end
end

always_comb
begin

end

endmodule

