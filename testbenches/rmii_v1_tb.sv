// Bohdan Purtell
// University of Florida
// Testbench pour PHY 
// Description: C'est pour testing ethernet RMII interface

`timescale 1 ns / 1 ps

module ethernet_v1_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [7:0] t_dataout;

    // probe
    logic [1:0] t_datain;
    logic [63:0] t_packet;
    logic t_en;
    logic t_tvalid;
    logic t_CRS_DV;

    // dut
    rmii_v1 dut (
      .clk(t_clk),
      .rst(t_rst),

      .RXD(t_datain),
      .CRS_DV(t_CRS_DV),

      .tx_tdata(t_dataout),
      .tx_tvalid(t_tvalid)
    );

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    integer i;

    initial
        begin
            // populate test vectors
            t_rst = 0;
            clk_en = 1;
            i = 0;
            #10

            t_rst = 1;
            #10

            t_rst = 0;
            t_packet = 64'hDEAD_BEEF;
            #10

            t_CRS_DV = 1;
            for (i = 0; i < 33; i += 2) begin
              t_datain = { t_packet[i], t_packet[i + 1] };
              #10

              $display("bruh");
            end

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

