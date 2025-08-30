// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève
// STATUS: complete

`timescale 1 ns / 1 ps

module avalon_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire [3:0][63:0] t_dataout;

    // probe
    logic t_datain;
    logic t_en;

    logic [63:0] wire_source_sink_data;
    logic wire_source_sink_valid;
    logic wire_sink_source_ready;
    logic wire_source_sink_sop;
    logic wire_source_sink_eop;
    logic wire_source_sink_empty;

    // source
    avalon_st_source #(
      .WIDTH(64)
    ) source1 (
      .clk(t_clk),
      .rst(t_rst),

      .data(wire_source_sink_data),
      .valid(wire_source_sink_valid),
      .ready(wire_sink_source_ready),
      .sop(wire_source_sink_sop),
      .eop(wire_source_sink_eop),
      .empty(wire_source_sink_empty)
    );

    // sink
    avalon_st_sink #(
      .WIDTH(64)
    ) sink1 (
      .clk(t_clk),
      .rst(t_rst),

      .data(wire_source_sink_data),
      .valid(wire_source_sink_valid),
      .ready(wire_sink_source_ready),
      .sop(wire_source_sink_sop),
      .eop(wire_source_sink_eop),
      .empty(wire_source_sink_empty),
      .reg_out(t_dataout)
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

            #100

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

