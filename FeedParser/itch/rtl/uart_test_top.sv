// =============================================================================
// uart_test_top.sv
// Arty A7-100T — UART reporter hardware validation test
//
// Bypasses the Ethernet / ITCH pipeline.  On every reset (BTN0) the
// sequencer fires 8 canned events into uart_reporter with a 20 ms gap
// between each, then stops.  The UART output can be validated against the
// companion Python script:
//
//   python3 scripts/validate_uart.py --port /dev/ttyUSB1
//
// Expected output (8 lines):
//   ADD  REF=0000000000001001 SIDE=B SZ=000003E8 PX=0012D484
//   ADD  REF=0000000000001002 SIDE=S SZ=000001F4 PX=0012D678
//   BBO  BID=0012D484x000003E8 ASK=0012D678x000001F4
//   EXE  REF=0000000000001001 SZ=000001F4
//   CAN  REF=0000000000001002 SZ=00000064
//   DEL  REF=0000000000001001
//   REP  OLD=0000000000001002 NEW=0000000000001010 SZ=000000C8 PX=0012D8A8
//   GAP  SEQ=0000000000000008
//
// LEDs:
//   LED[0] — heartbeat (~1 Hz)
//   LED[1] — event strobe (pulses on each fired event)
//   LED[2] — all 8 events sent (stays on)
//   LED[3] — unused
//
// Pin assignments identical to itch_demo_top; use the same XDC file.
// =============================================================================

