// Bohdan Purtell
// University of Florida
// Basic Understanding of Avalon Stream Bus
// STATUS: complete

module avalon_st_source #(
  parameter int WIDTH = 64,
  parameter int EMPTY_WIDTH = $clog2(WIDTH/8)
) (
  input logic clk,
  input logic rst,

  output logic [WIDTH - 1 : 0] data,
  output logic valid,

  input logic ready,

  output logic sop,
  output logic eop,

  output logic [EMPTY_WIDTH - 1 : 0] empty
);

typedef enum {
  IDLE,
  BEAT0,
  BEAT1,
  BEAT2,
  DONE
} state_t;

state_t current_state, next_state;

// logic [WIDTH - 1 : 0] beat0 = {64{1'b1}};
logic [WIDTH - 1 : 0] beat0 = {16{4'hF}};
logic [WIDTH - 1 : 0] beat1 = {16{4'hE}};
logic [WIDTH - 1 : 0] beat2 = {16{4'HD}};

// reg proc
always_ff @(posedge clk)
begin
  if (rst) current_state <= IDLE;
  else current_state <= next_state;
end

// next_state logic
always_comb
begin
  // defaults
  data = 0;
  valid = 0;
  sop = 0;
  eop = 0;
  empty = 0;
  next_state = current_state;

  // next state case
  unique case(current_state)
    IDLE : begin
      next_state = BEAT0;
    end

    BEAT0 : begin
      if (ready) begin
        next_state = BEAT1;
      end

      data = beat0;
      valid = 1;
      sop = 1;
    end

    BEAT1 : begin
      if (ready) begin
        next_state = BEAT2;
      end

      valid = 1;
      data = beat1;
    end

    BEAT2 : begin
      if (ready) begin
        next_state = DONE;
      end

      data = beat2;
      valid = 1;
      eop = 1;
      empty = 3;
    end

    DONE : begin
      // valid = 0;
    end

 endcase
end

endmodule

