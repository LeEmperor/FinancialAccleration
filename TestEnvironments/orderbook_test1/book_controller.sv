// Bohdan Purtell
// University of Florida
// Description: Book Microcontroller

module book_controller #(
  parameter int width = 32
) (
  input logic clk, rst, en,

  input logic [3:0] msg_type,
  input logic side,
  input logic entry_present,

  output logic generate_locator,
  output logic alloc_req,
  output logic free_req,
  output logic hash_table_WE
);

typedef enum logic [3:0] {
  add = 0,
  modify = 1,
  cancel = 2
} instruction_e;
instruction_e msg_enum;

typedef enum {
  idle_s,
  add_s,
  modify_s,
  cancel_s
} state_e;

state_e current_state, next_state;

always_ff @(posedge clk) 
begin
  if (rst) begin
    current_state <= idle_s;
  end else if (en) begin 
    current_state <= next_state;
  end
end

always_comb
begin
  // defaults
  next_state = current_state;

  generate_locator = 0;
  alloc_req = 0;
  free_req = 0;
  hash_table_WE = 0;

  msg_enum = instruction_e'(msg_type);
  case (current_state)
    idle_s : begin
      case (msg_enum)
        add : begin
          generate_locator = 1;
          alloc_req = 1;

          next_state = add_s;
        end

        modify : begin
          next_state = modify_s;
        end

        cancel : begin
          free_req = 1;
          next_state = cancel_s;
        end
      endcase
    end
  endcase

end

endmodule

