// Bohdan Purtell
// University of Florida
// Testbench pour Stack
// STATUS: Fonctionné

`timescale 1 ns / 1 ps

module stack_tb();

  // params
  localparam int width1 = 32;
  localparam int width2 = 10;
  localparam int width3 = 8;
  localparam int depth = 10;

  // clocks
  logic t_clk1;
  logic clk1_en;
  logic t_clk2;
  logic clk2_en;
  logic t_clk3;
  logic clk3_en;

  // control
  logic t_rst;
  logic t_en;

  // monitor
  // wire [width1 - 1 : 0] t_out1;
  // wire [width2 - 1 : 0] t_out2;
  // wire [width3 - 1 : 0] t_out3;

  wire [15:0] t_out;
  wire t_full;
  wire t_empty;

  // stim
  // logic [width1 - 1 : 0] t_in1;
  // logic [width2 - 1 : 0] t_in2;
  // logic [width3 - 1 : 0] t_in3;

  logic [15:0] t_in;

  logic t_push;
  logic t_pop;

  function example_func (int x, int b);
    return x + b;
  endfunction

  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  task task_push (int i);
    t_in = 16'(i);
    t_push = 1;
    #10

    t_in = 0;
    t_push = 0;
    #10
    $display("pushing: %4d", i);
  endtask

  task task_pop ();
    t_pop = 1;
    #10

    $display("popped: %4d", t_out);

    t_pop = 0;
    #10

    $display("still? popped: %4d", t_out);
  endtask

  stack # (
    .width(16),
    .depth(10)
  ) dut (
    .clk(t_clk1),
    .rst(t_rst),
    .en(t_en),

    .push(t_push),
    .pop(t_pop),

    .indata(t_in),
    .outdata(t_out),

    .empty(t_empty),
    .full(t_full)
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
    t_push = 0;
    t_pop = 0;
    t_in = 0;
    #10

    t_rst = 0;
    #10

    task_push(25);
    task_push(30);

    task_pop();

    task_push(35);
    task_push(50);

    task_pop();
    task_pop();
    task_pop();
    task_pop();

    // mettre les truc voici

    #50
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

