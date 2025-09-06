// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module memory_source_tb ();

    // control
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [31:0] t_dataout;
    wire t_valid;

    // probe
    logic t_datain;
    logic t_en;
    logic t_ready;

    // dut
    memory_source dut (
      .clk_hifreq(t_clk),
      .rst(t_rst),
      .ready(t_ready),
      .data_out(t_dataout),
      .valid(t_valid)
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
            t_ready = 0;
            #10

            t_rst = 1;
            #10

            t_rst = 0;
            #10

            #100

            t_ready = 1;
            #10
            t_ready = 0;
            #50

            t_ready = 1;
            #10
            t_ready = 0;
            #30

            t_ready = 1;
            #10
            t_ready = 0;
            #90

            #100

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

