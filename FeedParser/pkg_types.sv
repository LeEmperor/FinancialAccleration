// Bohdan Purtell
// University of Florida
// Types Header

package types_pkg;
  // les états de parser 
  typedef enum {
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

  // pipline global struct
  typedef struct packed {
    parser_state_t current_state;
    parser_state_t next_state;

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

    logic [31:0] order_id;
    logic [31:0] price;
    logic [31:0] qty;

    logic [7:0] bytes_left;
    logic [7:0] payload_left;

    logic [2:0] event_count;
  } pipeline_state_t;

  // not sure if this is used
  typedef struct packed {
    // msg data
    logic [1:0] msg_type;
    logic [7:0] msg_len;

    logic [7:0] order_id;
    logic [7:0] order_price;
    logic [7:0] order_qty;
  } order_t;

  // events
  typedef struct packed {
    logic [1:0] msg_type;
    logic [31:0] id;
    logic [31:0] price;
    logic [31:0] qty;
  } event_t;

endpackage : types_pkg;

