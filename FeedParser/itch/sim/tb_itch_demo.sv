// =============================================================================
// tb_itch_demo.sv
// Simulation testbench for the ITCH demo pipeline
//
// Drives byte-serial input simulating:
//   Packet 1: MoldUDP64 with 3 messages
//     MSG 1: Add Order (A) — BUY  1000 @ $123.45 ref=0x1001
//     MSG 2: Add Order (A) — SELL  500 @ $123.50 ref=0x1002
//     MSG 3: Add Order (A) — BUY   300 @ $123.44 ref=0x1003
//
//   Packet 2: SeqNum=4
//     MSG 1: Order Execute (E) — ref=0x1001, 500 shares
//     MSG 2: Order Cancel  (X) — ref=0x1003, 100 shares
//
//   Packet 3: SeqNum=6
//     MSG 1: Order Replace (U) — orig=0x1002, new=0x1010, 200 @ $123.55
//     MSG 2: Order Delete  (D) — ref=0x1001
//
//   Packet 4: SeqNum=9  (GAP — expected 8, received 9)
//     MSG 1: Add Order (A) — SELL 100 @ $123.48 ref=0x2001
//
// After each packet we check the BBO output.
// =============================================================================

`timescale 1ns/1ps

module tb_itch_demo;

    // -------------------------------------------------------------------------
    // Clock & reset
    // -------------------------------------------------------------------------
    logic clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic [7:0]  in_data;
    logic        in_valid, in_sof;

    // MoldUDP64 → decoder
    logic [7:0]  itch_byte;
    logic        itch_valid, itch_msg_start;
    logic        gap_det;
    logic [63:0] gap_seq;

    // Decoder outputs
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

    // Book outputs
    logic [31:0] best_bid_price, best_bid_size;
    logic [31:0] best_ask_price, best_ask_size;
    logic        bbo_updated;

    // UART
    logic        uart_tx;

    // Sticky latch for gap_det (1-cycle strobe — must be captured before check)
    logic        gap_latch = 0;

    // -------------------------------------------------------------------------
    // Instantiate pipeline
    // -------------------------------------------------------------------------
    moldudp64_parser u_mold (
        .clk          (clk),
        .rst_n        (rst_n),
        .in_data      (in_data),
        .in_valid     (in_valid),
        .in_sof       (in_sof),
        .out_data     (itch_byte),
        .out_valid    (itch_valid),
        .out_msg_start(itch_msg_start),
        .gap_detected (gap_det),
        .seq_num      (gap_seq)
    );

    itch_decoder u_dec (
        .clk           (clk),
        .rst_n         (rst_n),
        .in_data       (itch_byte),
        .in_valid      (itch_valid),
        .in_msg_start  (itch_msg_start),
        .add_valid     (add_valid),
        .add_stock_locate(add_stock_locate),
        .add_timestamp (add_timestamp),
        .add_order_ref (add_order_ref),
        .add_side      (add_side),
        .add_shares    (add_shares),
        .add_stock     (add_stock),
        .add_price     (add_price),
        .del_valid     (del_valid),
        .del_order_ref (del_order_ref),
        .del_timestamp (del_timestamp),
        .rep_valid     (rep_valid),
        .rep_orig_ref  (rep_orig_ref),
        .rep_new_ref   (rep_new_ref),
        .rep_shares    (rep_shares),
        .rep_price     (rep_price),
        .rep_timestamp (rep_timestamp),
        .exe_valid     (exe_valid),
        .exe_order_ref (exe_order_ref),
        .exe_shares    (exe_shares),
        .exe_timestamp (exe_timestamp),
        .can_valid     (can_valid),
        .can_order_ref (can_order_ref),
        .can_shares    (can_shares),
        .can_timestamp (can_timestamp)
    );

    order_book #(.ORDER_SLOTS(256), .NUM_LEVELS(8)) u_book (
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

    uart_reporter #(.CLK_HZ(100_000_000), .BAUD(115_200)) u_uart (
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
    // Packet helper tasks
    // -------------------------------------------------------------------------

    // Drive one byte into the pipeline
    task automatic drive_byte(input logic [7:0] b, input logic sof=1'b0);
        @(posedge clk);
        in_data  <= b;
        in_valid <= 1'b1;
        in_sof   <= sof;
        @(posedge clk);
        in_valid <= 1'b0;
        in_sof   <= 1'b0;
        // Inter-byte gap (simulates 10 clk cycles per byte at 100Mb/100MHz)
        repeat(8) @(posedge clk);
    endtask

    // Drive a MoldUDP64 packet
    // bytes[] = raw UDP payload (everything after UDP header)
    task automatic drive_packet(input logic [7:0] payload [], input int plen);
        drive_byte(payload[0], 1'b1);  // SOF on first byte
        for (int i = 1; i < plen; i++)
            drive_byte(payload[i]);
        repeat(20) @(posedge clk);
    endtask

    // Build MoldUDP64 header bytes
    function automatic void build_mold_hdr(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [63:0] seqnum,
        input logic [15:0] msg_count
    );
        // Session ID (10 bytes) = "DEMOSESS01"
        msg[offset+0]  = 8'h44; msg[offset+1]  = 8'h45; msg[offset+2]  = 8'h4D;
        msg[offset+3]  = 8'h4F; msg[offset+4]  = 8'h53; msg[offset+5]  = 8'h45;
        msg[offset+6]  = 8'h53; msg[offset+7]  = 8'h53; msg[offset+8]  = 8'h30;
        msg[offset+9]  = 8'h31;
        // Sequence number (8 bytes, big-endian)
        msg[offset+10] = seqnum[63:56]; msg[offset+11] = seqnum[55:48];
        msg[offset+12] = seqnum[47:40]; msg[offset+13] = seqnum[39:32];
        msg[offset+14] = seqnum[31:24]; msg[offset+15] = seqnum[23:16];
        msg[offset+16] = seqnum[15:8];  msg[offset+17] = seqnum[7:0];
        // Message count (2 bytes)
        msg[offset+18] = msg_count[15:8];
        msg[offset+19] = msg_count[7:0];
    endfunction

    // Build Add Order (A) message block (2-byte length + 36-byte body)
    // price is wire format (actual * 10000)
    function automatic void build_add(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [15:0] locate,
        input logic [63:0] order_ref,
        input logic        side,       // 1=buy
        input logic [31:0] shares,
        input logic [63:0] stock,      // 8-char ASCII packed big-endian
        input logic [31:0] price
    );
        // Length = 36
        msg[offset+0] = 8'h00; msg[offset+1] = 8'h24;
        // Type = 'A'
        msg[offset+2] = 8'h41;
        // Stock locate
        msg[offset+3] = locate[15:8]; msg[offset+4] = locate[7:0];
        // Tracking number = 0
        msg[offset+5] = 8'h00; msg[offset+6] = 8'h00;
        // Timestamp (6 bytes) = 09:30:00.000000000 = 34200000000000 ns
        // = 0x001F1B5B00000 → just use 0 for demo
        msg[offset+7]  = 8'h00; msg[offset+8]  = 8'h00; msg[offset+9]  = 8'h1F;
        msg[offset+10] = 8'h1B; msg[offset+11] = 8'h5B; msg[offset+12] = 8'h00;
        // Order ref (8 bytes)
        msg[offset+13] = order_ref[63:56]; msg[offset+14] = order_ref[55:48];
        msg[offset+15] = order_ref[47:40]; msg[offset+16] = order_ref[39:32];
        msg[offset+17] = order_ref[31:24]; msg[offset+18] = order_ref[23:16];
        msg[offset+19] = order_ref[15:8];  msg[offset+20] = order_ref[7:0];
        // Side
        msg[offset+21] = side ? 8'h42 : 8'h53; // 'B' or 'S'
        // Shares
        msg[offset+22] = shares[31:24]; msg[offset+23] = shares[23:16];
        msg[offset+24] = shares[15:8];  msg[offset+25] = shares[7:0];
        // Stock (8 bytes)
        msg[offset+26] = stock[63:56]; msg[offset+27] = stock[55:48];
        msg[offset+28] = stock[47:40]; msg[offset+29] = stock[39:32];
        msg[offset+30] = stock[31:24]; msg[offset+31] = stock[23:16];
        msg[offset+32] = stock[15:8];  msg[offset+33] = stock[7:0];
        // Price
        msg[offset+34] = price[31:24]; msg[offset+35] = price[23:16];
        msg[offset+36] = price[15:8];  msg[offset+37] = price[7:0];
    endfunction

    // Build Delete message (D) block = 2 + 19 = 21 bytes
    function automatic void build_del(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [63:0] order_ref
    );
        msg[offset+0] = 8'h00; msg[offset+1] = 8'h13; // length=19
        msg[offset+2] = 8'h44; // 'D'
        msg[offset+3] = 8'h00; msg[offset+4] = 8'h01; // locate
        msg[offset+5] = 8'h00; msg[offset+6] = 8'h00; // tracking
        // timestamp
        msg[offset+7]  = 8'h00; msg[offset+8]  = 8'h00; msg[offset+9]  = 8'h1F;
        msg[offset+10] = 8'h1B; msg[offset+11] = 8'h5B; msg[offset+12] = 8'h01;
        // order ref
        msg[offset+13] = order_ref[63:56]; msg[offset+14] = order_ref[55:48];
        msg[offset+15] = order_ref[47:40]; msg[offset+16] = order_ref[39:32];
        msg[offset+17] = order_ref[31:24]; msg[offset+18] = order_ref[23:16];
        msg[offset+19] = order_ref[15:8];  msg[offset+20] = order_ref[7:0];
    endfunction

    // Build Execute message (E) block = 2 + 31 = 33 bytes
    function automatic void build_exe(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [63:0] order_ref,
        input logic [31:0] exec_shares
    );
        msg[offset+0] = 8'h00; msg[offset+1] = 8'h1F; // length=31
        msg[offset+2] = 8'h45; // 'E'
        msg[offset+3] = 8'h00; msg[offset+4] = 8'h01;
        msg[offset+5] = 8'h00; msg[offset+6] = 8'h00;
        msg[offset+7]  = 8'h00; msg[offset+8]  = 8'h00; msg[offset+9]  = 8'h1F;
        msg[offset+10] = 8'h1B; msg[offset+11] = 8'h5B; msg[offset+12] = 8'h02;
        // order ref
        msg[offset+13] = order_ref[63:56]; msg[offset+14] = order_ref[55:48];
        msg[offset+15] = order_ref[47:40]; msg[offset+16] = order_ref[39:32];
        msg[offset+17] = order_ref[31:24]; msg[offset+18] = order_ref[23:16];
        msg[offset+19] = order_ref[15:8];  msg[offset+20] = order_ref[7:0];
        // executed shares
        msg[offset+21] = exec_shares[31:24]; msg[offset+22] = exec_shares[23:16];
        msg[offset+23] = exec_shares[15:8];  msg[offset+24] = exec_shares[7:0];
        // match number (8 bytes, zeroed)
        for (int i = 25; i <= 32; i++) msg[offset+i] = 8'h00;
    endfunction

    // Build Cancel message (X) block = 2 + 23 = 25 bytes
    function automatic void build_can(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [63:0] order_ref,
        input logic [31:0] cancel_shares
    );
        msg[offset+0] = 8'h00; msg[offset+1] = 8'h17; // length=23
        msg[offset+2] = 8'h58; // 'X'
        msg[offset+3] = 8'h00; msg[offset+4] = 8'h01;
        msg[offset+5] = 8'h00; msg[offset+6] = 8'h00;
        msg[offset+7]  = 8'h00; msg[offset+8]  = 8'h00; msg[offset+9]  = 8'h1F;
        msg[offset+10] = 8'h1B; msg[offset+11] = 8'h5B; msg[offset+12] = 8'h03;
        msg[offset+13] = order_ref[63:56]; msg[offset+14] = order_ref[55:48];
        msg[offset+15] = order_ref[47:40]; msg[offset+16] = order_ref[39:32];
        msg[offset+17] = order_ref[31:24]; msg[offset+18] = order_ref[23:16];
        msg[offset+19] = order_ref[15:8];  msg[offset+20] = order_ref[7:0];
        msg[offset+21] = cancel_shares[31:24]; msg[offset+22] = cancel_shares[23:16];
        msg[offset+23] = cancel_shares[15:8];  msg[offset+24] = cancel_shares[7:0];
    endfunction

    // Build Replace message (U) block = 2 + 35 = 37 bytes
    function automatic void build_rep(
        ref   logic [7:0] msg [],
        input int         offset,
        input logic [63:0] orig_ref,
        input logic [63:0] new_ref,
        input logic [31:0] shares,
        input logic [31:0] price
    );
        msg[offset+0] = 8'h00; msg[offset+1] = 8'h23; // length=35
        msg[offset+2] = 8'h55; // 'U'
        msg[offset+3] = 8'h00; msg[offset+4] = 8'h01;
        msg[offset+5] = 8'h00; msg[offset+6] = 8'h00;
        msg[offset+7]  = 8'h00; msg[offset+8]  = 8'h00; msg[offset+9]  = 8'h1F;
        msg[offset+10] = 8'h1B; msg[offset+11] = 8'h5B; msg[offset+12] = 8'h04;
        // orig ref
        msg[offset+13] = orig_ref[63:56]; msg[offset+14] = orig_ref[55:48];
        msg[offset+15] = orig_ref[47:40]; msg[offset+16] = orig_ref[39:32];
        msg[offset+17] = orig_ref[31:24]; msg[offset+18] = orig_ref[23:16];
        msg[offset+19] = orig_ref[15:8];  msg[offset+20] = orig_ref[7:0];
        // new ref
        msg[offset+21] = new_ref[63:56];  msg[offset+22] = new_ref[55:48];
        msg[offset+23] = new_ref[47:40];  msg[offset+24] = new_ref[39:32];
        msg[offset+25] = new_ref[31:24];  msg[offset+26] = new_ref[23:16];
        msg[offset+27] = new_ref[15:8];   msg[offset+28] = new_ref[7:0];
        // shares
        msg[offset+29] = shares[31:24]; msg[offset+30] = shares[23:16];
        msg[offset+31] = shares[15:8];  msg[offset+32] = shares[7:0];
        // price
        msg[offset+33] = price[31:24]; msg[offset+34] = price[23:16];
        msg[offset+35] = price[15:8];  msg[offset+36] = price[7:0];
    endfunction

    // -------------------------------------------------------------------------
    // Assertion helper
    // -------------------------------------------------------------------------
    int pass_count, fail_count;

    task automatic check(
        input string  name,
        input logic [63:0] got,
        input logic [63:0] expected
    );
        if (got === expected) begin
            $display("[PASS] %s = 0x%016X", name, got);
            pass_count++;
        end else begin
            $display("[FAIL] %s: got=0x%016X expected=0x%016X", name, got, expected);
            fail_count++;
        end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        in_data  = 8'h00;
        in_valid = 1'b0;
        in_sof   = 1'b0;
        pass_count = 0;
        fail_count = 0;

        // Wait for reset
        @(posedge rst_n);
        repeat(5) @(posedge clk);

        $display("\n=== ITCH Demo Testbench ===\n");

        // =====================================================================
        // PACKET 1: SeqNum=1, 3 Add Orders
        //   ref=0x1001 BUY  1000 @ 123.45 → wire price = 1234500 = 0x0012D484
        //   ref=0x1002 SELL  500 @ 123.50 → wire price = 1235000 = 0x0012D678
        //   ref=0x1003 BUY   300 @ 123.44 → wire price = 1234400 = 0x0012D420
        // Expected BBO after: BID=0x0012D484 x 1000, ASK=0x0012D678 x 500
        // =====================================================================
        begin
            automatic logic [7:0] pkt1[] = new[20 + 38 + 38 + 38];
            build_mold_hdr(pkt1, 0, 64'd1, 16'd3);
            // AAPL space-padded: "AAPL    " = 0x4141504C20202020
            build_add(pkt1, 20, 16'h0001, 64'h0000000000001001,
                      1'b1, 32'd1000, 64'h4141504C20202020, 32'h0012D484);
            build_add(pkt1, 58, 16'h0001, 64'h0000000000001002,
                      1'b0, 32'd500,  64'h4141504C20202020, 32'h0012D678);
            build_add(pkt1, 96, 16'h0001, 64'h0000000000001003,
                      1'b1, 32'd300,  64'h4141504C20202020, 32'h0012D420);
            drive_packet(pkt1, $size(pkt1));
        end

        // Wait for book to settle
        repeat(50) @(posedge clk);
        $display("\n--- After Packet 1 (3 Adds) ---");
        check("best_bid_price", {32'h0, best_bid_price}, {32'h0, 32'h0012D484});
        check("best_bid_size",  {32'h0, best_bid_size},  {32'h0, 32'd1000});
        check("best_ask_price", {32'h0, best_ask_price}, {32'h0, 32'h0012D678});
        check("best_ask_size",  {32'h0, best_ask_size},  {32'h0, 32'd500});

        // =====================================================================
        // PACKET 2: SeqNum=4, Execute + Cancel
        //   Execute ref=0x1001 500 shares → leaves 500 @ 0x0012D484
        //   Cancel  ref=0x1003 100 shares → leaves 200 @ 0x0012D420
        // Expected BBO: BID px same, size 500
        // =====================================================================
        begin
            automatic logic [7:0] pkt2[] = new[20 + 33 + 25];
            build_mold_hdr(pkt2, 0, 64'd4, 16'd2);
            build_exe(pkt2, 20, 64'h0000000000001001, 32'd500);
            build_can(pkt2, 53, 64'h0000000000001003, 32'd100);
            drive_packet(pkt2, $size(pkt2));
        end

        repeat(50) @(posedge clk);
        $display("\n--- After Packet 2 (Exe + Can) ---");
        check("best_bid_price", {32'h0, best_bid_price}, {32'h0, 32'h0012D484});
        check("best_bid_size",  {32'h0, best_bid_size},  {32'h0, 32'd500});

        // =====================================================================
        // PACKET 3: SeqNum=6, Replace + Delete
        //   Replace ref=0x1002 → new_ref=0x1010, 200 @ 123.55=0x0012D8A8
        //   Delete  ref=0x1001 (was 500 remaining)
        // Expected BBO: BID unchanged (0x1003 still there), ASK new price
        // =====================================================================
        begin
            automatic logic [7:0] pkt3[] = new[20 + 37 + 21];
            build_mold_hdr(pkt3, 0, 64'd6, 16'd2);
            build_rep(pkt3, 20,
                      64'h0000000000001002, 64'h0000000000001010,
                      32'd200, 32'h0012D8A8);
            build_del(pkt3, 57, 64'h0000000000001001);
            drive_packet(pkt3, $size(pkt3));
        end

        repeat(50) @(posedge clk);
        $display("\n--- After Packet 3 (Rep + Del) ---");
        check("best_bid_price", {32'h0, best_bid_price}, {32'h0, 32'h0012D420});
        check("best_ask_price", {32'h0, best_ask_price}, {32'h0, 32'h0012D8A8});
        check("best_ask_size",  {32'h0, best_ask_size},  {32'h0, 32'd200});

        // =====================================================================
        // PACKET 4: SeqNum=9 — GAP (expected 8)
        // =====================================================================
        gap_latch = 1'b0;  // clear sticky latch before the packet
        begin
            automatic logic [7:0] pkt4[] = new[20 + 38];
            build_mold_hdr(pkt4, 0, 64'd9, 16'd1);
            build_add(pkt4, 20, 16'h0001, 64'h0000000000002001,
                      1'b0, 32'd100, 64'h4141504C20202020, 32'h0012D520);
            drive_packet(pkt4, $size(pkt4));
        end

        repeat(30) @(posedge clk);
        $display("\n--- After Packet 4 (Gap test) ---");
        if (gap_latch) begin
            $display("[PASS] gap_detected asserted correctly");
            pass_count++;
        end else begin
            $display("[FAIL] gap_detected not asserted");
            fail_count++;
        end

        // =====================================================================
        // Summary
        // =====================================================================
        repeat(100) @(posedge clk);
        $display("\n=== Results: %0d PASS, %0d FAIL ===\n", pass_count, fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED\n");
        else
            $display("SOME TESTS FAILED\n");

        $finish;
    end

    always @(posedge clk) if (gap_det) gap_latch <= 1'b1;

    // -------------------------------------------------------------------------
    // Monitor: print all decoded events
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (add_valid)
            $display("[%0t] ADD  ref=%016X side=%s sz=%0d px=%0d",
                $time, add_order_ref, add_side?"BUY":"SELL", add_shares, add_price);
        if (del_valid)
            $display("[%0t] DEL  ref=%016X", $time, del_order_ref);
        if (rep_valid)
            $display("[%0t] REP  orig=%016X new=%016X sz=%0d px=%0d",
                $time, rep_orig_ref, rep_new_ref, rep_shares, rep_price);
        if (exe_valid)
            $display("[%0t] EXE  ref=%016X sz=%0d", $time, exe_order_ref, exe_shares);
        if (can_valid)
            $display("[%0t] CAN  ref=%016X sz=%0d", $time, can_order_ref, can_shares);
        if (bbo_updated)
            $display("[%0t] BBO  bid=%0d x %0d  ask=%0d x %0d",
                $time, best_bid_price, best_bid_size, best_ask_price, best_ask_size);
        if (gap_det)
            $display("[%0t] GAP  seq=%0d", $time, gap_seq);
    end

    // Timeout
    initial begin
        #50_000_000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
