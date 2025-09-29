// Bohdan Purtell
// UF

module static_free_lists # (
  parameter int levels = 5,
  parameter int slots = 8,
  parameter int level_width = $clog2(levels),
  parameter int slot_width = $clog2(slots)
) (
  input logic clk, rst, en,

  input logic [4:0] free_slot_idx,
  output logic [4:0] alloc_slot_idx,

  input logic [1:0] level, // accessors adresse
  input logic [1:0] alloq_req_arr, // accessor de alloqreqs
  input logic [1:0] free_req_arr // accessor de freereqs
);

logic [1:0] wire_demux;

always_comb
begin
  case (level)
    'd1 : begin
      wire_demux = ;
    end

    'd2 : begin

    end

    'd3 : begin

    end
  endcase
end

free_list # (
  .slots(slots)
) level1 (
  .clk(clk),
  .rst(rst),
  .en(en),

  .alloc_req(alloq_req_arr[0]),
  .alloc_slot_idx(alloc_slot_idx),

  .free_req(free_req_arr[0]),
  .free_slot_idx(free_slot_idx)
);

free_list # (
  .slots(slots)
) level2 (
  .clk(clk),
  .rst(rst),
  .en(en),

  .alloc_req(alloq_req_arr[1]),
  .alloc_slot_idx(alloc_slot_idx),

  .free_req(free_req_arr[1]),
  .free_slot_idx(free_slot_idx)
);

free_list # (
  .slots(slots)
) level3 (
  .clk(clk),
  .rst(rst),
  .en(en),

  .alloc_req(alloq_req_arr[2]),
  .alloc_slot_idx(alloc_slot_idx),

  .free_req(free_req_arr[2]),
  .free_slot_idx(free_slot_idx)
);

endmodule

