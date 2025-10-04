// Bohdan Purtell
// University of Florida
// Testbench Template

`timescale 1 ns / 1 ps

module mux2_tb();

  // params
  localparam int width1 = 8;
  localparam int width2 = 8;
  localparam int width3 = 8;

  // clocks
  logic t_clk1;
  logic clk1_en;
  logic t_clk2;
  logic clk2_en;
  logic t_clk3;
  logic clk3_en;

  logic t_sel;

  // control
  logic t_rst;
  logic t_en;

  // monitor
  wire [width1 - 1 : 0] t_out1;
  wire [width2 - 1 : 0] t_out2;
  wire [width3 - 1 : 0] t_out3;

  // stim
  logic [width1 - 1 : 0] t_in1;
  logic [width1 - 1 : 0] t_in2;
  logic [width3 - 1 : 0] t_in3;

  function example_func (int x, int b);
    return x + b;
  endfunction

  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  // test dut # (
  //   .width(32)
  // ) (
  //
  // );

  mux2 # (
    .width(8)
  ) dut (
    .a(t_in1),
    .b(t_in2),
    .sel(t_sel),
    .out1(t_out1)
  );

  // clock proc
  initial begin : CLK_GEN
    t_clk1 = 0;
    forever #5 t_clk1 = ~t_clk1 & clk1_en;
  end

  // main
  initial begin : MAIN
    clk1_en = 1;
    t_rst = 1;
    #10

    t_rst = 0;
    #10

    t_sel = 0;
    #10

    t_in1 = 8'd5;
    t_in2 = 8'd6;
    #10

    t_sel = 1;
    #10

    // t_sel = X;
    // #10

    // mettre les truc voici

    #50
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

