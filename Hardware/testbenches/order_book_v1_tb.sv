// Bohdan Purtell
// University of Florida
// Testbench Template v2
// Description: C'est pour testing très brève

`timescale 1 ns / 1 ps

module order_book_v1_tb();

    // control 
    logic t_clk;
    logic t_rst;
    logic clk_en;

    // monitor
    wire t_dataout;
    wire [9:0][31:0] t_bidprices;
    wire [9:0][31:0] t_bidquantities;

    // probe
    logic [63:0] t_datain;
    logic t_en;
    logic t_slave_tvalid;

    // dut
    order_book_v1 dut (
      .clk(t_clk),
      .rst(t_rst),
      .slave_tdata(t_datain),
      .slave_tvalid(t_slave_tvalid),
      .bidprices_out(t_bidprices),
      .bidquantities_out(t_bidquantities)
    );

    typedef struct packed {
      logic [31:0] price;
      logic [31:0] volume;
    } order_t;

    function automatic order_t makeOrder(input int price, input int volume);
       order_t order = '{price: $unsigned(price), volume: $unsigned(volume)};
    endfunction

    task automatic insertOrder(input int p, input int q);
      t_valid <= 0;
      t_datain <= {logic'(p), logic'(q)};
      #10

      t_valid <= 1;
      #10
    endtask

    initial begin : CLK_GEN
        t_clk = 0;
        forever #5 t_clk = ~t_clk & clk_en;
    end

    initial
        begin
            // populate test vectors
            t_rst = 0;
            clk_en = 1;
            t_slave_tvalid = 0;
            #10

            t_rst = 1;
            #10

            t_rst = 0;
            #10

            t_datain = {32'd12304, 32'd27};
            // $display("slave_tdata [30:0] : %d", t_datain[30:0]);
            order_t o1 = makeOrder();
            #20

            // makeOrder(120, 10);

            t_datain = {32'd12702, 32'd71};
            #20

            t_datain = {32'd12000, 32'd15};
            #20

            #20

            // {32'dxx, 32'dxx}

            clk_en = 0;
            disable CLK_GEN;

        end
endmodule

