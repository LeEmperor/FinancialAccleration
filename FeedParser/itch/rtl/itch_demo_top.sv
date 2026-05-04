// =============================================================================
// itch_demo_top.sv
// Arty A7-100T ITCH Demo — Top Level
//
// Wires together:
//   eth_mii_rx       — MII 4-bit nibble → byte-serial converter (100Mb)
//   moldudp64_parser — strips MoldUDP64 header
//   itch_decoder     — decodes A/D/U/E/X messages
//   order_book       — maintains price levels, outputs BBO
//   uart_reporter    — sends ASCII events over USB-UART
//
// Arty A7-100T pin assignments (see itch_demo_constraints_arty100t.xdc):
//   E3          — 100 MHz system clock
//   D9          — BTN0, active high, used as reset
//   A8          — SW0, slide up (1) = run, slide down (0) = hold reset
//   D10         — UART TX → FTDI (/dev/ttyUSBx at 115200)
//
// Ethernet — MII interface (LAN8720 / SMSC PHY on Arty):
//   F15         — eth_rx_clk (25 MHz, PHY output, clock-capable SRCC pin)
//   D18/E17/E18/G17 — MII RXD[3:0]
//   G16         — MII RX_DV
//   C17         — MII RXERR
//   H15         — MII TX_EN  (tied off — demo is receive-only)
//   H14/J14/J13/H17 — MII TXD[3:0] (tied off)
//   C16         — PHY hard reset (active low)
//
// Clock domains:
//   sys_clk  (100 MHz) — all parser/book/reporter logic
//   eth_rx_clk (25 MHz, from PHY) — eth_mii_rx nibble assembler
//
// CDC (eth_rx_clk → sys_clk):
//   A toggle-synchroniser converts the 1-cycle eth_rx_clk byte_valid/udp_sof
//   strobes into clean 1-cycle sys_clk pulses.  byte_out is stable data
//   covered by a false-path constraint (≥80 ns stable before the pulse fires).
// =============================================================================

