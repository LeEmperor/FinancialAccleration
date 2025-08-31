// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève
// STATUS: functionelle

`timescale 1 ns / 1 ps

module ram_v1_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [31:0] t_dataout;

    // probe
    logic [31:0] t_datain;
    logic [9:0] t_addr;
    logic t_wren;

    // dut
    ram_v1 #(
      .ADDR_WIDTH(10),
      .DATA_WIDTH(32)
    ) dut (
      .clk(t_clk),
      .rst(t_rst),
      .addr(t_addr),
      .data_in(t_datain),
      .data_out(t_dataout),
      .wr_en(t_wren)
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

            t_datain = 32'hDEADBEEF;
            t_addr = 10'h10;
            #10

            t_wren = 1;
            #10

            t_wren = 0;
            #10

            t_datain = 32'hFFFFEEEE;
            #10

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

