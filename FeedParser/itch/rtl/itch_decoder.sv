// =============================================================================
// itch_decoder.sv
// Arty A7-100T ITCH Demo
//
// Byte-serial ITCH 5.0 message decoder.
// Accepts bytes from moldudp64_parser, decodes message types A/D/U/E/X.
// Emits decoded fields as registered outputs with a done strobe.
//
// Supported messages:
//   A - Add Order          (36 bytes)
//   F - Add Order w/ MPID  (40 bytes) - decoded same as A, MPID ignored
//   D - Delete Order       (19 bytes)
//   U - Order Replace      (35 bytes)
//   E - Order Executed     (31 bytes)
//   X - Order Cancel       (23 bytes)
//   All others are skipped using the block length from moldudp64.
// =============================================================================

module itch_decoder (
    input  logic        clk,
    input  logic        rst_n,

    // From MoldUDP64 parser
    input  logic [7:0]  in_data,
    input  logic        in_valid,
    input  logic        in_msg_start,  // first byte of new message (type byte)

    // Decoded Add Order (A/F)
    output logic        add_valid,
    output logic [15:0] add_stock_locate,
    output logic [47:0] add_timestamp,
    output logic [63:0] add_order_ref,
    output logic        add_side,      // 1=Buy, 0=Sell
    output logic [31:0] add_shares,
    output logic [63:0] add_stock,     // 8 char ASCII
    output logic [31:0] add_price,     // fixed point x10000

    // Decoded Delete Order (D)
    output logic        del_valid,
    output logic [63:0] del_order_ref,
    output logic [47:0] del_timestamp,

    // Decoded Order Replace (U)
    output logic        rep_valid,
    output logic [63:0] rep_orig_ref,
    output logic [63:0] rep_new_ref,
    output logic [31:0] rep_shares,
    output logic [31:0] rep_price,
    output logic [47:0] rep_timestamp,

    // Decoded Order Executed (E)
    output logic        exe_valid,
    output logic [63:0] exe_order_ref,
    output logic [31:0] exe_shares,
    output logic [47:0] exe_timestamp,

    // Decoded Order Cancel (X)
    output logic        can_valid,
    output logic [63:0] can_order_ref,
    output logic [31:0] can_shares,
    output logic [47:0] can_timestamp
);

    // -------------------------------------------------------------------------
    // Field offsets within each message (0-indexed from type byte)
    //
    // All messages share common header:
    //   [0]     type         (1B)
    //   [1:2]   stock_locate (2B)
    //   [3:4]   tracking_num (2B)  — ignored
    //   [5:10]  timestamp    (6B)
    //
    // Add Order (A) = 36 bytes:
    //   [11:18] order_ref    (8B)
    //   [19]    side         (1B)  'B'=0x42 Buy, 'S'=0x53 Sell
    //   [20:23] shares       (4B)
    //   [24:31] stock        (8B)
    //   [32:35] price        (4B)
    //
    // Delete Order (D) = 19 bytes:
    //   [11:18] order_ref    (8B)
    //
    // Order Replace (U) = 35 bytes:
    //   [11:18] orig_ref     (8B)
    //   [19:26] new_ref      (8B)
    //   [27:30] shares       (4B)
    //   [31:34] price        (4B)
    //
    // Order Executed (E) = 31 bytes:
    //   [11:18] order_ref    (8B)
    //   [19:22] exec_shares  (4B)
    //   [23:30] match_num    (8B)  — ignored
    //
    // Order Cancel (X) = 23 bytes:
    //   [11:18] order_ref    (8B)
    //   [19:22] cancelled    (4B)
    // -------------------------------------------------------------------------

    typedef enum logic [2:0] {
        T_NONE, T_ADD, T_ADD_MPID, T_DELETE, T_REPLACE, T_EXECUTE, T_CANCEL
    } msg_type_t;

    msg_type_t  cur_type;
    logic [7:0] byte_idx;   // position within current message (0=type byte)

    // Shift registers for multi-byte fields (big-endian accumulation)
    logic [63:0] sr64;
    logic [47:0] sr48;
    logic [31:0] sr32;

    // Latched common fields
    logic [15:0] f_stock_locate;
    logic [47:0] f_timestamp;

    // Clear all valid strobes by default
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            cur_type      <= T_NONE;
            byte_idx      <= 8'd0;
            sr64          <= '0;
            sr48          <= '0;
            sr32          <= '0;
            f_stock_locate<= '0;
            f_timestamp   <= '0;

            add_valid     <= 1'b0;
            del_valid     <= 1'b0;
            rep_valid     <= 1'b0;
            exe_valid     <= 1'b0;
            can_valid     <= 1'b0;

            add_stock_locate <= '0;
            add_timestamp    <= '0;
            add_order_ref    <= '0;
            add_side         <= 1'b0;
            add_shares       <= '0;
            add_stock        <= '0;
            add_price        <= '0;

            del_order_ref    <= '0;
            del_timestamp    <= '0;

            rep_orig_ref     <= '0;
            rep_new_ref      <= '0;
            rep_shares       <= '0;
            rep_price        <= '0;
            rep_timestamp    <= '0;

            exe_order_ref    <= '0;
            exe_shares       <= '0;
            exe_timestamp    <= '0;

            can_order_ref    <= '0;
            can_shares       <= '0;
            can_timestamp    <= '0;
        end else begin
            // Deassert all valids (single cycle pulses)
            add_valid <= 1'b0;
            del_valid <= 1'b0;
            rep_valid <= 1'b0;
            exe_valid <= 1'b0;
            can_valid <= 1'b0;

            if (in_valid) begin
                if (in_msg_start) begin
                    // --------------------------------------------------------
                    // Byte 0: message type — dispatch
                    // --------------------------------------------------------
                    byte_idx <= 8'd1;
                    case (in_data)
                        8'h41: cur_type <= T_ADD;       // 'A'
                        8'h46: cur_type <= T_ADD_MPID;  // 'F'
                        8'h44: cur_type <= T_DELETE;    // 'D'
                        8'h55: cur_type <= T_REPLACE;   // 'U'
                        8'h45: cur_type <= T_EXECUTE;   // 'E'
                        8'h58: cur_type <= T_CANCEL;    // 'X'
                        default: cur_type <= T_NONE;
                    endcase
                end else if (cur_type != T_NONE) begin
                    byte_idx <= byte_idx + 8'd1;

                    // --------------------------------------------------------
                    // Common header fields (same layout for all msg types)
                    // --------------------------------------------------------
                    case (byte_idx)
                        // Stock locate [1:2]
                        8'd1: f_stock_locate[15:8] <= in_data;
                        8'd2: f_stock_locate[7:0]  <= in_data;
                        // Tracking number [3:4] — ignored
                        // Timestamp [5:10]
                        8'd5:  f_timestamp[47:40] <= in_data;
                        8'd6:  f_timestamp[39:32] <= in_data;
                        8'd7:  f_timestamp[31:24] <= in_data;
                        8'd8:  f_timestamp[23:16] <= in_data;
                        8'd9:  f_timestamp[15:8]  <= in_data;
                        8'd10: f_timestamp[7:0]   <= in_data;
                        default: ; // handled below per-type
                    endcase

                    // --------------------------------------------------------
                    // Per-type field decoding
                    // --------------------------------------------------------
                    if (byte_idx >= 8'd11) begin
                        case (cur_type)

                            // --------------------------------------------------
                            // Add Order (A / F): bytes 11-35
                            // --------------------------------------------------
                            T_ADD, T_ADD_MPID: begin
                                case (byte_idx)
                                    // order_ref [11:18]
                                    8'd11: sr64[63:56] <= in_data;
                                    8'd12: sr64[55:48] <= in_data;
                                    8'd13: sr64[47:40] <= in_data;
                                    8'd14: sr64[39:32] <= in_data;
                                    8'd15: sr64[31:24] <= in_data;
                                    8'd16: sr64[23:16] <= in_data;
                                    8'd17: sr64[15:8]  <= in_data;
                                    8'd18: begin
                                        sr64[7:0]     <= in_data;
                                        add_order_ref <= {sr64[63:8], in_data};
                                    end
                                    // side [19]
                                    8'd19: add_side <= (in_data == 8'h42); // 'B'
                                    // shares [20:23]
                                    8'd20: sr32[31:24] <= in_data;
                                    8'd21: sr32[23:16] <= in_data;
                                    8'd22: sr32[15:8]  <= in_data;
                                    8'd23: begin
                                        sr32[7:0]    <= in_data;
                                        add_shares   <= {sr32[31:8], in_data};
                                    end
                                    // stock [24:31]
                                    8'd24: sr64[63:56] <= in_data;
                                    8'd25: sr64[55:48] <= in_data;
                                    8'd26: sr64[47:40] <= in_data;
                                    8'd27: sr64[39:32] <= in_data;
                                    8'd28: sr64[31:24] <= in_data;
                                    8'd29: sr64[23:16] <= in_data;
                                    8'd30: sr64[15:8]  <= in_data;
                                    8'd31: begin
                                        sr64[7:0]  <= in_data;
                                        add_stock  <= {sr64[63:8], in_data};
                                    end
                                    // price [32:35]
                                    8'd32: sr32[31:24] <= in_data;
                                    8'd33: sr32[23:16] <= in_data;
                                    8'd34: sr32[15:8]  <= in_data;
                                    8'd35: begin
                                        add_price        <= {sr32[31:8], in_data};
                                        add_stock_locate <= f_stock_locate;
                                        add_timestamp    <= f_timestamp;
                                        add_valid        <= 1'b1;
                                        cur_type         <= T_NONE;
                                    end
                                    default: ; // MPID byte at 36-39 ignored
                                endcase
                            end

                            // --------------------------------------------------
                            // Delete Order (D): bytes 11-18
                            // --------------------------------------------------
                            T_DELETE: begin
                                case (byte_idx)
                                    8'd11: sr64[63:56] <= in_data;
                                    8'd12: sr64[55:48] <= in_data;
                                    8'd13: sr64[47:40] <= in_data;
                                    8'd14: sr64[39:32] <= in_data;
                                    8'd15: sr64[31:24] <= in_data;
                                    8'd16: sr64[23:16] <= in_data;
                                    8'd17: sr64[15:8]  <= in_data;
                                    8'd18: begin
                                        del_order_ref <= {sr64[63:8], in_data};
                                        del_timestamp <= f_timestamp;
                                        del_valid     <= 1'b1;
                                        cur_type      <= T_NONE;
                                    end
                                    default: ;
                                endcase
                            end

                            // --------------------------------------------------
                            // Order Replace (U): bytes 11-34
                            // --------------------------------------------------
                            T_REPLACE: begin
                                case (byte_idx)
                                    // orig_ref [11:18]
                                    8'd11: sr64[63:56] <= in_data;
                                    8'd12: sr64[55:48] <= in_data;
                                    8'd13: sr64[47:40] <= in_data;
                                    8'd14: sr64[39:32] <= in_data;
                                    8'd15: sr64[31:24] <= in_data;
                                    8'd16: sr64[23:16] <= in_data;
                                    8'd17: sr64[15:8]  <= in_data;
                                    8'd18: begin
                                        rep_orig_ref <= {sr64[63:8], in_data};
                                    end
                                    // new_ref [19:26]
                                    8'd19: sr64[63:56] <= in_data;
                                    8'd20: sr64[55:48] <= in_data;
                                    8'd21: sr64[47:40] <= in_data;
                                    8'd22: sr64[39:32] <= in_data;
                                    8'd23: sr64[31:24] <= in_data;
                                    8'd24: sr64[23:16] <= in_data;
                                    8'd25: sr64[15:8]  <= in_data;
                                    8'd26: begin
                                        rep_new_ref <= {sr64[63:8], in_data};
                                    end
                                    // shares [27:30]
                                    8'd27: sr32[31:24] <= in_data;
                                    8'd28: sr32[23:16] <= in_data;
                                    8'd29: sr32[15:8]  <= in_data;
                                    8'd30: begin
                                        rep_shares <= {sr32[31:8], in_data};
                                    end
                                    // price [31:34]
                                    8'd31: sr32[31:24] <= in_data;
                                    8'd32: sr32[23:16] <= in_data;
                                    8'd33: sr32[15:8]  <= in_data;
                                    8'd34: begin
                                        rep_price     <= {sr32[31:8], in_data};
                                        rep_timestamp <= f_timestamp;
                                        rep_valid     <= 1'b1;
                                        cur_type      <= T_NONE;
                                    end
                                    default: ;
                                endcase
                            end

                            // --------------------------------------------------
                            // Order Executed (E): bytes 11-22
                            // --------------------------------------------------
                            T_EXECUTE: begin
                                case (byte_idx)
                                    8'd11: sr64[63:56] <= in_data;
                                    8'd12: sr64[55:48] <= in_data;
                                    8'd13: sr64[47:40] <= in_data;
                                    8'd14: sr64[39:32] <= in_data;
                                    8'd15: sr64[31:24] <= in_data;
                                    8'd16: sr64[23:16] <= in_data;
                                    8'd17: sr64[15:8]  <= in_data;
                                    8'd18: begin
                                        exe_order_ref <= {sr64[63:8], in_data};
                                    end
                                    8'd19: sr32[31:24] <= in_data;
                                    8'd20: sr32[23:16] <= in_data;
                                    8'd21: sr32[15:8]  <= in_data;
                                    8'd22: begin
                                        exe_shares    <= {sr32[31:8], in_data};
                                        exe_timestamp <= f_timestamp;
                                        exe_valid     <= 1'b1;
                                        cur_type      <= T_NONE;
                                        // match number bytes 23-30 will arrive
                                        // but cur_type=NONE so they are ignored
                                    end
                                    default: ;
                                endcase
                            end

                            // --------------------------------------------------
                            // Order Cancel (X): bytes 11-22
                            // --------------------------------------------------
                            T_CANCEL: begin
                                case (byte_idx)
                                    8'd11: sr64[63:56] <= in_data;
                                    8'd12: sr64[55:48] <= in_data;
                                    8'd13: sr64[47:40] <= in_data;
                                    8'd14: sr64[39:32] <= in_data;
                                    8'd15: sr64[31:24] <= in_data;
                                    8'd16: sr64[23:16] <= in_data;
                                    8'd17: sr64[15:8]  <= in_data;
                                    8'd18: begin
                                        can_order_ref <= {sr64[63:8], in_data};
                                    end
                                    8'd19: sr32[31:24] <= in_data;
                                    8'd20: sr32[23:16] <= in_data;
                                    8'd21: sr32[15:8]  <= in_data;
                                    8'd22: begin
                                        can_shares    <= {sr32[31:8], in_data};
                                        can_timestamp <= f_timestamp;
                                        can_valid     <= 1'b1;
                                        cur_type      <= T_NONE;
                                    end
                                    default: ;
                                endcase
                            end

                            default: ; // T_NONE — skip
                        endcase
                    end
                end
            end
        end
    end

endmodule
