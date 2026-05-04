// =============================================================================
// eth_mii_rx.sv
// Arty A7-100T ITCH Demo
//
// MII receive path for 100BASE-TX.
// Assembles 4-bit nibbles into bytes, strips preamble/SFD,
// counts off the Ethernet+IP+UDP headers (42 bytes fixed),
// then asserts byte_valid and udp_sof for the UDP payload bytes.
//
// MII timing (100BASE-TX):
//   eth_rx_clk = 25 MHz, sourced by PHY (SRCC-capable pin F15 on Arty A7)
//   rxd[3:0]   stable on rising edge of eth_rx_clk
//   rx_dv      = 1 while frame data is valid
//   Nibble ordering: lower nibble of byte on first clock, upper nibble second
//     Byte 0x55 = 0101_0101 → nibbles 0x5, 0x5
//     SFD  0xD5 = 1101_0101 → nibbles 0x5, 0xD
//
// CDC note:
//   All outputs (byte_out, byte_valid, udp_sof) are in the eth_rx_clk domain.
//   The top-level converts byte_valid/udp_sof into sys_clk-domain pulses using
//   a toggle-synchroniser; byte_out is treated as stable data protected by a
//   false-path constraint (stable for ≥2 eth_rx_clk cycles = 80 ns = 8 sys_clk
//   cycles before the synchronised pulse fires).
//
// Assumptions (demo simplifications):
//   - IPv4, no IP options (fixed 20-byte IP header)
//   - UDP only; no VLAN tags
//   - No FCS or IP/UDP checksum validation
//   - rxerr is accepted as a port but frame-abort logic not implemented
// =============================================================================

module eth_mii_rx (
    input  logic        eth_rx_clk,  // 25 MHz from PHY
    input  logic        rst,
    input  logic [3:0]  rxd,
    input  logic        rx_dv,
    input  logic        rxerr,       // PHY receive-error flag (unused in demo)

    output logic [7:0]  byte_out,
    output logic        byte_valid,  // 1-cycle strobe per valid payload byte
    output logic        udp_sof      // 1-cycle strobe: byte_out is first UDP payload byte
);

    // -------------------------------------------------------------------------
    // Nibble → byte assembler
    // Two eth_rx_clk cycles per byte: first = lower nibble, second = upper.
    // -------------------------------------------------------------------------
    logic        nibble_cnt;   // 0 = capturing lower nibble, 1 = upper (byte complete)
    logic [3:0]  lo_nibble;
    logic        byte_ready;

    always_ff @(posedge eth_rx_clk) begin
        if (rst) begin
            nibble_cnt <= 1'b0;
            lo_nibble  <= 4'h0;
            byte_ready <= 1'b0;
            byte_out   <= 8'h00;
        end else begin
            byte_ready <= 1'b0;
            if (rx_dv) begin
                nibble_cnt <= ~nibble_cnt;
                if (!nibble_cnt) begin
                    lo_nibble <= rxd;                    // latch lower nibble
                end else begin
                    byte_out   <= {rxd, lo_nibble};      // {high[7:4], low[3:0]}
                    byte_ready <= 1'b1;
                end
            end else begin
                nibble_cnt <= 1'b0;                      // reset on inter-frame gap
            end
        end
    end

    // -------------------------------------------------------------------------
    // Frame state machine — strips preamble, SFD, and 42-byte header
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        FS_IDLE,      // waiting for first preamble byte
        FS_PREAMBLE,  // consuming 0x55 preamble bytes
        FS_HEADER,    // skipping 42-byte Eth+IP+UDP header
        FS_PAYLOAD,   // emitting UDP payload bytes
        FS_DRAIN      // (not used; rx_dv falling resets to IDLE directly)
    } frame_state_t;

    frame_state_t fstate;
    logic [5:0]   hdr_cnt;      // header byte counter (0..41)
    logic         first_payload;
    logic [7:0]   etype_hi;     // latches EtherType high byte (hdr_cnt==12)

    always_ff @(posedge eth_rx_clk) begin
        if (rst) begin
            fstate        <= FS_IDLE;
            hdr_cnt       <= 6'd0;
            byte_valid    <= 1'b0;
            udp_sof       <= 1'b0;
            first_payload <= 1'b0;
            etype_hi      <= 8'h00;
        end else begin
            byte_valid <= 1'b0;
            udp_sof    <= 1'b0;

            if (!rx_dv) begin
                // End of frame: reset unconditionally
                fstate  <= FS_IDLE;
                hdr_cnt <= 6'd0;
            end else if (byte_ready) begin
                case (fstate)
                    FS_IDLE: begin
                        if (byte_out == 8'h55)
                            fstate <= FS_PREAMBLE;
                    end

                    FS_PREAMBLE: begin
                        if (byte_out == 8'h55) begin
                            // more preamble — stay
                        end else if (byte_out == 8'hD5) begin
                            fstate  <= FS_HEADER;
                            hdr_cnt <= 6'd0;
                        end else begin
                            fstate <= FS_IDLE;
                        end
                    end

                    FS_HEADER: begin
                        // Latch EtherType high byte (byte 12 of Ethernet header)
                        if (hdr_cnt == 6'd12)
                            etype_hi <= byte_out;

                        // EtherType low byte (byte 13): check for IPv4 (0x0800).
                        // Anything else goes to FS_DRAIN — silently discard the frame.
                        if (hdr_cnt == 6'd13) begin
                            if ({etype_hi, byte_out} != 16'h0800)
                                fstate <= FS_DRAIN;
                        end

                        if (hdr_cnt == 6'd41) begin
                            fstate        <= FS_PAYLOAD;
                            first_payload <= 1'b1;
                        end else begin
                            hdr_cnt <= hdr_cnt + 1;
                        end
                    end

                    FS_PAYLOAD: begin
                        byte_valid <= 1'b1;
                        if (first_payload) begin
                            udp_sof       <= 1'b1;
                            first_payload <= 1'b0;
                        end
                    end

                    FS_DRAIN: begin
                        // Non-IPv4 frame: sit here until rx_dv drops
                    end

                    default: fstate <= FS_IDLE;
                endcase
            end
        end
    end

endmodule
