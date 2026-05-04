// =============================================================================
// eth_rmii_rx.sv
// Arty A7-100T ITCH Demo
//
// Minimal RMII receiver for 100BASE-TX.
// Assembles 2-bit dibits into bytes, strips preamble/SFD,
// counts off the Ethernet+IP+UDP headers (42 bytes fixed),
// then asserts byte_valid and udp_sof for the UDP payload bytes.
//
// Assumptions (valid for demo against a known ITCH feed sender):
//   - IPv4, no IP options (fixed 20-byte header)
//   - UDP only
//   - No VLAN tags
//   - We don't validate checksums or dest port (add those for production)
//
// RMII timing:
//   eth_clk = 50 MHz (from PHY REF_CLK pin)
//   rxd[1:0] stable on rising edge of eth_clk
//   rx_dv = 1 while frame is valid
//   Preamble = 0x55 x7, SFD = 0xD5
//   Dibits are sent LSB-first: byte 0x55 = dibits 01,01,01,01
// =============================================================================

module eth_rmii_rx (
    input  logic        eth_clk,    // 50 MHz RMII ref clock
    input  logic        rst_n,
    input  logic [1:0]  rxd,
    input  logic        rx_dv,

    output logic [7:0]  byte_out,
    output logic        byte_valid, // strobes for 1 eth_clk cycle per byte
    output logic        udp_sof     // strobes on first byte of UDP payload
);

    // -------------------------------------------------------------------------
    // Dibit → byte assembler
    // -------------------------------------------------------------------------
    logic [1:0]  dibit_cnt;    // 0..3 (4 dibits = 1 byte)
    logic [7:0]  shift;        // shift register, LSB first
    logic        byte_ready;

    always_ff @(posedge eth_clk) begin
        if (!rst_n) begin
            dibit_cnt  <= 2'd0;
            shift      <= 8'h00;
            byte_ready <= 1'b0;
            byte_out   <= 8'h00;
        end else begin
            byte_ready <= 1'b0;
            if (rx_dv) begin
                shift     <= {rxd, shift[7:2]};  // LSB first into MSB position
                dibit_cnt <= dibit_cnt + 1;
                if (dibit_cnt == 2'd3) begin
                    byte_out   <= {rxd, shift[7:2]};
                    byte_ready <= 1'b1;
                end
            end else begin
                dibit_cnt <= 2'd0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Frame state machine — strip preamble, headers, emit payload
    // -------------------------------------------------------------------------
    typedef enum logic [2:0] {
        FS_IDLE,        // waiting for frame
        FS_PREAMBLE,    // consuming preamble bytes (0x55)
        FS_SFD,         // waiting for SFD (0xD5)
        FS_HEADER,      // skipping 42-byte Eth+IP+UDP header
        FS_PAYLOAD,     // emitting UDP payload bytes
        FS_DRAIN        // rx_dv gone, discard until next frame
    } frame_state_t;

    frame_state_t fstate;
    logic [5:0]   hdr_cnt;   // header byte counter (max 42)
    logic         first_payload;

    always_ff @(posedge eth_clk) begin
        if (!rst_n) begin
            fstate        <= FS_IDLE;
            hdr_cnt       <= 6'd0;
            byte_valid    <= 1'b0;
            udp_sof       <= 1'b0;
            first_payload <= 1'b0;
        end else begin
            byte_valid <= 1'b0;
            udp_sof    <= 1'b0;

            if (!rx_dv) begin
                fstate <= FS_IDLE;
                hdr_cnt <= 6'd0;
            end else if (byte_ready) begin
                case (fstate)
                    FS_IDLE: begin
                        if (byte_out == 8'h55) begin
                            fstate <= FS_PREAMBLE;
                        end
                    end

                    FS_PREAMBLE: begin
                        if (byte_out == 8'h55) begin
                            // keep consuming preamble
                        end else if (byte_out == 8'hD5) begin
                            fstate  <= FS_HEADER;
                            hdr_cnt <= 6'd0;
                        end else begin
                            fstate <= FS_IDLE; // invalid
                        end
                    end

                    FS_HEADER: begin
                        // Skip 42 bytes: 14 (ETH) + 20 (IP) + 8 (UDP)
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

                    default: fstate <= FS_IDLE;
                endcase
            end
        end
    end

endmodule
