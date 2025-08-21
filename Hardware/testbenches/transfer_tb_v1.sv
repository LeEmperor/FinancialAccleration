// Bohdan Purtell
// University of Florida
// Testbench AXI-Stream
// Description: C'est pour le AXI-stream

`timescale 1 ns / 1 ps

module axis_stream_tb_v1();

  // master params
  localparam int MASTER_WIDTH = 64;

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [MASTER_WIDTH - 1 : 0] t_dataout;

    // probe
    logic t_datain;
    logic t_en;

    // interfaces
    AXIS_interface #(
      .WIDTH(MASTER_WIDTH)
    ) stream(); // wire bundle?

    // dut
    producer_v1 #(
      .WIDTH(MASTER_WIDTH)
    ) producer_dut (
      .clk(t_clk),
      .rst(t_rst),
      .axis_bus(stream)
    );

    consumer_v1 #(
      .WIDTH(MASTER_WIDTH)
    ) consumer_dut (
      .clk(t_clk),
      .rst(t_rst),
      .out1_reg(t_dataout),
      .axis_bus(stream)
    );

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    initial
        begin
            clk_en = 1;
            // populate test vectors
            t_rst = 0;
            #10

            t_rst = 1;
            #10

            t_rst = 0;
            #10

            #50

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

