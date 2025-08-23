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
  output header_t pulse_header
);


typedef enum {
  IDLE,
  IN_PKT,
  DROPPING
} state_t;

state_t state;

localparam AAPL = 32'h41_41_50_4C;
localparam GOOG = 32'h47_4F_4F_47;

// combination assigns


// next_state logic block
always_ff @(posedge clk or posedge rst)
begin
  if (rst) begin
    master_tlast <= 0;
    master_tdata <= 0;
    master_tvalid <= 0;
  end else begin
    state <= state;
    unique case (state)
      IDLE : begin
        if (slave_tvalid && slave_tready) begin
          // asserter que le filter est vrai
          state <= IN_PKT;
        end

      end

      IN_PKT : begin
        if (slave_tlast) begin
          state <= IDLE;
        end
      end

      DROPPING : begin
        if (slave_tlast) begin
          state <= IDLE;
        end
      end
    endcase
  end
end


// output logic
always_comb
begin
  unique case (state)
    IDLE : begin
      master_tdata = 0;
      master_tvalid = 0;
    end

    IN_PKT : begin

    end

    DROPPING : begin

    end

  endcase
end

endmodule

