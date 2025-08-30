// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module funky_v1_tb ();

    // control
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire t_dataout;

    // probe
    logic t_datain;
    logic t_en;

    logic t_a;
    logic t_b;

    // dut
    funky_v1 dut (
      .a(t_a),
      .b(t_b),
      .c(t_dataout)
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

            t_a = 1;
            t_b = 0;
            #10

            t_a = 1;
            t_b = 1;
            #10

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

