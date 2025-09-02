// Bohdan Purtell
// University of Florida
// Description: Test Envoyer pour le Ram (verifier que le RAM on peut de lire
// et on peut l'utiliser cette données)
// STATUS: pas functionelle

module test1 #(
  parameter int WIDTH = 32
) (
  // peripherals for bruh
  input logic button, // display / count
  output logic [15:0] LEDS_RED,
  output logic [7:0] LEDS_GREEN,

  // control
  input logic clk, rst, // tie rst à button1

  // Avalon-ST
  input logic ready,
  output logic [WIDTH - 1 : 0] data,
  output logic valid,
  output logic sop,
  output logic eop,
  output logic empty
);

// REG/WIRE Declarations
// logic[WIDTH / 8 - 1 : 0] cycle_counter;
logic [9:0] reg_ram_addr;
logic [9:0] reg_ram_addr_next;
logic ram_wren;
logic [31:0] wire_ram_data_in;
logic [31:0] wire_ram_data_out;

// Structural Coding
// dualport_ram_v1 ram1 (
//   .address_a(reg_ram_addr),
//   .address_b(),
//   .clock(clk),
//   .data_a(wire_ram_data_in),
//   .data_b(),
//   .wren_a(ram_wren),
//   .wren_b(),
//   .q_a(wire_ram_data_out),
//   .q_b()
// );

ram_v1 (
  .address(reg_ram_addr),
  .clock(clk),
  .data(wire_ram_data_in),
  .wren(ram_wren),
  .q(wire_ram_data_out)
);

typedef enum {
  IDLE,
  WAITING,
  BUTTON_DOWN
} state_t;

state_t current_state, next_state;

// Behavioural Coding
// assign ram_wren = 1;
// assign ready = 1;
//
// cycle counter
always_ff @(posedge clk)
begin
  if (rst) begin
    reg_ram_addr <= 0;
    current_state <= IDLE;
  end else begin
    reg_ram_addr <= reg_ram_addr_next;
    current_state <= next_state;
  end
end

assign LEDS_GREEN[7:0] = reg_ram_addr[7:0];

// next state
always_comb
begin
  // defaults
  next_state = current_state;
  reg_ram_addr_next = reg_ram_addr;
  LEDS_RED = 0;

  unique case (current_state)
    IDLE : begin
      next_state = WAITING;
    end

    WAITING : begin
      if (button) begin
        LEDS_RED[15:0] = wire_ram_data_out[15:0];
        next_state = BUTTON_DOWN;
      end
    end

    BUTTON_DOWN : begin
      if (button) begin
        LEDS_RED[15:0] = wire_ram_data_out[15:0];
        next_state = BUTTON_DOWN;
      end else begin
        reg_ram_addr_next = reg_ram_addr + 4;
        next_state = WAITING;
      end
    end
  endcase

end

// capture
// always_ff @(posedge clk)
// begin
//   if (rst) begin
//     data <= 0;
//     valid <= 0;
//   end else if (ready) begin
//     // go
//     data <= wire_ram_data_out[31:0];
//     valid <= 1;
//   end
//
// end

endmodule
