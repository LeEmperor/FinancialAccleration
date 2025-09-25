// Bohdan Purtell
// University of Florida
// STATUS: Bonne Fonctionné

module stack # (
  parameter int depth = 16,
  parameter int width = 4
) (
  input logic clk, rst, en,

  input logic push,
  input logic pop,

  input  logic [width - 1 : 0] indata,
  output logic [width - 1 : 0] outdata,

  output logic empty,
  output logic full
);

logic [width - 1 : 0] mem [depth];
logic [$clog2(width) : 0] stack_pointer; // size considerations?

assign outdata = mem[stack_pointer];

always_ff @(posedge clk or rst)
begin
  if (rst) begin
    stack_pointer <= 0;
  end else begin
    case ({push, pop})
      2'b10 : begin
        mem[stack_pointer] <= indata;
        stack_pointer <= stack_pointer + 1;
      end

      2'b01 : begin
        stack_pointer <= stack_pointer - 1;
      end

      2'b11 : begin 
        mem[stack_pointer] <= indata;
      end
    endcase
  end

end

endmodule

