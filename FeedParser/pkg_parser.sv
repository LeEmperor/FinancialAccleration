// Bohdan Purtell
// University of Florida
// Parser Machine

package parser_pkg;

  import types_pkg::*;

function automatic void parse_byte(
  input byte in_byte,
  inout pipeline_state_t saved_state,

  inout event_t event_buf [10],
  inout event_t new_event
);
  case (saved_state.current_state)
    READ_ETH_DST_MAC : begin
      saved_state.eth_dest_mac = {saved_state.eth_dest_mac[39:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 6;
        saved_state = READ_ETH_SRC_MAC;
      end

    end

    READ_ETH_SRC_MAC : begin
      saved_state.eth_src_mac = {saved_state.eth_src_mac[39:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 2;
        saved_state.next_state = READ_ETH_TYPE;
      end
    end

    READ_ETH_TYPE : begin
      saved_state.eth_type = {saved_state.eth_type[7:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 4;
        saved_state.next_state = READ_IP_HEADER;
      end
    end

    READ_IP_HEADER : begin
      saved_state.ip_header = {saved_state.ip_header[23:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 2;
        saved_state.next_state = READ_UDP_HEADER;
      end
    end

    READ_UDP_HEADER : begin
      saved_state.payload_length = {saved_state.payload_length[7:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.next_state = READ_MESSAGE_TYPE;
      end
    end

    READ_MESSAGE_TYPE : begin
      saved_state.msg_type = in_byte;
      saved_state.next_state = READ_MESSAGE_LEN;
    end

    READ_MESSAGE_LEN : begin
      saved_state.msg_len = in_byte;
      saved_state.next_state = READ_MESSAGE_ID;
      saved_state.bytes_left = 4;
    end

    READ_MESSAGE_ID : begin
      saved_state.order_id = {saved_state.order_id[23:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 4;
        saved_state.next_state = READ_MESSAGE_PRICE;
      end
    end

    READ_MESSAGE_PRICE : begin
      saved_state.price = {saved_state.price[23:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.bytes_left = 4; 
        saved_state.next_state = READ_MESSAGE_QTY;
      end
    end

    READ_MESSAGE_QTY : begin
      saved_state.qty = {saved_state.qty[23:0], in_byte};
      saved_state.bytes_left--;

      if (saved_state.bytes_left == 0) begin
        saved_state.next_state = READ_MESSAGE_TYPE;
        // $display("message parsed -----------", );
        // $display("type: %0b", saved_state.msg_type);
        // $display("len: %0d", saved_state.msg_len);
        // $display("id: %0d", saved_state.order_id);
        // $display("price: %0d", saved_state.price);
        // $display("qty: %0d", saved_state.qty);
        new_event.msg_type = saved_state.msg_type;
        new_event.id = saved_state.order_id;
        new_event.price = saved_state.price;
        new_event.qty = saved_state.qty;
        event_buf[saved_state.event_count] = new_event;
      end
    end

    // READ_MESSAGE_QTY : begin
    //   qty_accumulator = {qty_accumulator[23:0], in_byte};
    //   bytes_left--;
    //   // test_idx2 = 'd7;
    //
    //   if (bytes_left == 0) begin
    //     // test_idx2 = 'd7;
    //     $display("message qty: %0d", qty_accumulator);
    //     if (msg_type_accumulator == 1) begin
    //       // if (event_count < 10) begin
    //         event_buf[event_count].event_type = 'd1;
    //         event_buf[event_count].id = orderid_accumulator;
    //         event_buf[event_count].price = price_accumulator; 
    //         event_buf[event_count].qty = qty_accumulator;
    //         event_count++;
    //       // end
    //     end
    //
    //     state = READ_MESSAGE_TYPE;
    //   end else begin
    //     state = READ_MESSAGE_QTY;
    //   end
    // end
    //
    default : begin
    end
  endcase

endfunction

endpackage : parser_pkg;

