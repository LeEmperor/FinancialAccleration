// =============================================================================
// tb_itch_decoder.sv
// Unit testbench for itch_decoder
//
// Injects byte-serial ITCH messages directly (bypassing moldudp64_parser).
// Each message is sent one byte at a time with in_msg_start on the type byte.
//
// Tests:
//   A  — Add Order       : all fields decoded, valid fires on last byte
//   F  — Add Order+MPID  : same fields as A, MPID bytes silently discarded
//   D  — Delete Order    : order_ref + timestamp
//   U  — Order Replace   : orig_ref, new_ref, shares, price
//   E  — Order Executed  : order_ref, shares; match number ignored
//   X  — Order Cancel    : order_ref, shares
//   ?  — Unknown type    : no valid fires, byte_idx resets on next msg_start
//   Back-to-back messages: valid from previous message cleared before next
//
// Message byte layout (all big-endian, 0-indexed from type byte):
//   [0]      type          (1B)
//   [1:2]    stock_locate  (2B)
//   [3:4]    tracking_num  (2B, ignored)
//   [5:10]   timestamp     (6B)
//   [11..]   message-specific (see itch_decoder.sv comments)
// =============================================================================

`timescale 1ns/1ps

module tb_itch_decoder;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        rst_n = 0;
    logic [7:0]  in_data     = 0;
    logic        in_valid    = 0;
    logic        in_msg_start= 0;

    logic        add_valid;
    logic [15:0] add_stock_locate;
    logic [47:0] add_timestamp;
    logic [63:0] add_order_ref;
    logic        add_side;
    logic [31:0] add_shares;
    logic [63:0] add_stock;
    logic [31:0] add_price;

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

    always #5 clk = ~clk;

    itch_decoder u_dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .in_data        (in_data),
        .in_valid       (in_valid),
        .in_msg_start   (in_msg_start),
        .add_valid      (add_valid),
        .add_stock_locate(add_stock_locate),
        .add_timestamp  (add_timestamp),
        .add_order_ref  (add_order_ref),
        .add_side       (add_side),
        .add_shares     (add_shares),
        .add_stock      (add_stock),
        .add_price      (add_price),
        .del_valid      (del_valid),
        .del_order_ref  (del_order_ref),
        .del_timestamp  (del_timestamp),
        .rep_valid      (rep_valid),
        .rep_orig_ref   (rep_orig_ref),
        .rep_new_ref    (rep_new_ref),
        .rep_shares     (rep_shares),
        .rep_price      (rep_price),
        .rep_timestamp  (rep_timestamp),
        .exe_valid      (exe_valid),
        .exe_order_ref  (exe_order_ref),
        .exe_shares     (exe_shares),
        .exe_timestamp  (exe_timestamp),
        .can_valid      (can_valid),
        .can_order_ref  (can_order_ref),
        .can_shares     (can_shares),
        .can_timestamp  (can_timestamp)
    );

    initial begin
        repeat(4) @(posedge clk); rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // Byte driver — 1-cycle valid pulse, optional msg_start, 2-cycle gap
    // -------------------------------------------------------------------------
    task automatic drive_byte(input logic [7:0] b, input logic start = 1'b0);
        @(posedge clk); #1;
        in_data      <= b;
        in_valid     <= 1'b1;
        in_msg_start <= start;
        @(posedge clk); #1;
        in_valid     <= 1'b0;
        in_msg_start <= 1'b0;
        repeat(2) @(posedge clk);
    endtask

    // Drive a complete ITCH message.
    // bytes[0] is the type byte (in_msg_start=1), rest follow normally.
    task automatic drive_msg(input logic [7:0] bytes[], input int len);
        drive_byte(bytes[0], 1'b1); // type byte with msg_start
        for (int i = 1; i < len; i++)
            drive_byte(bytes[i]);
    endtask

    // -------------------------------------------------------------------------
    // Build full ITCH messages
    // Header bytes [1..10] are inlined in each task to avoid the dynamic-array
    // ref mismatch that arises when passing a fixed array to msg[].
    //
    // build_add uses msg[40] so it works for both A (36 bytes) and
    // F/Add-with-MPID (40 bytes) callers; only bytes 0..35 are written here.
    // -------------------------------------------------------------------------

    // `hdr` macro-style task — inline equivalent, called nowhere externally.
    // Inlined directly below instead.

    // Add Order (A/F) — caller declares msg[40]; bytes 0..35 written here.
    // [11:18]=order_ref  [19]=side  [20:23]=shares  [24:31]=stock  [32:35]=price
    task automatic build_add(
        ref   logic [7:0] msg[40],
        input logic [15:0] locate,
        input logic [47:0] ts,
        input logic [63:0] order_ref,
        input logic        side,
        input logic [31:0] shares,
        input logic [63:0] stock,
        input logic [31:0] price
    );
        msg[0]  = 8'h41; // type 'A' (caller overwrites to 'F' if needed)
        // stock_locate [1:2]
        msg[1]  = locate[15:8]; msg[2]  = locate[7:0];
        // tracking_num [3:4] = 0
        msg[3]  = 8'h00;        msg[4]  = 8'h00;
        // timestamp [5:10]
        msg[5]  = ts[47:40]; msg[6]  = ts[39:32]; msg[7]  = ts[31:24];
        msg[8]  = ts[23:16]; msg[9]  = ts[15:8];  msg[10] = ts[7:0];
        // order_ref [11:18]
        msg[11] = order_ref[63:56]; msg[12] = order_ref[55:48];
        msg[13] = order_ref[47:40]; msg[14] = order_ref[39:32];
        msg[15] = order_ref[31:24]; msg[16] = order_ref[23:16];
        msg[17] = order_ref[15:8];  msg[18] = order_ref[7:0];
        // side [19]
        msg[19] = side ? 8'h42 : 8'h53; // 'B' or 'S'
        // shares [20:23]
        msg[20] = shares[31:24]; msg[21] = shares[23:16];
        msg[22] = shares[15:8];  msg[23] = shares[7:0];
        // stock [24:31]
        msg[24] = stock[63:56]; msg[25] = stock[55:48];
        msg[26] = stock[47:40]; msg[27] = stock[39:32];
        msg[28] = stock[31:24]; msg[29] = stock[23:16];
        msg[30] = stock[15:8];  msg[31] = stock[7:0];
        // price [32:35]
        msg[32] = price[31:24]; msg[33] = price[23:16];
        msg[34] = price[15:8];  msg[35] = price[7:0];
        // bytes [36:39] left for caller (MPID for 'F', unused for 'A')
    endtask

    // Delete Order (D) = 19 bytes
    // [11:18]=order_ref
    task automatic build_del(
        ref   logic [7:0] msg[19],
        input logic [15:0] locate,
        input logic [47:0] ts,
        input logic [63:0] order_ref
    );
        msg[0]  = 8'h44; // 'D'
        msg[1]  = locate[15:8]; msg[2]  = locate[7:0];
        msg[3]  = 8'h00;        msg[4]  = 8'h00;
        msg[5]  = ts[47:40]; msg[6]  = ts[39:32]; msg[7]  = ts[31:24];
        msg[8]  = ts[23:16]; msg[9]  = ts[15:8];  msg[10] = ts[7:0];
        msg[11] = order_ref[63:56]; msg[12] = order_ref[55:48];
        msg[13] = order_ref[47:40]; msg[14] = order_ref[39:32];
        msg[15] = order_ref[31:24]; msg[16] = order_ref[23:16];
        msg[17] = order_ref[15:8];  msg[18] = order_ref[7:0];
    endtask

    // Order Replace (U) = 35 bytes
    // [11:18]=orig_ref  [19:26]=new_ref  [27:30]=shares  [31:34]=price
    task automatic build_rep(
        ref   logic [7:0] msg[35],
        input logic [15:0] locate,
        input logic [47:0] ts,
        input logic [63:0] orig_ref,
        input logic [63:0] new_ref,
        input logic [31:0] shares,
        input logic [31:0] price
    );
        msg[0]  = 8'h55; // 'U'
        msg[1]  = locate[15:8]; msg[2]  = locate[7:0];
        msg[3]  = 8'h00;        msg[4]  = 8'h00;
        msg[5]  = ts[47:40]; msg[6]  = ts[39:32]; msg[7]  = ts[31:24];
        msg[8]  = ts[23:16]; msg[9]  = ts[15:8];  msg[10] = ts[7:0];
        msg[11] = orig_ref[63:56]; msg[12] = orig_ref[55:48];
        msg[13] = orig_ref[47:40]; msg[14] = orig_ref[39:32];
        msg[15] = orig_ref[31:24]; msg[16] = orig_ref[23:16];
        msg[17] = orig_ref[15:8];  msg[18] = orig_ref[7:0];
        msg[19] = new_ref[63:56];  msg[20] = new_ref[55:48];
        msg[21] = new_ref[47:40];  msg[22] = new_ref[39:32];
        msg[23] = new_ref[31:24];  msg[24] = new_ref[23:16];
        msg[25] = new_ref[15:8];   msg[26] = new_ref[7:0];
        msg[27] = shares[31:24]; msg[28] = shares[23:16];
        msg[29] = shares[15:8];  msg[30] = shares[7:0];
        msg[31] = price[31:24];  msg[32] = price[23:16];
        msg[33] = price[15:8];   msg[34] = price[7:0];
    endtask

    // Order Executed (E) = 31 bytes
    // [11:18]=order_ref  [19:22]=exec_shares  [23:30]=match_num (ignored)
    task automatic build_exe(
        ref   logic [7:0] msg[31],
        input logic [15:0] locate,
        input logic [47:0] ts,
        input logic [63:0] order_ref,
        input logic [31:0] exec_shares
    );
        msg[0]  = 8'h45; // 'E'
        msg[1]  = locate[15:8]; msg[2]  = locate[7:0];
        msg[3]  = 8'h00;        msg[4]  = 8'h00;
        msg[5]  = ts[47:40]; msg[6]  = ts[39:32]; msg[7]  = ts[31:24];
        msg[8]  = ts[23:16]; msg[9]  = ts[15:8];  msg[10] = ts[7:0];
        msg[11] = order_ref[63:56]; msg[12] = order_ref[55:48];
        msg[13] = order_ref[47:40]; msg[14] = order_ref[39:32];
        msg[15] = order_ref[31:24]; msg[16] = order_ref[23:16];
        msg[17] = order_ref[15:8];  msg[18] = order_ref[7:0];
        msg[19] = exec_shares[31:24]; msg[20] = exec_shares[23:16];
        msg[21] = exec_shares[15:8];  msg[22] = exec_shares[7:0];
        // match number [23:30] = 0 (ignored by decoder)
        for (int i = 23; i < 31; i++) msg[i] = 8'h00;
    endtask

    // Order Cancel (X) = 23 bytes
    // [11:18]=order_ref  [19:22]=cancelled_shares
    task automatic build_can(
        ref   logic [7:0] msg[23],
        input logic [15:0] locate,
        input logic [47:0] ts,
        input logic [63:0] order_ref,
        input logic [31:0] cancel_shares
    );
        msg[0]  = 8'h58; // 'X'
        msg[1]  = locate[15:8]; msg[2]  = locate[7:0];
        msg[3]  = 8'h00;        msg[4]  = 8'h00;
        msg[5]  = ts[47:40]; msg[6]  = ts[39:32]; msg[7]  = ts[31:24];
        msg[8]  = ts[23:16]; msg[9]  = ts[15:8];  msg[10] = ts[7:0];
        msg[11] = order_ref[63:56]; msg[12] = order_ref[55:48];
        msg[13] = order_ref[47:40]; msg[14] = order_ref[39:32];
        msg[15] = order_ref[31:24]; msg[16] = order_ref[23:16];
        msg[17] = order_ref[15:8];  msg[18] = order_ref[7:0];
        msg[19] = cancel_shares[31:24]; msg[20] = cancel_shares[23:16];
        msg[21] = cancel_shares[15:8];  msg[22] = cancel_shares[7:0];
    endtask

    // -------------------------------------------------------------------------
    // Valid-event latches (1-cycle strobes need to be caught)
    // -------------------------------------------------------------------------
    logic add_seen, del_seen, rep_seen, exe_seen, can_seen;

    task automatic clear_latches();
        add_seen = 0; del_seen = 0; rep_seen = 0;
        exe_seen = 0; can_seen = 0;
    endtask

    always @(posedge clk) begin
        if (add_valid) add_seen <= 1'b1;
        if (del_valid) del_seen <= 1'b1;
        if (rep_valid) rep_seen <= 1'b1;
        if (exe_valid) exe_seen <= 1'b1;
        if (can_valid) can_seen <= 1'b1;
    end

    // Snapshot decoded fields when valid fires
    logic [15:0] s_add_locate;
    logic [47:0] s_add_ts;
    logic [63:0] s_add_ref;
    logic        s_add_side;
    logic [31:0] s_add_shares, s_add_price;
    logic [63:0] s_add_stock;

    logic [63:0] s_del_ref; logic [47:0] s_del_ts;
    logic [63:0] s_rep_orig, s_rep_new; logic [31:0] s_rep_shares, s_rep_price; logic [47:0] s_rep_ts;
    logic [63:0] s_exe_ref; logic [31:0] s_exe_shares; logic [47:0] s_exe_ts;
    logic [63:0] s_can_ref; logic [31:0] s_can_shares; logic [47:0] s_can_ts;

    always @(posedge clk) begin
        if (add_valid) begin
            s_add_locate <= add_stock_locate; s_add_ts     <= add_timestamp;
            s_add_ref    <= add_order_ref;    s_add_side   <= add_side;
            s_add_shares <= add_shares;       s_add_price  <= add_price;
            s_add_stock  <= add_stock;
        end
        if (del_valid) begin s_del_ref <= del_order_ref; s_del_ts <= del_timestamp; end
        if (rep_valid) begin
            s_rep_orig   <= rep_orig_ref;  s_rep_new    <= rep_new_ref;
            s_rep_shares <= rep_shares;    s_rep_price  <= rep_price;
            s_rep_ts     <= rep_timestamp;
        end
        if (exe_valid) begin s_exe_ref <= exe_order_ref; s_exe_shares <= exe_shares; s_exe_ts <= exe_timestamp; end
        if (can_valid) begin s_can_ref <= can_order_ref; s_can_shares <= can_shares; s_can_ts <= can_timestamp; end
    end

    // -------------------------------------------------------------------------
    // Assertion helpers
    // -------------------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0;

    task automatic chk64(input string name,
                         input logic [63:0] got, input logic [63:0] exp);
        if (got === exp) begin
            $display("[PASS] %-45s : 0x%016X", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=0x%016X  exp=0x%016X", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk32(input string name,
                         input logic [31:0] got, input logic [31:0] exp);
        if (got === exp) begin
            $display("[PASS] %-45s : 0x%08X", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=0x%08X  exp=0x%08X", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk48(input string name,
                         input logic [47:0] got, input logic [47:0] exp);
        if (got === exp) begin
            $display("[PASS] %-45s : 0x%012X", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=0x%012X  exp=0x%012X", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_bool(input string name, input logic got, input logic exp);
        if (got === exp) begin
            $display("[PASS] %-45s : %0b", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=%0b  exp=%0b", name, got, exp);
            fail_cnt++;
        end
    endtask

    // Test values
    localparam logic [15:0] LOCATE    = 16'h0042;
    localparam logic [47:0] TIMESTAMP = 48'h001F1B5B0001;
    localparam logic [63:0] REF_A     = 64'h0000000012345678;
    localparam logic [63:0] REF_B     = 64'h00000000DEADBEEF;
    localparam logic [31:0] SHARES    = 32'h000003E8;  // 1000
    localparam logic [63:0] STOCK     = 64'h4141504C20202020; // "AAPL    "
    localparam logic [31:0] PRICE     = 32'h0012D484;  // $123.45

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge clk);

        $display("\n=== tb_itch_decoder ===\n");

        // =====================================================================
        // Test A: Add Order (A) — 36 bytes
        // =====================================================================
        $display("--- Test A: Add Order (36 bytes) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[40];
            build_add(msg, LOCATE, TIMESTAMP, REF_A, 1'b1, SHARES, STOCK, PRICE);
            drive_msg(msg, 36);
        end
        repeat(5) @(posedge clk);

        chk_bool("add_valid fired",           add_seen,      1'b1);
        chk_bool("del_valid NOT fired",       del_seen,      1'b0);
        chk64   ("add_order_ref",             s_add_ref,     REF_A);
        chk_bool("add_side = BUY",            s_add_side,    1'b1);
        chk32   ("add_shares",                s_add_shares,  SHARES);
        chk32   ("add_price",                 s_add_price,   PRICE);
        chk64   ("add_stock",                 s_add_stock,   STOCK);
        chk48   ("add_timestamp",             s_add_ts,      TIMESTAMP);

        // =====================================================================
        // Test F: Add Order with MPID (F) — 40 bytes, same fields as A
        // =====================================================================
        $display("\n--- Test F: Add Order w/ MPID (40 bytes, MPID ignored) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[40];
            // Build as Add Order then change type to 'F' and add 4 MPID bytes
            build_add(msg, LOCATE, TIMESTAMP, REF_B, 1'b0, 32'd500,
                      STOCK, 32'h0012D678);
            msg[0] = 8'h46; // 'F'
            // bytes 36-39: MPID "NSDQ" (will be silently ignored)
            msg[36] = 8'h4E; msg[37] = 8'h53; msg[38] = 8'h44; msg[39] = 8'h51;
            drive_msg(msg, 40);
        end
        repeat(5) @(posedge clk);

        chk_bool("add_valid fired for F",     add_seen,      1'b1);
        chk64   ("F: add_order_ref",          s_add_ref,     REF_B);
        chk_bool("F: add_side = SELL",        s_add_side,    1'b0);
        chk32   ("F: add_shares",             s_add_shares,  32'd500);
        chk32   ("F: add_price",              s_add_price,   32'h0012D678);

        // =====================================================================
        // Test D: Delete Order (D) — 19 bytes
        // =====================================================================
        $display("\n--- Test D: Delete Order (19 bytes) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[19];
            build_del(msg, LOCATE, TIMESTAMP, REF_A);
            drive_msg(msg, 19);
        end
        repeat(5) @(posedge clk);

        chk_bool("del_valid fired",           del_seen,      1'b1);
        chk_bool("add_valid NOT fired",       add_seen,      1'b0);
        chk64   ("del_order_ref",             s_del_ref,     REF_A);
        chk48   ("del_timestamp",             s_del_ts,      TIMESTAMP);

        // =====================================================================
        // Test U: Order Replace (U) — 35 bytes
        // =====================================================================
        $display("\n--- Test U: Order Replace (35 bytes) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[35];
            build_rep(msg, LOCATE, TIMESTAMP, REF_A, REF_B, 32'd200, 32'h0012D8A8);
            drive_msg(msg, 35);
        end
        repeat(5) @(posedge clk);

        chk_bool("rep_valid fired",           rep_seen,      1'b1);
        chk64   ("rep_orig_ref",              s_rep_orig,    REF_A);
        chk64   ("rep_new_ref",               s_rep_new,     REF_B);
        chk32   ("rep_shares",                s_rep_shares,  32'd200);
        chk32   ("rep_price",                 s_rep_price,   32'h0012D8A8);
        chk48   ("rep_timestamp",             s_rep_ts,      TIMESTAMP);

        // =====================================================================
        // Test E: Order Executed (E) — 31 bytes
        // =====================================================================
        $display("\n--- Test E: Order Executed (31 bytes) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[31];
            build_exe(msg, LOCATE, TIMESTAMP, REF_A, 32'd750);
            drive_msg(msg, 31);
        end
        repeat(5) @(posedge clk);

        chk_bool("exe_valid fired",           exe_seen,      1'b1);
        chk_bool("rep_valid NOT fired",       rep_seen,      1'b0);
        chk64   ("exe_order_ref",             s_exe_ref,     REF_A);
        chk32   ("exe_shares",                s_exe_shares,  32'd750);
        chk48   ("exe_timestamp",             s_exe_ts,      TIMESTAMP);

        // =====================================================================
        // Test X: Order Cancel (X) — 23 bytes
        // =====================================================================
        $display("\n--- Test X: Order Cancel (23 bytes) ---");
        clear_latches();
        begin
            automatic logic [7:0] msg[23];
            build_can(msg, LOCATE, TIMESTAMP, REF_B, 32'd100);
            drive_msg(msg, 23);
        end
        repeat(5) @(posedge clk);

        chk_bool("can_valid fired",           can_seen,      1'b1);
        chk_bool("exe_valid NOT fired",       exe_seen,      1'b0);
        chk64   ("can_order_ref",             s_can_ref,     REF_B);
        chk32   ("can_shares",                s_can_shares,  32'd100);
        chk48   ("can_timestamp",             s_can_ts,      TIMESTAMP);

        // =====================================================================
        // Test ?: Unknown message type — no valid should fire
        // =====================================================================
        $display("\n--- Test ?: Unknown type byte (0x50 = 'P') ---");
        clear_latches();
        begin
            // Type 'P' (0x50) is not decoded; drive 20 bytes of garbage
            automatic logic [7:0] msg[20];
            msg[0] = 8'h50; // 'P'
            for (int i = 1; i < 20; i++) msg[i] = 8'(i);
            drive_msg(msg, 20);
        end
        repeat(5) @(posedge clk);

        chk_bool("no add_valid on unknown",   add_seen,      1'b0);
        chk_bool("no del_valid on unknown",   del_seen,      1'b0);
        chk_bool("no rep_valid on unknown",   rep_seen,      1'b0);
        chk_bool("no exe_valid on unknown",   exe_seen,      1'b0);
        chk_bool("no can_valid on unknown",   can_seen,      1'b0);

        // =====================================================================
        // Test back-to-back: valid from message N is cleared before message N+1
        // Send two Add Orders in sequence; check second one's fields are right.
        // =====================================================================
        $display("\n--- Test back-to-back: two Add Orders in sequence ---");
        clear_latches();
        begin
            automatic logic [7:0] msg1[40], msg2[40];
            build_add(msg1, 16'h0001, TIMESTAMP, 64'hAAAA, 1'b1, 32'd111, STOCK, 32'h0001_0000);
            build_add(msg2, 16'h0002, TIMESTAMP, 64'hBBBB, 1'b0, 32'd222, STOCK, 32'h0002_0000);
            drive_msg(msg1, 36);
            repeat(2) @(posedge clk);
            drive_msg(msg2, 36);
        end
        repeat(5) @(posedge clk);

        // Snapshot was captured on each rising edge of add_valid.
        // After both messages, s_add_* holds the LAST message's values.
        chk64   ("2nd add: order_ref",        s_add_ref,     64'hBBBB);
        chk_bool("2nd add: side = SELL",      s_add_side,    1'b0);
        chk32   ("2nd add: shares",           s_add_shares,  32'd222);
        chk32   ("2nd add: price",            s_add_price,   32'h0002_0000);

        // =====================================================================
        // Summary
        // =====================================================================
        repeat(10) @(posedge clk);
        $display("\n=== Results: %0d PASS, %0d FAIL ===\n", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED\n");
        $finish;
    end

    initial begin #10_000_000; $display("TIMEOUT"); $finish; end

endmodule
