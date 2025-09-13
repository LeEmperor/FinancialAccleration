// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module orderbook_v2_tb();
    // control
    logic t_clk;
    logic t_rst;
    logic t_en;
    logic clk_en;

    // monitor
    wire t_dataout;
    wire t_bid1price;

    // probe
    logic [31:0] t_indata;
    logic t_valid;

    // dut
    orderbook_v2 dut (
      .clk_hifreq(t_clk),
      .rst(t_rst),
      .en(t_en),
      .in_data(t_indata),
      .valid(t_valid),

      .bid1_price(),
      .bid2_price(),
      .bid3_price(),
      .bid4_price(),
      .bid5_price(),
      .bid6_price(),
      .bid7_price(),
      .bid8_price(),
      .bid9_price(),
      .bid10_price()
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

            t_indata = 32'h20;
            t_valid = 1;
            #10

            #20

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

