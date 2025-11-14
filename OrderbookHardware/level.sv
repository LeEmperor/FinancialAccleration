// toplevel of a level

module level_v1 #(
  parameter int DATA_WIDTH = 64
) (
  input logic clk, rst,

  input logic [31:0] qty,
  input logic [31:0] order_id,
  input logic [31:0] vendor_id,
  input logic [31:0] exchange_id,
  input logic [63:0] priority_key,
  input logic [15:0] next_idx,
  input logic [15:0] prev_idx,

  output logic data_lost
);

typedef struct {
  logic [31:0] order_id;
} slot_t;

slot_t slots [10];

logic [3:0] write_ptr;
logic [3:0] read_ptr;

function int alloq_idx(void);
endfunction

always_ff @(posedge clk)
begin
  if (rst) begin
    write_ptr <= 0;
    read_ptr <= 0;
  end else begin

  end
end

always_comb
begin

end

endmodule

