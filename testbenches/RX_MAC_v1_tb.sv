// Bohdan Purtell
// University of Florida
// Description: Testbench pour RX MAC
// STATUS: not finished testing for tlast assertions from the (up from the RMII shim)

`timescale 1 ns / 1 ps

module RX_MAC_v1_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [7:0] t_dataout;

    // probe
    logic [7:0] t_datain;
    logic t_en;
    // logic [84:0] full_data = { {5{16'h55}}, 16'hDF, 64'hDEAD_BEEF_DEAD_BEAD };
    // logic [0:112] full_data = { {5{8'h55}}, 8'hDF, 64'hDEAD_BEEF_DEAD_BEAD };

    // logic [0:69][7:0] full_data_packed = { {5{8'h55}}, 8'hDF, 64'hDEAD_BEEF_DEAD_BEAD };
    logic [69:0][7:0] full_data_packed = {<<8{ {5{8'h55}}, 8'hDF, 64'hDEAD_BEEF_DEAD_BEAD }};

    // dut
    RX_MAC_v1 dut (
      .clk(t_clk),
      .rst(t_rst),
      .rx_datain(t_datain),
      .tx_dataout(t_dataout),
      .rx_tlast(),
      .tx_tlast()
    );

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    int i;

    initial
        begin
            // populate test vectors
            t_rst = 0;
            clk_en = 1;
            #10

            t_rst = 1;
            #10

            t_rst = 0;
            #20

            for(i = 0; i < 90; i++) begin
              t_datain = full_data_packed[i];
              #10
              $display("bruh");
            end

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

