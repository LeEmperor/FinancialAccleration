// Bohdan Purtell
// University of Florida
// Description: Generic Circuit pour Driver les Pins avec Button Debouncing

module debounce_circuit_v1 (
  input logic clk_hifreq, rst,
  input logic button,
  output logic pulse
);

typedef enum {
  IDLE,
  WAITING,
  BUTTON_DOWN
} state_t;
state_t current_state;
state_t next_state;

// reg proc
always_ff @(posedge clk_hifreq)
begin
  if (rst) begin
    current_state <= IDLE;
  end else begin
    current_state <= next_state;
  end
end

// next state
always_comb
begin
  next_state = current_state;
  pulse = 0;

  unique case (current_state)
    IDLE : begin
      next_state = WAITING;
    end

    WAITING : begin
      if (button) begin
        pulse = 1;
        next_state = BUTTON_DOWN;
      end
    end

    BUTTON_DOWN : begin
      if (button) begin
        next_state = BUTTON_DOWN;
      end else begin
        next_state = WAITING;
      end
    end
  endcase

end

endmodule

