// Bohdan Purtell
// University of Florida
// Testbench Template

`timescale 1 ns / 1 ps

module fifo_tb();

  // params
  localparam int width1 = 32;
  localparam int width2 = 10;
  localparam int width3 = 8;

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
  logic t_wren;
  logic t_rden;

  // monitor
  wire [width1 - 1 : 0] t_out1;
  wire [width2 - 1 : 0] t_out2;
  wire [width3 - 1 : 0] t_out3;

  wire t_empty;
  wire t_full;

  // stim
  logic [width1 - 1 : 0] t_in1;
  logic [width2 - 1 : 0] t_in2;
  logic [width3 - 1 : 0] t_in3;

  function example_func (int x, int b);
    return x + b;
  endfunction

  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  task task_write (string test_name, int val);
    $display("test: %s - writing val: %d", test_name, val);
    t_in1 = val;
    t_wren = 1;
    #10

    t_wren = 0;
    #10

    $display("write complete");
  endtask

  task task_read (string test_name);
    $display("test: %s - reading", test_name);
    t_rden = 1;
    #10

    $display("read value: %d", t_out1);

    t_rden = 0;
    #10

    $display("read complete");
  endtask

  // test dut # (
  //   .width(32)
  // ) (
  //
  // );

  fifo dut (
    .clk(t_clk1),
    .rst(t_rst),
    .en(t_en),

    .wren(t_wren),
    .rden(t_rden),

    .indata(t_in1),
    .outdata(t_out1),

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
    t_wren = 0;
    t_rden = 0;
    t_in1 = 0;
    #10

    t_rst = 0;
    #10

    // mettre les truc voici

    for (int i = 0; i < 7; i++) begin
      task_write("loop write", i);
    end

    task_read("test read 1");
    task_read("test read 2");

    #50
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