module itch_demo_top (
    input  logic        sys_clk,     // 100 MHz -> only clock pin going in

    input  logic        sw0,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        sw1,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        sw2,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        sw3,         // SW0: slide UP = run, DOWN = hold reset

    input  logic        btn0,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        btn1,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        btn2,         // SW0: slide UP = run, DOWN = hold reset
    input  logic        btn3,         // SW0: slide UP = run, DOWN = hold reset

    // MII interface
    input  logic        eth_rx_clk,  // 25 MHz from PHY (SRCC pin)
    input  logic [3:0]  eth_rxd,
    input  logic        eth_rx_dv,
    input  logic        eth_rxerr,
    output logic        eth_rst_n,   // PHY hard reset, active low

    output logic        eth_tx_en,   // tied off — RX only
    output logic [3:0]  eth_txd,     // tied off

    // UART
    output logic        uart_tx,

    // Debug LEDs
    output logic [3:0]  led
);

    // -------------------------------------------------------------------------
    // Reset — synchronise to sys_clk.
    // Deasserted once BTN0 released and SW0 slid up.
    // -------------------------------------------------------------------------
    logic rst; assign rst = btn0;
    logic rst_meta;
    logic rst_sync_sys;

    always_ff @(posedge sys_clk) begin
      if (rst) begin
        rst_meta <= 0;
        rst_sync_sys <= 0;
      end else begin
        rst_meta <= rst;
        rst_sync_sys <= rst_meta;
      end
    end
    assign 

    // Keep PHY out of reset after 1 ms (100 k cycles @ 100 MHz)
    logic [16:0] phy_rst_cnt;
    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            phy_rst_cnt <= '0;
            eth_rst_n   <= 1'b0;
        end else begin
            if (phy_rst_cnt != 17'h1FFFF) phy_rst_cnt <= phy_rst_cnt + 1;
            else                          eth_rst_n   <= 1'b1;
        end
    end

    // TX tie-off (receive-only demo)
    assign eth_tx_en = 1'b0;
    assign eth_txd   = 4'b0000;

    // -------------------------------------------------------------------------
    // MII → byte-serial converter  (eth_rx_clk domain)
    // -------------------------------------------------------------------------
    logic [7:0]  mii_byte;
    logic        mii_byte_valid_eth;  // 1-cycle strobe in eth_rx_clk domain
    logic        mii_sof_eth;         // 1-cycle strobe in eth_rx_clk domain

    eth_mii_rx u_mii (
        .eth_rx_clk (eth_rx_clk),
        .rst_n      (rst_n),          // coarse reset; metastability acceptable here
        .rxd        (eth_rxd),
        .rx_dv      (eth_rx_dv),
        .rxerr      (eth_rxerr),
        .byte_out   (mii_byte),
        .byte_valid (mii_byte_valid_eth),
        .udp_sof    (mii_sof_eth)
    );

    // -------------------------------------------------------------------------
    // CDC: eth_rx_clk (25 MHz) → sys_clk (100 MHz)
    //
    // Toggle registers (eth_rx_clk domain):
    //   mii_byte_toggle flips each time a new byte is valid.
    //   mii_is_sof latches whether that byte is a UDP SOF.
    //   Both are registered on the same clock edge, so they're always coherent.
    //
    // 2-FF synchroniser + edge detect (sys_clk domain):
    //   Converts the toggle edge into a clean 1-cycle sys_clk pulse.
    //   mii_byte and mii_is_sof are stable ≥80 ns before the pulse fires,
    //   covered by a set_false_path in the XDC.
    // -------------------------------------------------------------------------
    logic mii_byte_toggle;
    logic mii_is_sof;

    always_ff @(posedge eth_rx_clk) begin
        if (!rst_n) begin
            mii_byte_toggle <= 1'b0;
            mii_is_sof      <= 1'b0;
        end else if (mii_byte_valid_eth) begin
            mii_byte_toggle <= ~mii_byte_toggle;
            mii_is_sof      <= mii_sof_eth;
        end
    end

    logic [2:0] byte_sync;
    always_ff @(posedge sys_clk) begin
        if (!rst_n) byte_sync <= 3'b000;
        else        byte_sync <= {byte_sync[1:0], mii_byte_toggle};
    end

    wire in_valid_sys = byte_sync[2] ^ byte_sync[1];  // 1-cycle sys_clk pulse
    wire in_sof_sys   = in_valid_sys & mii_is_sof;    // valid only when in_valid fires

    // -------------------------------------------------------------------------
    // MoldUDP64 parser
    // -------------------------------------------------------------------------
    logic [7:0]  itch_byte;
    logic        itch_valid;
    logic        itch_msg_start;
    logic        gap_det;
    logic [63:0] gap_seq;

    moldudp64_parser u_mold (
        .clk          (sys_clk),
        .rst_n        (rst_n),
        .in_data      (mii_byte),
        .in_valid     (in_valid_sys),
        .in_sof       (in_sof_sys),
        .out_data     (itch_byte),
        .out_valid    (itch_valid),
        .out_msg_start(itch_msg_start),
        .gap_detected (gap_det),
        .seq_num      (gap_seq)
    );

    // -------------------------------------------------------------------------
    // ITCH decoder
    // -------------------------------------------------------------------------
    logic        add_valid;
    logic [15:0] add_stock_locate;
    logic [47:0] add_timestamp;
    logic [63:0] add_order_ref;
    logic        add_side;
    logic [31:0] add_shares, add_price;
    logic [63:0] add_stock;

    logic        del_valid;
    logic [63:0] del_order_ref;
    logic [47:0] del_timestamp;

    logic        rep_valid;
    logic [63:0] rep_orig_ref, rep_new_ref;
    logic [31:0] rep_shares, rep_price;
    logic [47:0] rep_timestamp;

    logic        exe_valid;
    logic [63:0] exe_order_ref;
    logic [31:0] exe_shares;
    logic [47:0] exe_timestamp;

    logic        can_valid;
    logic [63:0] can_order_ref;
    logic [31:0] can_shares;
    logic [47:0] can_timestamp;

    itch_decoder u_decoder (
        .clk             (sys_clk),
        .rst_n           (rst_n),
        .in_data         (itch_byte),
        .in_valid        (itch_valid),
        .in_msg_start    (itch_msg_start),
        .add_valid       (add_valid),
        .add_stock_locate(add_stock_locate),
        .add_timestamp   (add_timestamp),
        .add_order_ref   (add_order_ref),
        .add_side        (add_side),
        .add_shares      (add_shares),
        .add_stock       (add_stock),
        .add_price       (add_price),
        .del_valid       (del_valid),
        .del_order_ref   (del_order_ref),
        .del_timestamp   (del_timestamp),
        .rep_valid       (rep_valid),
        .rep_orig_ref    (rep_orig_ref),
        .rep_new_ref     (rep_new_ref),
        .rep_shares      (rep_shares),
        .rep_price       (rep_price),
        .rep_timestamp   (rep_timestamp),
        .exe_valid       (exe_valid),
        .exe_order_ref   (exe_order_ref),
        .exe_shares      (exe_shares),
        .exe_timestamp   (exe_timestamp),
        .can_valid       (can_valid),
        .can_order_ref   (can_order_ref),
        .can_shares      (can_shares),
        .can_timestamp   (can_timestamp)
    );

    // -------------------------------------------------------------------------
    // Order book
    // -------------------------------------------------------------------------
    logic [31:0] best_bid_price, best_bid_size;
    logic [31:0] best_ask_price, best_ask_size;
    logic        bbo_updated;

    order_book u_book (
        .clk            (sys_clk),
        .rst_n          (rst_n),
        .add_valid      (add_valid),
        .add_order_ref  (add_order_ref),
        .add_side       (add_side),
        .add_shares     (add_shares),
        .add_price      (add_price),
        .del_valid      (del_valid),
        .del_order_ref  (del_order_ref),
        .rep_valid      (rep_valid),
        .rep_orig_ref   (rep_orig_ref),
        .rep_new_ref    (rep_new_ref),
        .rep_shares     (rep_shares),
        .rep_price      (rep_price),
        .exe_valid      (exe_valid),
        .exe_order_ref  (exe_order_ref),
        .exe_shares     (exe_shares),
        .can_valid      (can_valid),
        .can_order_ref  (can_order_ref),
        .can_shares     (can_shares),
        .best_bid_price (best_bid_price),
        .best_bid_size  (best_bid_size),
        .best_ask_price (best_ask_price),
        .best_ask_size  (best_ask_size),
        .bbo_updated    (bbo_updated)
    );

    // -------------------------------------------------------------------------
    // UART reporter
    // -------------------------------------------------------------------------
    uart_reporter #(
        .CLK_HZ (100_000_000),
        .BAUD   (115_200)
    ) u_uart (
        .clk            (sys_clk),
        .rst_n          (rst_n),
        .add_valid      (add_valid),
        .add_order_ref  (add_order_ref),
        .add_side       (add_side),
        .add_shares     (add_shares),
        .add_price      (add_price),
        .del_valid      (del_valid),
        .del_order_ref  (del_order_ref),
        .rep_valid      (rep_valid),
        .rep_orig_ref   (rep_orig_ref),
        .rep_new_ref    (rep_new_ref),
        .rep_shares     (rep_shares),
        .rep_price      (rep_price),
        .exe_valid      (exe_valid),
        .exe_order_ref  (exe_order_ref),
        .exe_shares     (exe_shares),
        .can_valid      (can_valid),
        .can_order_ref  (can_order_ref),
        .can_shares     (can_shares),
        .bbo_updated    (bbo_updated),
        .best_bid_price (best_bid_price),
        .best_bid_size  (best_bid_size),
        .best_ask_price (best_ask_price),
        .best_ask_size  (best_ask_size),
        .gap_detected   (gap_det),
        .gap_seq        (gap_seq),
        .uart_tx        (uart_tx)
    );

    // -------------------------------------------------------------------------
    // Debug LEDs
    //   led[0] — heartbeat (~1 Hz)
    //   led[1] — any ITCH message decoded this cycle
    //   led[2] — BBO updated this cycle
    //   led[3] — sequence gap detected (sticky until reset)
    // -------------------------------------------------------------------------
    logic [26:0] hb_cnt;
    logic        gap_latch;

    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            hb_cnt    <= '0;
            gap_latch <= 1'b0;
        end else begin
            hb_cnt <= hb_cnt + 1;
            if (gap_det) gap_latch <= 1'b1;
        end
    end

    assign led[0] = hb_cnt[26];
    assign led[1] = add_valid | del_valid | rep_valid | exe_valid | can_valid;
    assign led[2] = bbo_updated;
    assign led[3] = gap_latch;

endmodule
