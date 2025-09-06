// Bohdan Purtell
// University of Florida
// Eth0 ISE Config

module eth0_config (

  input logic clk_hifreq,
  input logic rst,

  input logic busy,
  output logic [7:0] reg_addr,
  output logic [31:0] data_out,
  output logic wren
);

typedef enum {
  IDLE,
  WAITING
} state_t;
state_t current_state, next_state;

logic clk_half;

clk_div2 clkhalf (
  .clk50(clk_hifreq),
  .clk1(clk_half),
  .rst(rst),
  .pulse()
);

// reg proc
always_ff @(posedge clk_1)
begin
  if (rst) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

// next_state logic
always_comb
begin
  // default
  next_state = current_state;

  unique case (current_state)
    IDLE : begin
      if (!busy) begin
        next_state = WAITING;
      end
    end

  endcase
end

endmodule

