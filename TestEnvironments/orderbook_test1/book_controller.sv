// Bohdan Purtell
// University of Florida
// Description: Book Microcontroller

module book_controller #(
  parameter int width = 32
) (
  input logic clk, rst, en,

  input logic [1:0] command,

  output logic valid
);

typedef enum {
  idle,
  compute,
  done
} state_t;
state_t current_state, next_state;

always_ff @(posedge clk) 
begin
  if (rst) begin
    current_state <= idle;
  end else if (en) begin 
    current_state <= next_state;
  end
end

typedef enum logic [1:0] {
  add = 0,
  modify = 1,
  cancel = 2
} instruction_e;

always_comb
begin
  // defaults
  valid = 0;
  next_state = current_state;

  case (command) 
    (add) : begin
      // $display("bruh");
      valid = 1;

      next_state = compute;
    end

    (modify) : begin
      next_state = ;
    end

    (cancel) : begin
      next_state = ;
    end
  endcase


end

endmodule

