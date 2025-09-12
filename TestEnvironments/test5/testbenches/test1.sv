// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module test1();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire t_dataout;
    wire t_sop;
    wire t_eop;
    wire t_wren;

    // probe
    logic t_datain;
    logic t_en;
    logic t_rdy;

    // dut
    controller dut (
      .clk_hifreq(t_clk),
      .rst(t_rst),
      .sop(t_sop),
      .eop(t_eop),
      .wren(t_wren),
      .reg_wren(),
      .rdy(t_rdy),
      .en(t_en)
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
            t_rdy = 0;
            t_en = 0;
            #10

            t_rdy = 1;
            t_en = 1;
            #30

            t_rdy = 0;
            #30


            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

