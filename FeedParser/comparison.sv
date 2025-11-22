// Bohdan Purtell
// University of Florida
// Feed Parser Comparative Count

module feed_parser # (
  parameter int DATA_WIDTH = 512,
  parameter int KEEP_WIDTH = DATA_WIDTH / 8,
  parameter int USER_SIZE_WIDTH = 16,
  parameter int USER_SRC_WIDTH = 16,
  parameter int USER_DST_WIDTH = 16
) (
  // clk and rst
  input logic clk, rst,
  input logic tx_clk,
  input logic rx_clk,

  // CMAC AXI4-Stream Signals
  input logic [DATA_WIDTH - 1 : 0]        s_axis_tdata,
  input logic [KEEP_WIDTH - 1 : 0]        s_axis_tkeep,
  input logic [USER_SIZE_WIDTH - 1 : 0]   s_axis_tuser_size,
  input logic [USER_DST_WIDTH  - 1 : 0]   s_axis_tuser_dst,
  input logic [USER_SRC_WIDTH  - 1 : 0]   s_axis_tuser_src,

  input logic s_axis_tlast,
  input logic s_axis_tvalid,
  output logic s_axis_tready,

  // feed parser internals
  
  output logic [31:0] order_id
);

localparam int PAYLOAD_OFFSET = 0;
localparam int HEADER_OFFSET = 0;

localparam int NUM_SUBSCRIPTIONS = 1;
localparam int IP_WIDTH = 48;
localparam logic [IP_WIDTH - 1 : 0] SUBSCRIBED_IPS [NUM_SUBSCRIPTIONS] = '{
  48'h0100_5E00_0001
};

typedef enum logic [5:0] {
  READ_ETH_DST_MAC,
  READ_ETH_SRC_MAC,
  READ_ETH_TYPE,

  READ_IP_HEADER,
  READ_UDP_HEADER,

  READ_MESSAGE_TYPE,
  READ_MESSAGE_LEN,
  READ_MESSAGE_ID,
  READ_MESSAGE_PRICE,
  READ_MESSAGE_QTY,
  READ_MESSAGE_SIDE,
  READ_MESSAGE_NEW_PRICE,
  READ_MESSAGE_NEW_QTY
} parser_state_t;

parser_state_t parser_state;

// 64 bytes (512 bits) width of the data bus, this serves as an offset to
// where we are inside it

// typedef struct packed {
//   logic [47:0] dst_mac; // 6 bytes 
//   logic [47:0] src_mac; // 6 bytes
//   logic [15:0] ether_type; // 2 bytes
// } eth_header_t;
//
// typedef struct packed {
//   logic [47:0] src_ip;
//   logic [47:0] dst_ip;
// } ip_header_t;
//
// typedef struct packed {
//   logic [7:0] payload_byte_length;
// } udp_header_t;
//
// typedef struct packed {
//   logic price;
// } generic_message_t;
//
// typedef struct packed {
//   logic price;
// } add_message_t;

// eth_header_t eth_header;
// ip_header_t ip_header;
// udp_header_t udp_header;

// always_comb
// begin
//   eth_header.dst_mac = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET : DATA_WIDTH - HEADER_OFFSET - 48];
//   eth_header.src_mac = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET - 48 - 1 : DATA_WIDTH - HEADER_OFFSET - 96];
//   eth_header.ether_type = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET - 96 - 1 : DATA_WIDTH - HEADER_OFFSET - 96 - 16];
// end

typedef struct packed {
  logic event_type;
  logic [31:0] id;
  logic [31:0] price;
  logic [31:0] qty;
} event_t;

function automatic logic is_accpeted_mc (logic [IP_WIDTH - 1 : 0] addr);
  is_accpeted_mc = 1'b0;
  foreach(SUBSCRIBED_IPS[i]) begin
    if (addr == SUBSCRIBED_IPS[i]) begin
      is_accpeted_mc = 1'b1;
    end
  end
endfunction