module uart_test_top (
    input  logic        sys_clk,   // 100 MHz  (E3)
    input  logic        rst_btn,   // BTN0 active-HIGH (D9) — Arty buttons pulled low
    output logic        uart_tx,   // USB-UART TX  (D10)
    output logic [3:0]  led
);

    // -------------------------------------------------------------------------
    // Reset: power-on reset auto-releases + BTN0 manual reset (active-high)
    // -------------------------------------------------------------------------
    logic [3:0] por_pipe;
    always_ff @(posedge sys_clk)
        por_pipe <= {por_pipe[2:0], 1'b1};

    wire rst_n = por_pipe[3] & ~rst_btn;

    // -------------------------------------------------------------------------
    // Event data ROM — 8 canned events
    //
    // Prices are ITCH wire format (actual × 10000).
    //   0x0012D484 ≈ $123.40   0x0012D678 ≈ $123.45
    //   0x0012D8A8 ≈ $123.50
    // These match the values used in tb_itch_demo.sv / tb_uart_reporter.sv.
    // -------------------------------------------------------------------------
    localparam int NUM_EVENTS = 8;

    // Event type encoding
    localparam logic [2:0]
        EV_ADD = 3'd0,
        EV_BBO = 3'd1,
        EV_EXE = 3'd2,
        EV_CAN = 3'd3,
        EV_DEL = 3'd4,
        EV_REP = 3'd5,
        EV_GAP = 3'd6;

    typedef struct packed {
        logic [2:0]  ev_type;
        logic        side;          // ADD only
        logic [63:0] ref_a;         // ADD/DEL/EXE/CAN: order_ref; REP: orig_ref
        logic [63:0] ref_b;         // REP: new_ref (unused otherwise)
        logic [31:0] shares;        // ADD/EXE/CAN/REP
        logic [31:0] price;         // ADD/REP
        logic [31:0] bid_px;        // BBO
        logic [31:0] bid_sz;        // BBO
        logic [31:0] ask_px;        // BBO
        logic [31:0] ask_sz;        // BBO
        logic [63:0] gap_seq;       // GAP
    } event_entry_t;

    event_entry_t ev_rom [NUM_EVENTS];

    initial begin
        // 0: ADD BUY  ref=0x1001  1000 shares  price=0x0012D484
        ev_rom[0] = '{EV_ADD, 1'b1,
                      64'h0000000000001001, 64'h0,
                      32'h000003E8, 32'h0012D484,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 1: ADD SELL ref=0x1002   500 shares  price=0x0012D678
        ev_rom[1] = '{EV_ADD, 1'b0,
                      64'h0000000000001002, 64'h0,
                      32'h000001F4, 32'h0012D678,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 2: BBO bid=0x0012D484×0x3E8  ask=0x0012D678×0x1F4
        ev_rom[2] = '{EV_BBO, 1'b0,
                      64'h0, 64'h0, 32'h0, 32'h0,
                      32'h0012D484, 32'h000003E8,
                      32'h0012D678, 32'h000001F4,
                      64'h0};

        // 3: EXE ref=0x1001  500 shares
        ev_rom[3] = '{EV_EXE, 1'b0,
                      64'h0000000000001001, 64'h0,
                      32'h000001F4, 32'h0,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 4: CAN ref=0x1002  100 shares
        ev_rom[4] = '{EV_CAN, 1'b0,
                      64'h0000000000001002, 64'h0,
                      32'h00000064, 32'h0,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 5: DEL ref=0x1001
        ev_rom[5] = '{EV_DEL, 1'b0,
                      64'h0000000000001001, 64'h0,
                      32'h0, 32'h0,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 6: REP orig=0x1002  new=0x1010  200 shares  price=0x0012D8A8
        ev_rom[6] = '{EV_REP, 1'b0,
                      64'h0000000000001002, 64'h0000000000001010,
                      32'h000000C8, 32'h0012D8A8,
                      32'h0, 32'h0, 32'h0, 32'h0, 64'h0};

        // 7: GAP seq=8
        ev_rom[7] = '{EV_GAP, 1'b0,
                      64'h0, 64'h0, 32'h0, 32'h0,
                      32'h0, 32'h0, 32'h0, 32'h0,
                      64'h0000000000000008};
    end

    // -------------------------------------------------------------------------
    // uart_reporter wires
    // -------------------------------------------------------------------------
    logic        add_valid;
    logic [63:0] add_order_ref;
    logic        add_side;
    logic [31:0] add_shares, add_price;

    logic        del_valid;
    logic [63:0] del_order_ref;

    logic        rep_valid;
    logic [63:0] rep_orig_ref, rep_new_ref;
    logic [31:0] rep_shares,   rep_price;

    logic        exe_valid;
    logic [63:0] exe_order_ref;
    logic [31:0] exe_shares;

    logic        can_valid;
    logic [63:0] can_order_ref;
    logic [31:0] can_shares;

    logic        bbo_updated;
    logic [31:0] best_bid_price, best_bid_size;
    logic [31:0] best_ask_price, best_ask_size;

    logic        gap_detected;
    logic [63:0] gap_seq;

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
        .gap_detected   (gap_detected),
        .gap_seq        (gap_seq),
        .uart_tx        (uart_tx)
    );

    // -------------------------------------------------------------------------
    // Sequencer — fires one event every DELAY_CYCLES clocks
    //
    // DELAY_CYCLES must be long enough for the UART FIFO to drain between
    // events.  The longest line (REP) is 71 chars; at 115200 baud:
    //   71 × 10 bits / 115200 ≈ 6.2 ms
    // 20 ms (2,000,000 cycles) is safely above this.
    // -------------------------------------------------------------------------
    localparam int DELAY_CYCLES = 2_000_000; // 20 ms

    typedef enum logic [1:0] { S_WAIT, S_FIRE, S_DONE } seq_t;
    seq_t        seq_state;
    logic [20:0] wait_cnt;   // 2^21 = 2,097,152 > DELAY_CYCLES
    logic [3:0]  ev_idx;

    // Default all strobe signals to 0
    always_comb begin
        add_valid = 1'b0; add_order_ref = '0; add_side = 1'b0;
        add_shares = '0;  add_price = '0;

        del_valid = 1'b0; del_order_ref = '0;

        rep_valid = 1'b0; rep_orig_ref = '0; rep_new_ref = '0;
        rep_shares = '0;  rep_price = '0;

        exe_valid = 1'b0; exe_order_ref = '0; exe_shares = '0;

        can_valid = 1'b0; can_order_ref = '0; can_shares = '0;

        bbo_updated    = 1'b0;
        best_bid_price = '0; best_bid_size = '0;
        best_ask_price = '0; best_ask_size = '0;

        gap_detected = 1'b0; gap_seq = '0;

        if (seq_state == S_FIRE) begin
            case (ev_rom[ev_idx].ev_type)
                EV_ADD: begin
                    add_valid     = 1'b1;
                    add_order_ref = ev_rom[ev_idx].ref_a;
                    add_side      = ev_rom[ev_idx].side;
                    add_shares    = ev_rom[ev_idx].shares;
                    add_price     = ev_rom[ev_idx].price;
                end
                EV_BBO: begin
                    bbo_updated    = 1'b1;
                    best_bid_price = ev_rom[ev_idx].bid_px;
                    best_bid_size  = ev_rom[ev_idx].bid_sz;
                    best_ask_price = ev_rom[ev_idx].ask_px;
                    best_ask_size  = ev_rom[ev_idx].ask_sz;
                end
                EV_EXE: begin
                    exe_valid     = 1'b1;
                    exe_order_ref = ev_rom[ev_idx].ref_a;
                    exe_shares    = ev_rom[ev_idx].shares;
                end
                EV_CAN: begin
                    can_valid     = 1'b1;
                    can_order_ref = ev_rom[ev_idx].ref_a;
                    can_shares    = ev_rom[ev_idx].shares;
                end
                EV_DEL: begin
                    del_valid     = 1'b1;
                    del_order_ref = ev_rom[ev_idx].ref_a;
                end
                EV_REP: begin
                    rep_valid    = 1'b1;
                    rep_orig_ref = ev_rom[ev_idx].ref_a;
                    rep_new_ref  = ev_rom[ev_idx].ref_b;
                    rep_shares   = ev_rom[ev_idx].shares;
                    rep_price    = ev_rom[ev_idx].price;
                end
                EV_GAP: begin
                    gap_detected = 1'b1;
                    gap_seq      = ev_rom[ev_idx].gap_seq;
                end
                default: ;
            endcase
        end
    end

    // Sequencer FSM
    always_ff @(posedge sys_clk) begin
        if (!rst_n) begin
            seq_state <= S_WAIT;
            wait_cnt  <= '0;
            ev_idx    <= '0;
        end else begin
            case (seq_state)
                S_WAIT: begin
                    if (wait_cnt == DELAY_CYCLES - 1) begin
                        wait_cnt  <= '0;
                        seq_state <= S_FIRE;
                    end else begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                end

                S_FIRE: begin
                    // Strobe is combinationally asserted this cycle.
                    // Advance to next event.
                    if (ev_idx == NUM_EVENTS - 1) begin
                        seq_state <= S_DONE;
                    end else begin
                        ev_idx    <= ev_idx + 1'b1;
                        seq_state <= S_WAIT;
                        wait_cnt  <= '0;
                    end
                end

                S_DONE: begin
                    // Idle — press BTN0 to reset and repeat
                end

                default: seq_state <= S_WAIT;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Debug LEDs
    // -------------------------------------------------------------------------
    logic [26:0] hb_cnt;
    logic        ev_strobe;

    assign ev_strobe = add_valid | del_valid | rep_valid |
                       exe_valid | can_valid | bbo_updated | gap_detected;

    always_ff @(posedge sys_clk) begin
        if (!rst_n) hb_cnt <= '0;
        else        hb_cnt <= hb_cnt + 1;
    end

    assign led[0] = hb_cnt[26];                  // heartbeat ~1 Hz
    assign led[1] = ev_strobe;                    // pulses on each event
    assign led[2] = (seq_state == S_DONE);        // lit when all done
    assign led[3] = 1'b0;

endmodule
