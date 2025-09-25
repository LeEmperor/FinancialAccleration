module free_list # (
  parameter int width = 32,
  parameter int bruh = 32,
  parameter int command_width = 32
) (  
  input logic clk, rst, en,

  input logic [command_width - 1 : 0] command,
  input logic [3:0] pop_which,
  input logic [3:0] push_which,
  output logic out1
);

typedef struct packed {
  logic [1:0] bruh;
  level_t* next;
  level_t* prev;
} level_t;

level_t levels[10];

logic [31:0] example_storage [10]; 

always_ff @(posedge clk)
begin
  case (command)
    'h10 : begin // pop
      // levels[pop_which].
    end

    'h11 : begin // push
      levels[push_which - 1].next = levels[push_which];
    end

    default : begin
      out1 <= 0;
    end
  endcase
end

endmodule

