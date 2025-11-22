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
    logic [47:0] dst_mac;
    logic [47:0] src_mac;
    logic [15:0] eth_type;
  } eth_hdr_t;

  typedef struct {
    logic [31:0] dst_ip;
  } ip_hdr_t;

  typedef struct {
    logic [15:0] payload_len;
  } udp_hdr_t;

  typedef struct {
    eth_hdr_t eth_hdr;
    ip_hdr_t ip_hdr;
    udp_hdr_t udp_hdr;

    byte payload[];
  } frame_t;

  function example_func (int x, int b);
    return x + b;
  endfunction

  function automatic void push (
    logic [511:0] data_bus,
    logic bruh
  );

  endfunction

  typedef byte unsigned byte_q[$];

  class Bytebuilder;
    byte unsigned bytes[$];

    function void push1byte(bit [7:0] v);
      bytes.push_back(v);
    endfunction

    function void push2bytes(bit [15:0] v);
      bytes.push_back(v[15:8]);
      bytes.push_back(v[7:0]);
    endfunction

    function void push4bytes(bit [31:0] v);
      bytes.push_back(v[31:24]);
      bytes.push_back(v[23:16]);
      bytes.push_back(v[15:8]);
      bytes.push_back(v[7:0]);
    endfunction

    // for mac addresses
    function void push6bytes(bit [47:0] v);
      bytes.push_back(v[47:40]);
      bytes.push_back(v[39:32]);
      bytes.push_back(v[31:24]);
      bytes.push_back(v[23:16]);
      bytes.push_back(v[15:8]);
      bytes.push_back(v[7:0]);
    endfunction

    function void push8bytes(bit [63:0] v);
      bytes.push_back(v[63:56]);
      bytes.push_back(v[55:48]);
      bytes.push_back(v[47:40]);
      bytes.push_back(v[39:32]);
      bytes.push_back(v[31:24]);
      bytes.push_back(v[23:16]);
      bytes.push_back(v[15:8]);
      bytes.push_back(v[7:0]);
    endfunction

    function void pushMAC(
      bit [7:0] mac1,
      bit [7:0] mac2,
      bit [7:0] mac3,
      bit [7:0] mac4,
      bit [7:0] mac5,
      bit [7:0] mac6
    );
      bytes.push_back(mac1);
      bytes.push_back(mac2);
      bytes.push_back(mac3);
      bytes.push_back(mac4);
      bytes.push_back(mac5);
      bytes.push_back(mac6);
    endfunction

    function void pushIP(
      bit [7:0] ip1,
      bit [7:0] ip2,
      bit [7:0] ip3,
      bit [7:0] ip4
    );
      bytes.push_back(ip1);
      bytes.push_back(ip2);
      bytes.push_back(ip3);
      bytes.push_back(ip4);
    endfunction

    function void padd(int n);
      repeat(n) bytes.push_back(8'h00);
    endfunction

    function automatic byte_q get_stream();
      return bytes;
    endfunction

  endclass

  function automatic void pack_to_512 (
    input byte unsigned stream[],
    output logic [511:0] word
  );

    for(int i = 0; i < 64; i++) begin
      word[i*8 +: 8] = stream[i];
    end

  endfunction

  function automatic void pack_to_64 (
    input byte unsigned stream[],
    output logic [63:0] word
  );

    for(int i = 0; i < 8; i++) begin
      word[i*8 +: 8] = stream[i];
    end

  endfunction

  // function fill_eth_header (int a);
  // endfunction

  // automatic function build_header (order_header_t hdr);
  // endfunction

  // automatic function populate_udp ();
  // endfunction

  // function automatic byte frame_bytes[] (frame_t f);
  //   byte bytes[$];
  //
  //   bytes.push_back(f.eth_hdr.dst_mac[47:0]);
  //
  //   return bytes;
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

  Bytebuilder b;
  byte unsigned stream_512[];
  byte unsigned stream_64[];
  logic [511:0] test_vect512;
  logic [63:0] test_vect64;

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

    // t_s_axis_tdata[511 : 504] = 'd1;
    // t_s_axis_tdata[503 : 496] = 'd2;
    // t_s_axis_tdata[495 : 488] = 'd20;
    // t_s_axis_tdata[487 : 480] = 'd30;
    // t_s_axis_tdata[479 : 472] = 'd10;
    // t_s_axis_tdata[471 : 464] = 'd50;
    // t_s_axis_tdata[463 : 0] = 0;


    // t_s_axis_tdata.push_back(8'd1);

    // t_s_axis

    // 2 bytes of type ADD, length 2
    // t_s_axis_tdata[7 : 0] = 'd1;
    // t_s_axis_tdata[15 : 8] = 'd12;
    //
    // // 4 bytes of ID = 20.25.23.17
    // t_s_axis_tdata[23 : 16] = 'd20;
    // t_s_axis_tdata[31 : 24] = 'd25;
    // t_s_axis_tdata[39 : 32] = 'd23;
    // t_s_axis_tdata[47 : 40] = 'd17;
    //
    // // 4 bytes of Price = 15
    // t_s_axis_tdata[55 : 48] = 'd0;
    // t_s_axis_tdata[63 : 56] = 'd0;
    // t_s_axis_tdata[71 : 64] = 'd0;
    // t_s_axis_tdata[79 : 72] = 'd15;
    //
    // // 4 bytes of Quantity = USD 20.00
    // t_s_axis_tdata[87 : 80] = 'd0;
    // t_s_axis_tdata[95 : 88] = 'd0;
    // t_s_axis_tdata[103 : 96] = 'd0;
    // t_s_axis_tdata[111 : 104] = 'd20;
   
    b = new();

    // b.push1byte(8'd123); // 'h7B
    // b.push1byte(8'd178); // 'hB2
    // b.push1byte(8'd120); // 'h78
    // b.push1byte(8'd196); // 'hC4

    // dest mac - 6
    b.pushMAC(6, 7, 6, 7, 6, 7);

    // src mac - 6
    b.pushMAC(1, 1, 1, 1, 1, 1);

    // eth type - 2
    b.push2bytes(16'h0800);
    
    // ip header - 4
    b.pushIP(8, 8, 8, 8);

    b.push2bytes(16'd250);

    // message type - 1
    b.push1byte(1);
    
    // message len - 1
    b.push1byte(24);

    // message id - 8
    b.push8bytes(64'd250);

    // message price - 8 
    b.push8bytes(64'd390);

    // message qty - 8
    b.push8bytes(64'd10);






    // stream_64 = b.get_stream();
    stream_512 = b.get_stream();

    // $display("bruh: %0d", stream_512);

    // for(int i = 0; i < 64; i++) begin
    //   $display("byte: %0d", stream_512[i]);
    // end

    // pack_to_64(stream_64, test_vect64);
    pack_to_512(stream_512, test_vect512);
    // $display("64 bit: %0d", test_vect64);
    // $display("64 bit: %0b", test_vect64);
    // $display("512 bit: %0b", test_vect512);

    t_s_axis_tdata = test_vect512;

    #10
    clk1_en = 0;
    disable CLK_GEN;
  end

endmodule

