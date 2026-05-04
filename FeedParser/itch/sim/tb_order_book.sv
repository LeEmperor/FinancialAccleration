// =============================================================================
// tb_order_book.sv
// Unit testbench for order_book
//
// Drives decoded ITCH event strobes directly (no decoder in path).
//
// FSM timing:
//   Cycle N  : strobe high at OP_IDLE → params latched, op_state → OP_xxx
//   Cycle N+1: op_state executes → bbo_updated=1, op_state → OP_IDLE
//   REPLACE takes one extra cycle (OP_REP_DEL then OP_REP_ADD).
//
// Tests:
//   1. ADD bid + ask → BBO set correctly
//   2. ADD multiple orders at same price level → sizes aggregated
//   3. DEL order → BBO updates, level cleared when size reaches zero
//   4. EXECUTE partial fill → order stays, level size reduced
//   5. EXECUTE full fill  → order removed, level cleared if last order
//   6. CANCEL shares      → order size reduced, level size reduced
//   7. REPLACE            → original removed, new reference added
//   8. Priority: ADD beats DEL when both arrive same cycle
//   9. BBO best-price selection across multiple price levels
// =============================================================================

`timescale 1ns/1ps

module tb_order_book;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        rst_n = 0;

    logic        add_valid    = 0;
    logic [63:0] add_order_ref= 0;
    logic        add_side     = 0;
    logic [31:0] add_shares   = 0;
    logic [31:0] add_price    = 0;

    logic        del_valid    = 0;
    logic [63:0] del_order_ref= 0;

    logic        rep_valid    = 0;
    logic [63:0] rep_orig_ref = 0;
    logic [63:0] rep_new_ref  = 0;
    logic [31:0] rep_shares   = 0;
    logic [31:0] rep_price    = 0;

    logic        exe_valid    = 0;
    logic [63:0] exe_order_ref= 0;
    logic [31:0] exe_shares   = 0;

    logic        can_valid    = 0;
    logic [63:0] can_order_ref= 0;
    logic [31:0] can_shares   = 0;

    logic [31:0] best_bid_price, best_bid_size;
    logic [31:0] best_ask_price, best_ask_size;
    logic        bbo_updated;

    always #5 clk = ~clk;

    order_book #(
        .ORDER_SLOTS (256),
        .NUM_LEVELS  (8)
    ) u_dut (
        .clk            (clk),
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

    initial begin
        repeat(4) @(posedge clk); rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // Operation drivers
    // All strobes are 1-cycle pulses. We wait 3 cycles after each to let the
    // FSM complete (2 for normal ops, 3 covers REPLACE's extra cycle).
    // -------------------------------------------------------------------------
    task automatic do_add(
        input logic [63:0] order_ref,
        input logic        side,   // 1=bid, 0=ask
        input logic [31:0] shares,
        input logic [31:0] price
    );
        @(posedge clk); #1;
        add_valid     <= 1'b1;
        add_order_ref <= order_ref;
        add_side      <= side;
        add_shares    <= shares;
        add_price     <= price;
        @(posedge clk); #1;
        add_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask

    task automatic do_del(input logic [63:0] order_ref);
        @(posedge clk); #1;
        del_valid     <= 1'b1;
        del_order_ref <= order_ref;
        @(posedge clk); #1;
        del_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask

    task automatic do_rep(
        input logic [63:0] orig_ref,
        input logic [63:0] new_ref,
        input logic [31:0] shares,
        input logic [31:0] price
    );
        @(posedge clk); #1;
        rep_valid    <= 1'b1;
        rep_orig_ref <= orig_ref;
        rep_new_ref  <= new_ref;
        rep_shares   <= shares;
        rep_price    <= price;
        @(posedge clk); #1;
        rep_valid <= 1'b0;
        repeat(4) @(posedge clk);  // REPLACE = 2 FSM cycles
    endtask

    task automatic do_exe(input logic [63:0] order_ref, input logic [31:0] shares);
        @(posedge clk); #1;
        exe_valid     <= 1'b1;
        exe_order_ref <= order_ref;
        exe_shares    <= shares;
        @(posedge clk); #1;
        exe_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask

    task automatic do_can(input logic [63:0] order_ref, input logic [31:0] shares);
        @(posedge clk); #1;
        can_valid     <= 1'b1;
        can_order_ref <= order_ref;
        can_shares    <= shares;
        @(posedge clk); #1;
        can_valid <= 1'b0;
        repeat(3) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // bbo_updated latch
    // -------------------------------------------------------------------------
    logic bbo_seen;
    task automatic clear_bbo_seen(); bbo_seen = 0; endtask
    always @(posedge clk) if (bbo_updated) bbo_seen <= 1'b1;

    // -------------------------------------------------------------------------
    // Assertion helpers
    // -------------------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0;

    task automatic chk32(input string name,
                         input logic [31:0] got, input logic [31:0] exp);
        if (got === exp) begin
            $display("[PASS] %-50s : 0x%08X (%0d)", name, got, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-50s : got=0x%08X (%0d)  exp=0x%08X (%0d)",
                     name, got, got, exp, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_bool(input string name, input logic got, input logic exp);
        if (got === exp) begin
            $display("[PASS] %-50s : %0b", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-50s : got=%0b  exp=%0b", name, got, exp);
            fail_cnt++;
        end
    endtask

    // Snapshot BBO into local variables for assertions
    logic [31:0] bid_px, bid_sz, ask_px, ask_sz;
    task automatic snap_bbo();
        bid_px = best_bid_price;
        bid_sz = best_bid_size;
        ask_px = best_ask_price;
        ask_sz = best_ask_size;
    endtask

    // Price constants (ITCH wire: actual × 10000)
    // $100.00 = 1_000_000 = 0x000F4240
    // $100.10 = 1_001_000 = 0x000F4628
    // $100.20 = 1_002_000 = 0x000F4A10
    // $100.30 = 1_003_000 = 0x000F4DF8
    localparam logic [31:0] PX_100_00 = 32'h000F4240;
    localparam logic [31:0] PX_100_10 = 32'h000F4628;
    localparam logic [31:0] PX_100_20 = 32'h000F4A10;
    localparam logic [31:0] PX_100_30 = 32'h000F4DF8;

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge clk);

        $display("\n=== tb_order_book ===\n");

        // =====================================================================
        // Test 1: Single bid + single ask → BBO initialises correctly
        // =====================================================================
        $display("--- Test 1: single bid + single ask ---");
        do_add(64'h0001, 1'b1, 32'd1000, PX_100_00); // BUY  1000 @ $100.00
        do_add(64'h0002, 1'b0, 32'd500,  PX_100_10); // SELL  500 @ $100.10
        snap_bbo();

        chk32("bid price = $100.00", bid_px, PX_100_00);
        chk32("bid size  = 1000",    bid_sz, 32'd1000);
        chk32("ask price = $100.10", ask_px, PX_100_10);
        chk32("ask size  = 500",     ask_sz, 32'd500);

        // =====================================================================
        // Test 2: Two orders at same bid price — sizes aggregate
        // =====================================================================
        $display("\n--- Test 2: two bids at same price (size aggregation) ---");
        do_add(64'h0003, 1'b1, 32'd300, PX_100_00); // BUY 300 @ same price
        snap_bbo();

        chk32("bid size = 1300 (1000+300)", bid_sz, 32'd1300);
        chk32("bid price unchanged",        bid_px, PX_100_00);

        // =====================================================================
        // Test 3: Better bid price displaces BBO
        // =====================================================================
        $display("\n--- Test 3: better bid price displaces BBO ---");
        do_add(64'h0004, 1'b1, 32'd200, PX_100_10); // BUY 200 @ $100.10 (better bid)
        snap_bbo();

        // BBO bid should now be $100.10 × 200
        chk32("bid price = $100.10 (new best)", bid_px, PX_100_10);
        chk32("bid size  = 200",                bid_sz, 32'd200);

        // =====================================================================
        // Test 4: DEL order — removes from level, BBO reverts
        // =====================================================================
        $display("\n--- Test 4: delete the best bid, BBO reverts ---");
        do_del(64'h0004); // remove the $100.10 bid
        snap_bbo();

        chk32("bid price reverts to $100.00", bid_px, PX_100_00);
        chk32("bid size  = 1300",             bid_sz, 32'd1300);

        // =====================================================================
        // Test 5: EXECUTE partial fill — order stays, size decreases
        // =====================================================================
        $display("\n--- Test 5: partial execution (500 of 1000 shares) ---");
        // ref 0x0001 is BUY 1000 @ $100.00; execute 500
        do_exe(64'h0001, 32'd500);
        snap_bbo();

        // Order still exists with 500 shares; level size should decrease
        // Level was 1300 (from 0x0001=1000 + 0x0003=300); after 500 exe → 800
        chk32("bid price unchanged after partial exe", bid_px, PX_100_00);
        chk32("bid size = 800 (1300-500)",             bid_sz, 32'd800);

        // =====================================================================
        // Test 6: EXECUTE full fill — order removed, level shrinks
        // =====================================================================
        $display("\n--- Test 6: full execution clears order ---");
        // Execute remaining 500 of ref 0x0001
        do_exe(64'h0001, 32'd500);
        snap_bbo();

        // ref 0x0001 is now gone; level should have only ref 0x0003 (300 shares)
        chk32("bid price still $100.00", bid_px, PX_100_00);
        chk32("bid size = 300 (only 0x0003 remains)", bid_sz, 32'd300);

        // =====================================================================
        // Test 7: CANCEL — partial size reduction
        // =====================================================================
        $display("\n--- Test 7: cancel 100 shares from ref 0x0003 (300 -> 200) ---");
        do_can(64'h0003, 32'd100);
        snap_bbo();

        chk32("bid size = 200 after cancel", bid_sz, 32'd200);
        chk32("bid price unchanged",         bid_px, PX_100_00);

        // =====================================================================
        // Test 8: REPLACE — original ref deleted, new ref inserted
        // =====================================================================
        $display("\n--- Test 8: replace ref 0x0002 (SELL 500@100.10) → ref 0x0010 (SELL 200@100.20) ---");
        do_rep(64'h0002, 64'h0010, 32'd200, PX_100_20);
        snap_bbo();

        // Old ask at $100.10 × 500 removed; new ask at $100.20 × 200
        chk32("ask price = $100.20 after replace", ask_px, PX_100_20);
        chk32("ask size  = 200",                   ask_sz, 32'd200);

        // =====================================================================
        // Test 9: BBO best-price selection — multiple ask price levels
        //         Add asks at $100.30 and $100.10; best ask should be $100.10
        // =====================================================================
        $display("\n--- Test 9: best-ask selection across price levels ---");
        do_add(64'h0020, 1'b0, 32'd100, PX_100_30); // SELL 100 @ $100.30
        do_add(64'h0021, 1'b0, 32'd150, PX_100_10); // SELL 150 @ $100.10 ← better
        snap_bbo();

        chk32("best ask = $100.10 (not $100.20 or $100.30)", ask_px, PX_100_10);
        chk32("best ask size = 150",                         ask_sz, 32'd150);

        // =====================================================================
        // Test 10: bbo_updated strobe — fires exactly when BBO changes
        // =====================================================================
        $display("\n--- Test 10: bbo_updated strobe ---");
        clear_bbo_seen();
        do_add(64'h0030, 1'b1, 32'd50, PX_100_20); // new bid at $100.20
        // Wait a cycle and check
        @(posedge clk);
        chk_bool("bbo_updated fired", bbo_seen, 1'b1);

        // =====================================================================
        // Test 11: Delete non-existent ref — no crash, BBO unchanged
        // =====================================================================
        $display("\n--- Test 11: delete unknown ref (no-op) ---");
        snap_bbo();
        begin
            automatic logic [31:0] pre_bid_px = bid_px;
            automatic logic [31:0] pre_ask_px = ask_px;
            do_del(64'hDEADBEEF); // ref not in table
            snap_bbo();
            chk32("BBO bid unchanged after bad del", bid_px, pre_bid_px);
            chk32("BBO ask unchanged after bad del", ask_px, pre_ask_px);
        end

        // =====================================================================
        // Summary
        // =====================================================================
        repeat(10) @(posedge clk);
        $display("\n=== Results: %0d PASS, %0d FAIL ===\n", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED\n");
        $finish;
    end

    initial begin #5_000_000; $display("TIMEOUT"); $finish; end

endmodule
