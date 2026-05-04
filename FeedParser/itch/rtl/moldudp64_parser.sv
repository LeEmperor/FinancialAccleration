// =============================================================================
// moldudp64_parser.sv
// Arty A7-100T ITCH Demo
//
// Accepts raw UDP payload bytes one at a time (from Ethernet RX path).
// Strips the 20-byte MoldUDP64 header, then iterates over message blocks,
// emitting individual ITCH message bytes with a valid strobe.
//
// Interface:
//   in_data / in_valid / in_sof  - byte-serial UDP payload input
//                                  in_sof pulses for exactly 1 cycle on the
//                                  first byte of each new UDP packet
//   out_data / out_valid         - byte-serial ITCH message body output
//   out_msg_start                - pulses 1 cycle on the type byte of each
//                                  new ITCH message
//   gap_detected                 - pulses 1 cycle when a sequence gap is seen
//   seq_num                      - current expected sequence number (debug)
// =============================================================================

module moldudp64_parser (
    input  logic        clk,
    input  logic        rst_n,

    // UDP payload in (byte serial)
    input  logic [7:0]  in_data,
    input  logic        in_valid,
    input  logic        in_sof,        // start-of-frame: first byte of UDP payload

    // ITCH message bytes out
    output logic [7:0]  out_data,
    output logic        out_valid,
    output logic        out_msg_start, // first byte of a new ITCH message (type byte)

    // Status
    output logic        gap_detected,
    output logic [63:0] seq_num        // next expected seq num (for debug/UART)
);

    // -------------------------------------------------------------------------
    // MoldUDP64 header layout (all big-endian):
    //   Bytes  0- 9 : Session ID (10 bytes, ignored)
    //   Bytes 10-17 : Sequence Number (uint64)
    //   Bytes 18-19 : Message Count (uint16)
    // Then for each message block:
    //   Bytes  0- 1 : Message Length (uint16)  — includes type byte
    //   Bytes  2..L : ITCH message body
    // -------------------------------------------------------------------------

    typedef enum logic [3:0] {
        S_SESSION,      // consuming session ID bytes (10)
        S_SEQNUM,       // consuming 8-byte sequence number
        S_MSGCOUNT,     // consuming 2-byte message count
        S_BLK_LEN_HI,  // high byte of block length
        S_BLK_LEN_LO,  // low byte of block length
        S_MSG_BODY,     // emitting ITCH message bytes
        S_IDLE          // waiting for next SOF
    } state_t;

    state_t             state;
    logic [3:0]         byte_cnt;       // within-field byte counter (max 10)
    logic [63:0]        pkt_seqnum;     // sequence number from this packet
    logic [15:0]        msg_count;      // messages remaining in this packet
    logic [15:0]        blk_len;        // bytes remaining in current block
    logic [63:0]        expected_seq;   // next expected sequence number
    logic [15:0]        pkt_msg_count;  // original message count (for expected_seq advance)
    logic               first_msg_byte; // next out byte is the type byte

    // Sequence number shift-in register
    logic [63:0]        seqnum_sr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            byte_cnt     <= '0;
            pkt_seqnum   <= '0;
            msg_count    <= '0;
            blk_len      <= '0;
            expected_seq <= 64'd1;   // NASDAQ sequences start at 1
            seqnum_sr    <= '0;
            pkt_msg_count<= '0;
            out_valid    <= 1'b0;
            out_data     <= 8'h00;
            out_msg_start<= 1'b0;
            gap_detected <= 1'b0;
            seq_num      <= 64'd1;
        end else begin
            // Default pulse signals
            out_valid     <= 1'b0;
            out_msg_start <= 1'b0;
            gap_detected  <= 1'b0;

            // SOF always resets us to the start of a new packet
            if (in_sof && in_valid) begin
                state        <= S_SESSION;
                byte_cnt     <= 4'd0;
                seqnum_sr    <= '0;
            end else if (in_valid) begin
                case (state)

                    // ----------------------------------------------------------
                    // Skip 10-byte session ID.
                    // The SOF byte is session byte 0 (handled by the in_sof branch
                    // above, which resets byte_cnt to 0).  So we only need 9 more
                    // bytes here before moving on to the sequence number field.
                    // ----------------------------------------------------------
                    S_SESSION: begin
                        if (byte_cnt == 4'd8) begin
                            state    <= S_SEQNUM;
                            byte_cnt <= 4'd0;
                        end else begin
                            byte_cnt <= byte_cnt + 1'b1;
                        end
                    end

                    // ----------------------------------------------------------
                    // Shift in 8-byte big-endian sequence number
                    // ----------------------------------------------------------
                    S_SEQNUM: begin
                        seqnum_sr <= {seqnum_sr[55:0], in_data};
                        if (byte_cnt == 4'd7) begin
                            pkt_seqnum <= {seqnum_sr[55:0], in_data};
                            state      <= S_MSGCOUNT;
                            byte_cnt   <= 4'd0;
                        end else begin
                            byte_cnt <= byte_cnt + 1'b1;
                        end
                    end

                    // ----------------------------------------------------------
                    // 2-byte message count
                    // ----------------------------------------------------------
                    S_MSGCOUNT: begin
                        if (byte_cnt == 4'd0) begin
                            msg_count[15:8] <= in_data;
                            byte_cnt        <= 4'd1;
                        end else begin
                            msg_count[7:0] <= in_data;
                            byte_cnt       <= 4'd0;

                            // Gap detection
                            if ({seqnum_sr[55:0], in_data} != 8'hxx) begin // suppress lint
                            end
                            if (pkt_seqnum != expected_seq && expected_seq != 64'd1) begin
                                gap_detected <= 1'b1;
                            end

                            // Move to first block or idle if count==0
                            if ({msg_count[15:8], in_data} == 16'd0) begin
                                state <= S_IDLE;
                            end else begin
                                msg_count     <= {msg_count[15:8], in_data};
                                pkt_msg_count <= {msg_count[15:8], in_data}; // save for expected_seq
                                state         <= S_BLK_LEN_HI;
                            end
                        end
                    end

                    // ----------------------------------------------------------
                    // Block length high byte
                    // ----------------------------------------------------------
                    S_BLK_LEN_HI: begin
                        blk_len[15:8] <= in_data;
                        state         <= S_BLK_LEN_LO;
                    end

                    // ----------------------------------------------------------
                    // Block length low byte — now we know how many bytes follow
                    // ----------------------------------------------------------
                    S_BLK_LEN_LO: begin
                        blk_len[7:0]  <= in_data;
                        first_msg_byte <= 1'b1;
                        state          <= S_MSG_BODY;
                    end

                    // ----------------------------------------------------------
                    // Emit ITCH message bytes
                    // ----------------------------------------------------------
                    S_MSG_BODY: begin
                        out_data      <= in_data;
                        out_valid     <= 1'b1;
                        out_msg_start <= first_msg_byte;
                        first_msg_byte <= 1'b0;

                        if (blk_len == 16'd1) begin
                            // Last byte of this block
                            if (msg_count == 16'd1) begin
                                // Last message in packet — advance expected seq by
                                // the original message count (MoldUDP64: seq N with
                                // M messages means next expected = N + M)
                                expected_seq <= pkt_seqnum + pkt_msg_count;
                                seq_num      <= pkt_seqnum + pkt_msg_count;
                                state        <= S_IDLE;
                            end else begin
                                msg_count <= msg_count - 1'b1;
                                state     <= S_BLK_LEN_HI;
                            end
                        end else begin
                            blk_len <= blk_len - 1'b1;
                        end
                    end

                    S_IDLE: begin
                        // wait for next SOF
                    end

                    default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule
