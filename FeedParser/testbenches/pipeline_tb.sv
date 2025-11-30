// Bohdan Purtell
// University of Florida
// Testbench Template

`timescale 1 ns / 1 ps

module struct_pipeline_test_tb();
  // clocks
  logic t_clk1;
  logic clk1_en;

  // control
  logic t_rst;
  logic t_en;

  // monitor

  // stim
  logic [63:0] t_data;

  struct_pipeline_test dut (
    .clk(t_clk1),
    .rst(t_rst),
    .data_bus(t_data)
  );

  function example_func (int x, int b);
    return x + b;
  endfunction

  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  // clock proc
  initial begin : CLK_GEN
    t_clk1 = 0;
    forever #5 t_clk1 = ~t_clk1 & clk1_en;
  end

  // main
  initial begin : MAIN
    clk1_en = 1;
    t_rst = 1;
    t_data = 0;
    #10

    t_rst = 0;
    #10

    t_data = {64{1'b1}};

    // mettre les truc voici

    #100
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

