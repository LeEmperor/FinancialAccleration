// Bohdan Purtell
// University of Florida
// Feed Parser CMAC Interactive Layer

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

typedef enum logic [2:0] {
  WAIT_TYPE,
  WAIT_LEN,
  READ_ID,
  READ_PRICE,
  READ_QTY,
  READ_SIDE,
  READ_NEW_PRICE,
  READ_NEW_QTY
} parser_state_t;

parser_state_t parser_state;

typedef enum {
  INIT,
  PARSING_HEADER,
  PARSING_PAYLOAD,
  DROPPING_PAYLOAD
} state_t;

state_t current_state, next_state;

// 64 bytes (512 bits) width of the data bus, this serves as an offset to
// where we are inside it
logic [4:0] data_offset;
logic [4:0] data_offset_n;

logic subscription_hit;

typedef struct packed {
  logic [47:0] dst_mac; // 6 bytes 
  logic [47:0] src_mac; // 6 bytes
  logic [15:0] ether_type; // 2 bytes
} eth_header_t;

typedef struct packed {
  logic [47:0] src_ip;
  logic [47:0] dst_ip;
} ip_header_t;

typedef struct packed {
  logic [7:0] payload_byte_length;
} udp_header_t;

typedef struct packed {
  logic price;
} generic_message_t;

typedef struct packed {
  logic price;
} add_message_t;

eth_header_t eth_header;
ip_header_t ip_header;
udp_header_t udp_header;

always_comb
begin
  eth_header.dst_mac = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET : DATA_WIDTH - HEADER_OFFSET - 48];
  eth_header.src_mac = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET - 48 - 1 : DATA_WIDTH - HEADER_OFFSET - 96];
  eth_header.ether_type = s_axis_tdata[DATA_WIDTH - HEADER_OFFSET - 96 - 1 : DATA_WIDTH - HEADER_OFFSET - 96 - 16];
end

function automatic logic is_accpeted_mc (logic [IP_WIDTH - 1 : 0] addr);
  is_accpeted_mc = 1'b0;
  foreach(SUBSCRIBED_IPS[i]) begin
    if (addr == SUBSCRIBED_IPS[i]) begin
      is_accpeted_mc = 1'b1;
    end
  end
endfunction

function automatic void parse_byte(
  input byte b,
  inout parser_state_t state,
  inout logic [7:0] msg_type,
  inout logic msg_side,
  inout logic [15:0] ticker_id,



  output logic bruh
);

  case (state)
    WAIT_TYPE : begin
      msg_type = b;
    end

    default : begin
    end
  endcase

endfunction

// 2 process
always_ff @(posedge clk)
begin
  if (rst) begin
    current_state <= INIT;
    data_offset <= 0;
  end else begin
    current_state <= next_state;
    data_offset <= data_offset_n;
  end
end



always_comb
begin
  for(int i = 0; i < 64; i++) begin
    if (s_axis_tkeep[i]) begin
      // next_state = parse_byte(next_state, s_axis_tdata[i]);
    end
  end
end

// next state logic
always_comb
begin
  // defaults
  next_state = current_state;
  s_axis_tready = 0;

  unique case(current_state)
    INIT : begin
      next_state = PARSING_HEADER;
      s_axis_tready = 1;
    end

    PARSING_HEADER : begin
      if (s_axis_tvalid) begin
        // fresh header
        // start at the 15th byte
        // subscription_hit = is_accpeted_mc(s_axis_tdata[
        subscription_hit = is_accpeted_mc(ip_header.dst_ip);
        if (subscription_hit) begin
          next_state = PARSING_PAYLOAD;
          s_axis_tready = 1;
        end
      end
    end

    PARSING_PAYLOAD : begin
      s_axis_tready = 1;
    end

    DROPPING_PAYLOAD : begin
      s_axis_tready = 1;
    end

    default : begin

    end
  endcase
end

endmodule

