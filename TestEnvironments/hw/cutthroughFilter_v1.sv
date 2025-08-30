module main #(
  parameter int WIDTH = 64
) (
  input logic clk, rst,

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
  output logic pulse_header
);

typedef enum {
  IDLE,
  IN_PKT,
  DROPPING
} state_t;

state_t current_state;
state_t next_state;

localparam AAPL = 32'h41_41_50_4C;
localparam GOOG = 32'h47_4F_4F_47;

// state regs
always_ff @(posedge clk or posedge rst)
begin
  if (rst) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

// next_state logic block
always_comb
begin
  // defaults
  next_state = current_state;
  master_tlast      = 0;
  master_tdata      = 0;
  master_tvalid     = 0;
  master_byteEnable = 0;
  slave_tready      = 0;
  
  unique case (current_state)
    IDLE : begin
      // handshake
      if (slave_tvalid && master_tready) begin
        // symbol filter
        if (slave_tdata[55:24] == GOOG) begin
          master_tvalid     = 1;
          slave_tready      = 1;
          master_tdata      = slave_tdata;
          master_byteEnable = slave_byteEnable;

          if (slave_tlast)
            next_state = IDLE;
          else
            next_state = IN_PKT;

        end else begin
          next_state = DROPPING;
          slave_tready = 1;
        end
      end
    end

    IN_PKT : begin
      // if (slave_tvalid) begin
      // end
      master_tdata = slave_tdata;
      
      if (slave_tlast)
        next_state = IDLE;
      else
        next_state = IN_PKT;
    end

    DROPPING : begin
      if (slave_tlast) begin
        next_state = IDLE;
      end else begin
        next_state = DROPPING;
        slave_tready = 1;
      end
    end

  endcase
end


endmodule

