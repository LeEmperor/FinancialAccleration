// Bohdan Purtell
// University of Florida
// Testbench pour Orderbook

`timescale 1 ns / 1 ps

module orderbook_tb();
    // control
    logic t_clk;
    logic t_rst;
    logic t_en;
    logic clk_en;

    // monitor
    wire t_dataout;
    wire [31:0] t_bid1price;
    wire [9:0] t_occupiedmask;

    // probe
    logic [31:0] t_indata;
    logic t_valid;

    // dut
    orderbook dut (
      .clk_hifreq(t_clk),
      .rst(t_rst),
      .en(t_en),
      .new_price(t_indata),
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
      .bid10_price(),

      .occupied_mask(t_occupiedmask)
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

            t_indata = 32'd32;
            t_valid = 1;
            #10
            $display("occupied mask: %b", t_occupiedmask);

            t_valid = 0;
            #10

            t_indata = 32'd21;
            t_valid = 1;
            #10
            //
            t_valid = 0;
            #10

            t_indata = 32'd22;
            t_valid = 1;
            #10

            t_valid = 0;
            #10

            t_indata = 32'd23;
            t_valid = 1;
            #10

            t_valid = 0;
            #10

            t_indata = 32'd10;
            t_valid = 1;
            #10
            t_valid = 0;
            #10

            // t_indata = 32'h24;
            // t_valid = 1;
            // #10

            t_valid = 0;
            #20

            clk_en = 0;
            disable CLK_GEN;

            // for (int i = 0; i < 10; i++) begin
            //   $display("num: %d", {10'b1 << i});
            // end
        end
endmodule

