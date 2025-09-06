// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module memory_source2_tb();
    // control
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [31:0] t_dataout;

    // probe
    logic [31:0] t_datain;
    logic t_wren;
    logic t_rden;

    // dut
    memory_source dut (
      .rd_en(t_rden),
      .rst(t_rst),
      .data_out(t_dataout)
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

            t_rst = 1;
            #10

            t_rst = 0;
            #10

            t_rden = 1;
            #30

            t_rden = 0;
            #20

            t_rden = 1;
            #40

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

