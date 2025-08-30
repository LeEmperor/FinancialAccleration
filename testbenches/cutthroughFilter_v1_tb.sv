// Bohdan Purtell
// University of Florida
// Testbench pour Verifier le Cutthrough Module

`timescale 1 ns / 1 ps

module main_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    logic t_slave_tvalid;
    logic t_master_tready;
    logic t_slave_tlast;

    // monitor
    wire [63:0] t_dataout;

    // probe
    logic [63:0] t_datain;
    logic t_en;

    // dut
    main dut (
      .clk(t_clk),
      .rst(t_rst),
      .slave_tdata(t_datain),
      .slave_byteEnable(0),
      .slave_tvalid(t_slave_tvalid),
      .slave_tlast(t_slave_tlast),
      .slave_tready(),

      .master_tdata(t_dataout),
      .master_byteEnable(),
      .master_tvalid(),
      .master_tlast(),
      .master_tready(t_master_tready)
    );

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    initial
        begin
            // populate test vectors
            t_rst = 0;
            t_slave_tvalid = 0;
            t_master_tready = 0;
            t_slave_tlast = 0;
            clk_en = 1;
            #10

            t_slave_tvalid = 1;
            t_datain = { 8'd0, 32'h47_4F_4F_47, 24'd0 };
            #30

            t_master_tready = 1;
            #40

            t_datain = {64'h12345678};
            #20

            t_datain = {64'h876654321};
            t_slave_tlast = 1;
            #20

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

