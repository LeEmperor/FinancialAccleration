// Bohdan Purtell
// University of Florida
// Feed Parser Stim Bench

`timescale 1 ns / 1 ps

module feed_parser_tb();

  // params
  localparam int width1 = 512;
  localparam int AXI_WIDTH = 512;
  int current_header_offset = 0; 
  int current_payload_offset = 0;

  // clocks
  logic t_clk1;
  logic clk1_en;

  // control
  logic t_rst;
  logic t_en;

  // monitor
  wire t_s_axis_tready;

  // stim
  logic [511 : 0] t_s_axis_tdata;
  logic t_s_axis_tvalid;

  // custom structs

  typedef struct {
    logic bruh;
  } ethernet_header_t;

  typedef struct {
    logic bruh;
  } ip_header_t;

  typedef struct {
    logic bruh;
  } udp_header_t;

  typedef struct {
    ethernet_header_t eth_hdr;
    ip_header_t ip_hdr;
    udp_header_t udp_hdr;
  } order_header_t;

  typedef struct {
    logic bruh;
  } order_message_t;

  function example_func (int x, int b);
    return x + b;
  endfunction

  // function fill_eth_header (int a);
  // endfunction

  // automatic function build_header (order_header_t hdr);
  // endfunction

  // automatic function populate_udp ();
  // endfunction



  task example_task (int x, int b);
    t_rst = 0;
    #10
    $display("task complete");
  endtask

  // test dut # (
  //   .width(32)
  // ) (
  //
  // );

  feed_parser # (
    .DATA_WIDTH(512) // defaults are utilized
  ) dut (
    // clocks/rst
    .clk(t_clk1),
    .rst(t_rst),
    .tx_clk(),
    .rx_clk(),

    // AXI-Stream
    .s_axis_tdata(t_s_axis_tdata),
    .s_axis_tready(t_s_axis_tready),
    .s_axis_tvalid(t_s_axis_tvalid)
  );


  // clock proc
  initial begin : CLK_GEN
    t_clk1 = 0;
    forever #5 t_clk1 = ~t_clk1 & clk1_en;
  end

  // initial begin : TEST_VECTOR_POPULATE
  //
  // end

  // main
  initial begin : MAIN
    clk1_en = 1;
    t_rst = 1;
    t_s_axis_tdata = 0;
    #10

    t_rst = 0;
    #10

    // mettre les truc voici

    // s_axis_tdata[511 : 510] = 0;


    #50
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

