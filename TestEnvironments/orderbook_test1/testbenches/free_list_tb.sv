// Bohdan Purtell
// University of Florida
// Testbench Template

`timescale 1 ns / 1 ps

module free_list_tb();

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

  // monitor
  wire [width1 - 1 : 0] t_out1;
  wire [width2 - 1 : 0] t_out2;
  wire [width3 - 1 : 0] t_out3;
  wire [15:0] t_alloc_idx;

  logic [15:0] indexes [10];
  int index_index;

  // stim
  logic t_alloc_req;
  logic t_free_req;

  logic [15:0] t_rendre_idx;

  function example_func (int x, int b);
    return x + b;
  endfunction

  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  free_list # (
    .levels(5),
    .slots(8)
  ) dut (
    .clk(t_clk1),
    .rst(t_rst),
    .en(t_en),

    .alloc_req(t_alloc_req),
    .alloc_slot_idx(t_alloc_idx),

    .free_req(t_free_req),
    .free_slot_idx(t_rendre_idx)
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
    t_en = 1;

    t_alloc_req = 0;
    t_free_req = 0;

    index_index = 0;
    #10

    t_rst = 0;
    #10

    #150

    t_alloc_req = 1;
    // t_
    #10
    #10 // c'est pourquoi?
    indexes[index_index] = t_alloc_idx;
    index_index++;

    t_alloc_req = 0;
    #10

    t_alloc_req = 1;
    #10
    indexes[index_index] = t_alloc_idx;
    index_index++;

    t_alloc_req = 0;
    #10

    t_alloc_req = 1;
    #10
    indexes[index_index] = t_alloc_idx;
    index_index++;

    t_alloc_req = 0;
    #10

    t_free_req = 1;
    t_rendre_idx = 'd14;
    #10

    t_free_req = 0;
    #10

    t_alloc_req = 0;
    #10

    t_alloc_req = 1;
    #10

    indexes[index_index] = t_alloc_idx;
    index_index++;

    t_alloc_req = 0;
    #10

    // display whole
    for (int i = 0; i < 10; i++) begin
      $display("allocated index (what was popped): %d", indexes[i]);
    end

    // mettre les truc voici
    #10
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