function automatic void parse_byte(
  input byte in_byte,
  inout parser_state_t state,
  inout logic [7:0]       msg_type_accumulator,
  inout logic [7:0]       msg_len_accumulator,

  inout logic [31:0]      orderid_accumulator,
  inout logic [31:0]      price_accumulator,
  inout logic [31:0]      qty_accumulator,

  inout event_t           event_buf [10],
  inout logic [2:0]       event_count,

  // inout logic [63:0]      test_vector,
  // inout logic [7:0]       test_idx,
  // inout logic [7:0]       test_idx2,

  inout logic [47:0]      eth_dest_mac_accumulator,
  inout logic [47:0]      eth_src_mac_accumulator,
  inout logic [15:0]      eth_type_accumulator,

  inout logic [7:0] bytes_left
);

  test_vector[test_idx] = 1;

  case (state)
    READ_ETH_DST_MAC : begin
      // $display("reading eth dst mac");

      eth_dest_mac_accumulator = {eth_dest_mac_accumulator[39:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_ETH_SRC_MAC;
        bytes_left = 6;
      end else begin
        state = READ_ETH_DST_MAC;
      end
    end

    READ_ETH_SRC_MAC : begin
      // $display("reading eth src mac");

      eth_src_mac_accumulator = {eth_src_mac_accumulator[39:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_ETH_TYPE;
        bytes_left = 2;
      end else begin
        state = READ_ETH_SRC_MAC;
      end


    end

    READ_ETH_TYPE : begin
      // $display("reading eth type");

      eth_type_accumulator = {eth_type_accumulator[7:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_IP_HEADER;
        bytes_left = 4;
      end else begin
        state = READ_ETH_TYPE;
      end

    end

    READ_IP_HEADER : begin
      state = READ_UDP_HEADER;
    end

    READ_UDP_HEADER : begin
      state = READ_MESSAGE_TYPE;
    end

    READ_MESSAGE_TYPE : begin
      // $display("wait type state ----------byte: %0d--------------------", in_byte);
      if (in_byte != 0) begin
        msg_type_accumulator = in_byte;
        state = READ_MESSAGE_LEN;
      end else begin
        state = READ_MESSAGE_TYPE;
      end
    end

    READ_MESSAGE_LEN : begin
      msg_len_accumulator = in_byte;
      // if (msg_type_accumulator == '1) begin
      // $display("in wait len case, in_byte: %0d", in_byte);
      // $display("msg_type_accumulator: %0d", msg_type_accumulator);
      if (msg_type_accumulator == 1) begin
        state = READ_MESSAGE_ID;
        bytes_left = 4;
      end else begin
        state = READ_MESSAGE_TYPE;
      end
    end

    READ_MESSAGE_ID : begin
      // $display("in read ID case -------------------%0d--------------------", bytes_left);
      orderid_accumulator = {orderid_accumulator[23:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        if (msg_type_accumulator == 1) begin
          state = READ_MESSAGE_PRICE;
          bytes_left = 4;
        end else begin
          state = READ_MESSAGE_TYPE;
        end
      end
    end

    READ_MESSAGE_PRICE : begin
      // $display("in read PRICE case -------------------%0d--------------------", bytes_left);
      price_accumulator = {price_accumulator[23:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        if (msg_type_accumulator == 1) begin
          state = READ_MESSAGE_QTY;
          bytes_left = 4;
        end
      end else begin
        state = READ_MESSAGE_PRICE;
      end
    end

    READ_MESSAGE_QTY : begin
      qty_accumulator = {qty_accumulator[23:0], in_byte};
      bytes_left--;
      // test_idx2 = 'd7;

      if (bytes_left == 0) begin
        // test_idx2 = 'd7;
        if (msg_type_accumulator == 1) begin
          // if (event_count < 10) begin
            event_buf[event_count].event_type = 'd1;
            event_buf[event_count].id = orderid_accumulator;
            event_buf[event_count].price = price_accumulator; 
            event_buf[event_count].qty = qty_accumulator;
            event_count++;
          // end
        end

        state = READ_MESSAGE_TYPE;
      end else begin
        state = READ_MESSAGE_QTY;
      end
    end

    default : begin
      event_count = event_count;
    end
  endcase

endfunction

// 2 process
// always_ff @(posedge clk)
// begin
//   if (rst) begin
//     current_state <= INIT;
//     data_offset <= 0;
//   end else begin
//     current_state <= next_state;
//     data_offset <= data_offset_n;
//   end
// end

byte bytes [0:63];
// assign bytes = s_axis_tdata[511:0];

logic [63:0] test_vector;
logic [7:0] test_idx;
logic [7:0] test_idx2;
logic [7:0] test_idx3;

always_comb 
begin
  for (int i = 0; i < 64; i++) begin
    bytes[i] = s_axis_tdata[i * 8 +: 8];
  end
end

// eth header accumulators
logic [47:0] eth_dest_mac; // 6 bytes
logic [47:0] eth_src_mac; // 6 bytes
logic [15:0] eth_type; // 2 bytes -> looking for 0x0800 (IPv4)

// ip header accumulators
logic [31:0] ip_header; // 4 bytes of dst ip

// udp header accumulators 
logic [15:0] payload_length; // 2 bytes (65k range)

// payload accumulators
logic [7:0] msg_type;
logic [7:0] msg_len;

logic [31:0] orider_id;
logic [31:0] price;
logic [31:0] qty;

event_t event_buffer_next [10];
logic [2:0] event_count_next;

event_t event_buffer [10];
logic [2:0] event_count;

logic [7:0] bytes_left;

always_ff @(posedge clk)
begin
  if (rst) begin
    // event_buffer <= '0;
    event_count <= '0;
    test_idx3 <= 0;
  end else begin
    event_buffer <= event_buffer_next;
    event_count <= event_count_next;
    test_idx3 <= test_idx2;
  end
end

logic [31:0] debug_id [64];
logic [31:0] debug_price;
logic [31:0] debug_qty;

always_comb
begin
  event_count_next = 0;
  debug_id[0] = order_id;
  debug_price[0] = price;
  debug_qty[0] = qty;
  parser_state = READ_ETH_DST_MAC;
  // bytes_left = 6;

  for(int i = 0; i < 64; i++) begin
    // if (s_axis_tkeep[i]) begin
    //   // next_state = parse_byte(next_state, s_axis_tdata[i]);
    //
    // end
    // $display("reading byte: %0d", bytes[i]);
    parse_byte(
      bytes[i],
      parser_state,
      msg_type,
      msg_len,
      order_id,
      price,
      qty,

      event_buffer_next,
      event_count_next,

      // test_vector,
      // i,
      // test_idx2,

      eth_dest_mac,
      eth_src_mac,
      eth_type,

      bytes_left
    );

    debug_id[i+1] = order_id;
    // $display("byte %0d", i);
    // $display("after parse: state: %10d, id: %10d, price: %10d, qty: %10d", parser_state, order_id, price, qty);
  end
end

endmodule
