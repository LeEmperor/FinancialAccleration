module struct_pipeline_test (
  input logic clk, rst,
  input logic [511:0] data_bus,
  output logic a
);

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

  logic [31:0] orider_id;
  logic [31:0] price;
  logic [31:0] qty;
} pipeline_state_t;

typedef struct packed {
  // msg data
  logic [1:0] msg_type;
  logic [7:0] msg_len;

  logic [7:0] order_id;
  logic [7:0] order_price;
  logic [7:0] order_qty;
} order_t;


typedef struct packed {
  logic [1:0] msg_type;
  logic [31:0] price;
  logic [31:0] qty;
} event_t;

pipeline_state_t stage1;
pipeline_state_t stage2;
pipeline_state_t stage3;
pipeline_state_t stage4;

pipeline_state_t stage1_next;
pipeline_state_t stage2_next;
pipeline_state_t stage3_next;
pipeline_state_t stage4_next;

logic [3:0] counter_offset;
logic [3:0] counter_offset_next;

// pipeline advancedment
always_ff @(posedge clk)
begin
  if (rst) begin
    stage1 <= 0;
    stage2 <= 0;
    stage3 <= 0;
    stage4 <= 0;
    counter_offset <= 0;
  end else begin
    stage1 <= stage1_next;
    stage2 <= stage2_next;
    stage3 <= stage3_next;
    stage4 <= stage4_next;
    counter_offset <= counter_offset_next;
  end
end

function automatic void parse_byte(
  input byte in_byte,
  inout pipeline_state_t pipeline_state,

  inout event_t event_buf
);
  case (state)
    READ_ETH_DST : begin
      pipeline_state.

    end


    READ_ETH_DST_MAC : begin
      // $display("reading eth dst mac");

      eth_dest_mac_accumulator = {eth_dest_mac_accumulator[39:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_ETH_SRC_MAC;
        bytes_left = 6;
        $display("read eth dest addr: %0d", eth_dest_mac_accumulator);
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
        $display("read eth src addr: %0d", eth_src_mac_accumulator);
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
        $display("read eth type: %0d", eth_type_accumulator);
      end else begin
        state = READ_ETH_TYPE;
      end

    end

    READ_IP_HEADER : begin
      // $display("reading ip header");
      ip_header_accumlator = {ip_header_accumlator[23:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_UDP_HEADER;
        bytes_left = 2;
        $display("read ip header: %0d", ip_header_accumlator);
      end else begin
        state = READ_IP_HEADER;
      end
    end

    READ_UDP_HEADER : begin
      // $display("reading udp header");
      udp_header_accumulator = {udp_header_accumulator[7:0], in_byte};
      bytes_left--;

      if (bytes_left == 0) begin
        state = READ_MESSAGE_TYPE;
        bytes_left = 1;
        $display("read payload len: %0d", udp_header_accumulator);
      end else begin
        state = READ_UDP_HEADER;
      end
    end

    READ_MESSAGE_TYPE : begin
      // $display("read message type: ");
      if (in_byte == 1) begin
        msg_type_accumulator = in_byte;
        state = READ_MESSAGE_LEN;
        $display("ADD type message found!", msg_type_accumulator);
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
        bytes_left = 8;
        $display("message len: %0d", msg_len_accumulator);
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
          bytes_left = 8;
          $display("message id: %0d", orderid_accumulator);
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
          bytes_left = 8;
          $display("message price: %0d", price_accumulator);
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
        $display("message qty: %0d", qty_accumulator);
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

byte unsigned bytes [0:63];
always_comb
begin
  for (int i = 0; i < 64; i++) begin
    bytes[i] = in_data[i * 8 +: 8];
  end
end

// next state logic
always_comb
begin
  stage2_next = stage1;
  stage3_next = stage2;
  stage4_next = stage3;
  stage1_next = 0;

  for(int i = counter_offset; i < counter_offset + 4; i++) begin
    $display("counter offset: %0d", counter_offset);

    parse_byte(
      bytes[i],
      stage1_next 
    );

    if (counter_offset >= 16) begin
      counter_offset_next = 0;
    end else begin
      counter_offset_next = counter_offset + 4;
    end
  end
end

endmodule

