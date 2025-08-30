// Copyright: None
// Bohdan Purtell
// University of Florda
// Description: Test of AXI-Stream coherent XOR gate (for bringup on MVP[-1])

module axis_xor_v1 # (
  parameter int WIDTH = 512
) (
  input logic aclk,
  input logic areset,

  input logic [WIDTH-1 : 0] slave_tdata,
  input logic slave_tvalid,
  output logic slave_tready,
  input logic slave_tlast,

  output logic [WIDTH/2 - 1 : 0] master_tdata,
  output logic master_tvalid,
  input logic master_tready,
  output logic master_tlast,

  output logic in_debug0,
  output logic in_debug1,
  output logic in_debug2,

  output logic out_debug0,
  output logic out_debug1,
  output logic out_debug2
);


// passthrough ready/valid flags
assign slave_tready = master_tready;

always_ff @(posedge aclk)
begin
  if (areset) begin
    out_debug0 <= 0;
    out_debug1 <= 0;
    out_debug2 <= 0;

    master_tlast  <= 0;
    master_tvalid <= 0;
    master_tdata  <= 0;
  end else begin
    master_tlast <= 0;
    if (master_tready && slave_tvalid) begin
      // handshake == faire des trucs
      for(int i = 0; i < (WIDTH/2); i++) begin
        master_tdata[i] <= slave_tdata[i] ^ slave_tdata[i + 1];
      end
    end
  end
end

endmodule

