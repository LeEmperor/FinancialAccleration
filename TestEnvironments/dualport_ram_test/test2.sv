// Bohdan Purtell
// University of Florida
// Description: Testing les Niveaux des Activations des Buttons
// STATUS: Functionnel pour un Counter et RAM lire

module test2 (

  input logic clk, rst,

  input logic [3:0] BUTTONS,
  input logic [15:0] SWITCHES,

  output logic [17:0] LEDS_RED,
  output logic [7:0] LEDS_GREEN

);

typedef enum {
  IDLE,
  WAITING,
  BUTTON_DOWN
} state_t;
state_t current_state;
state_t next_state;

logic [7:0] counter;
logic [7:0] counter_next;

logic ram_wren;
logic [31:0] wire_ram_data_in;
logic [31:0] wire_ram_data_out;

ram_v1 (
  .address({2'b00, counter}),
  .clock(clk),
  .data(),
  .wren(ram_wren),
  .q(wire_ram_data_out)
);

always_ff @(posedge clk)
begin
  if (rst) begin
    counter <= 0;
    current_state <= IDLE;
  end else begin
    counter <= counter_next;
    current_state <= next_state;
  end
end

always_comb 
begin
  counter_next <= counter;
  next_state <= current_state;

  case (current_state) 
    IDLE : begin
      next_state <= WAITING;
    end

    WAITING : begin
      if (BUTTONS[0]) begin
        counter_next <= counter + 1;
        next_state <= BUTTON_DOWN;
      end
    end

    BUTTON_DOWN : begin
      if (BUTTONS[0])
        next_state <= BUTTON_DOWN;
      else
        next_state <= WAITING;
    end
  endcase

end

always_comb
begin
  LEDS_GREEN[7:0] = counter[7:0];
  LEDS_RED[15:0] = wire_ram_data_out[15:0];
end

// always_comb
// begin
//   LEDS_RED[6] = BUTTONS[0] && BUTTONS[1];
//   LEDS_GREEN[5] = BUTTONS[2] && BUTTONS[3];
// end

endmodule

