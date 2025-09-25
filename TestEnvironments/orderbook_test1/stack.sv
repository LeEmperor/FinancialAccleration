module stack # (
  parameter int depth = 100,
  parameter int width = 16
) (
  input logic clk, rst, en,

  input logic push,
  input logic pop,

  input logic [31:0] indata,
  output logic [31:0] outdata,

  output logic empty,
  output logic full
);

logic [31:0] mem [10];
logic [3:0] stack_pointer;

always_ff @(posedge clk)
begin
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

endmodule

