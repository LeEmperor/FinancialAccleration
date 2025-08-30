// Bohdan Purtell
// University of Florida
// Testbench pour AXI-S coherence pour XOR gate
// Description: C'est un testbench informel

`timescale 1 ns / 1 ps

module axis_xor_v1_tb();

    // control
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire t_dataout;

    // probe
    logic t_datain;
    logic t_en;

    // dut
    axis_xor_v1 #(
      .WIDTH(128)
    ) dut (
      .aclk(),
      .areset(),

      // slave (receiver module)
      .slave_tdata(),
      .slave_tvalid(),
      .slave_tready(),
      .slave_tlast(),

      // master (sender module)
      .master_data(),
      .master_tvalid(),
      .master_tready(),
      .master_tlast()
    );

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    initial
        begin
            // populate test vectors
            t_rst = 0;
            clk_en = 1;
            #10

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

