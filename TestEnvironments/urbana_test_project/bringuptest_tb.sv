// Bohdan Purtell
// University of Florida
// Testbench Template

`timescale 1 ns / 1 ps

module axi_tb();

  // params
  localparam int WIDTH1 = 32;
  localparam int WIDTH2 = 10;
  localparam int WIDTH3 = 8;

  // clocks
  logic t_clk1;
  logic clk1_en;

  // control
  logic t_rst;

  logic t_awready;

  // monitor
  logic t_write;
  logic t_read;

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

  test_module dut (
    .aclk(t_clk1),
    .aresetn(t_rst),

    // debug probes
    .debug_launch_write(t_write),
    .debug_launch_read(t_read),

    // master write address
    .M_AXI_AWADDR(),
    .M_AXI_AWVALID(),
    .M_AXI_AWREADY(t_awready),

    // master write data
    .M_AXI_WDATA(),
    .M_AXI_WSTRB(),
    .M_AXI_WVALID(),
    .M_AXI_WREADY(),

    // master write response
    .M_AXI_BRESP(),
    .M_AXI_BVALID(),
    .M_AXI_BREADY(),

    // master read address
    .M_AXI_ARADDR(),
    .M_AXI_ARVALID(),
    .M_AXI_ARREADY(),

    // master read data
    .M_AXI_RDATA(),
    .M_AXI_RRESP(),
    .M_AXI_RVALID(),
    .M_AXI_RREADY()
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
    t_read = 0;
    t_write = 0;
    t_awready = 0;
    #10

    t_rst = 0;
    #10

    // mettre les truc voici
    t_write = 1;
    #30

    t_awready = 1;
    #20



    #50
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

