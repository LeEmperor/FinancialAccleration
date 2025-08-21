// Bohdan Purtell
// University of Florida
// Demonstration Basique des Principles de Cutthrough avec AXI-stream protocol

typedef struct packed {
  logic [7:0] msg_type;
  logic [23:0] symbol_id;
  logic [31:0] price_q16_16;
} header_t;

module cutthrough_v1 #(
  parameter int WIDTH = 64
) (
  input logic clk, rst,
  // AXIS_interface.receiver_v1 in, // le module's bus d'entrée est un receiver
  // AXIS_interface.sender_v1 out,  // le module's bus de sortie est un sender

  // AXIS slave (input)
  input logic [WIDTH - 1 : 0] slave_tdata,
  input logic [WIDTH/8 - 1 : 0] slave_byteEnable,
  input logic slave_tvalid,
  input logic slave_tlast,
  output logic slave_tready,

  // AXIS master (output)
  output logic [WIDTH - 1 : 0] master_tdata,
  output logic [WIDTH/8 - 1 : 0] master_byteEnable,
  output logic master_tvalid,
  output logic master_tlast,
  input logic master_tready,

  input  logic  pulse_ready,
  output logic  pulse_valid,
  output header_t pulse_header 
);

  // combinational bits
  logic [7:0] msg_type;
  logic [31:0] symbol;

  // flags
  logic dropping;

  assign master_tdata = slave_tdata;
  assign master_tlast = slave_tlast;
  assign master_byteEnable = slave_byteEnable;
  assign master_tvalid = slave_tvalid && !dropping;

  // backpressure honor
  assign slave_tready = (dropping) ? 1 : master_tready;

  assign msg_type = slave_tdata[63:56];
  assign symbol = slave_tdata[55:24];

  typedef enum {
    idle = 0,
    in_pkt = 1,

    // dropping,
    forwarding
  } state_e;

  state_e current_state;
  

  // packet state machine
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      current_state <= idle;
      dropping <= 0;
    end else begin
      // handshake
      if (slave_tvalid && slave_tready) begin
        current_state <= idle;

        case (current_state)
          idle : begin
            if (!slave_tlast) begin
              // quand pas packet première (premier packet, ou packet au milieu)
              if (
                (msg_type == 8'h51) || 
                (msg_type == 8'h54) &&
                (symbol == 32'h41_41_50_4C) || 
                (symbol == 32'h47_4F_4F_47)
              ) begin
                dropping <= 0;
                current_state <= in_pkt;
              end else begin
                dropping <= 1;
              end

            end
          end

          in_pkt : begin
            if (slave_tlast) begin
              dropping <= 0;
            end
          end
        endcase
      end
    end

  end

endmodule

