// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève
// STATUS : Complete pour le Pulse Configuration

`timescale 1 ns / 1 ps

module clk_div1_tb();

    // control
    logic t_clk50;
    logic t_clk1;
    logic t_rst;
    logic clk_en;

    // monitor
    wire t_dataout;
    wire t_pulse;

    // probe
    logic t_datain;
    logic t_en;

    // dut
    clk_div1 dut (
      .clk50(t_clk50),
      .rst(t_rst),
      .clk1(t_clk1),
      .pulse(t_pulse)
    );

    initial begin : CLK_GEN
        t_clk50 = 0;
        forever #5 t_clk50 = ~t_clk50 & clk_en;
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

            #200

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

