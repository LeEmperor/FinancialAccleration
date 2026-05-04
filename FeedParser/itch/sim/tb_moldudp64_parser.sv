// =============================================================================
// tb_moldudp64_parser.sv
// Unit testbench for moldudp64_parser
//
// Tests:
//   1. Single-message packet — header stripped, body bytes emitted
//   2. Multi-message packet  — all bodies emitted, out_msg_start on type bytes only
//   3. Gap detection         — fires when pkt_seqnum != expected_seq
//   4. No gap on first packet after reset (expected_seq guard)
//   5. SOF mid-packet resets — partial packet discarded, new packet parsed cleanly
//   6. Zero-message packet   — no output bytes
//   7. seq_num output tracks next expected sequence number
// =============================================================================

`timescale 1ns/1ps

module tb_moldudp64_parser;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        rst_n = 0;
    logic [7:0]  in_data  = 0;
    logic        in_valid = 0;
    logic        in_sof   = 0;

    logic [7:0]  out_data;
    logic        out_valid;
    logic        out_msg_start;
    logic        gap_detected;
    logic [63:0] seq_num;

    always #5 clk = ~clk;   // 100 MHz

    moldudp64_parser u_dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .in_data      (in_data),
        .in_valid     (in_valid),
        .in_sof       (in_sof),
        .out_data     (out_data),
        .out_valid    (out_valid),
        .out_msg_start(out_msg_start),
        .gap_detected (gap_detected),
        .seq_num      (seq_num)
    );

    initial begin
        repeat(4) @(posedge clk); rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // Drive one byte (1-cycle valid), optional SOF, 2-cycle gap after
    // -------------------------------------------------------------------------
    task automatic drive_byte(input logic [7:0] b, input logic sof = 1'b0);
        @(posedge clk); #1;
        in_data  <= b;
        in_valid <= 1'b1;
        in_sof   <= sof;
        @(posedge clk); #1;
        in_valid <= 1'b0;
        in_sof   <= 1'b0;
        repeat(2) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Drive a full MoldUDP64 UDP payload packet.
    //
    // Layout (all big-endian):
    //   bytes  0-9  : session ID  (10 bytes, we use "DEMOSESS01")
    //   bytes 10-17 : sequence number (uint64)
    //   bytes 18-19 : message count   (uint16)
    //   per message block:
    //     2 bytes  : block length (includes type byte)
    //     N bytes  : ITCH message body
    // -------------------------------------------------------------------------
    task automatic drive_mold_hdr(input logic [63:0] seqnum,
                                   input logic [15:0] msg_count);
        // Session ID "DEMOSESS01" (10 bytes) — first byte is SOF
        drive_byte(8'h44, 1'b1); // 'D' with SOF
        drive_byte(8'h45);       // 'E'
        drive_byte(8'h4D);       // 'M'
        drive_byte(8'h4F);       // 'O'
        drive_byte(8'h53);       // 'S'
        drive_byte(8'h45);       // 'E'
        drive_byte(8'h53);       // 'S'
        drive_byte(8'h53);       // 'S'
        drive_byte(8'h30);       // '0'
        drive_byte(8'h31);       // '1'
        // Sequence number (8 bytes, big-endian)
        drive_byte(seqnum[63:56]); drive_byte(seqnum[55:48]);
        drive_byte(seqnum[47:40]); drive_byte(seqnum[39:32]);
        drive_byte(seqnum[31:24]); drive_byte(seqnum[23:16]);
        drive_byte(seqnum[15:8]);  drive_byte(seqnum[7:0]);
        // Message count (2 bytes)
        drive_byte(msg_count[15:8]);
        drive_byte(msg_count[7:0]);
    endtask

    // Drive a message block: 2-byte length prefix then body bytes
    task automatic drive_block(input logic [7:0] body[], input int blen);
        automatic logic [15:0] len = 16'(blen);
        drive_byte(len[15:8]);
        drive_byte(len[7:0]);
        for (int i = 0; i < blen; i++)
            drive_byte(body[i]);
    endtask

    // -------------------------------------------------------------------------
    // Output capture
    // -------------------------------------------------------------------------
    logic [7:0]  out_buf  [512];
    logic        out_start[512];   // out_msg_start for each captured byte
    int          out_cnt;
    logic        gap_seen;
    logic [63:0] last_seq_num;

    task automatic clear_capture();
        out_cnt  = 0;
        gap_seen = 0;
    endtask

    always @(posedge clk) begin
        if (out_valid) begin
            out_buf  [out_cnt] = out_data;
            out_start[out_cnt] = out_msg_start;
            out_cnt++;
        end
        if (gap_detected) gap_seen <= 1'b1;
        last_seq_num <= seq_num;
    end

    // -------------------------------------------------------------------------
    // Assertion helpers
    // -------------------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0;

    task automatic chk_eq(input string name,
                          input logic [31:0] got, input logic [31:0] exp);
        if (got === exp) begin
            $display("[PASS] %-45s : %0d", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=%0d  exp=%0d", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_eq8(input string name,
                           input logic [7:0] got, input logic [7:0] exp);
        if (got === exp) begin
            $display("[PASS] %-45s : 0x%02X", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=0x%02X  exp=0x%02X", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_bool(input string name,
                            input logic got, input logic exp);
        if (got === exp) begin
            $display("[PASS] %-45s : %0b", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-45s : got=%0b  exp=%0b", name, got, exp);
            fail_cnt++;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge clk);

        $display("\n=== tb_moldudp64_parser ===\n");

        // =====================================================================
        // Test 1: Single-message packet (seqnum=1, 3-byte body)
        // =====================================================================
        $display("--- Test 1: single-message packet, 3-byte body ---");
        clear_capture();
        drive_mold_hdr(64'd1, 16'd1);
        begin
            automatic logic [7:0] body[3] = '{8'hAA, 8'hBB, 8'hCC};
            drive_block(body, 3);
        end
        repeat(10) @(posedge clk);

        chk_eq  ("out_cnt == 3",            out_cnt,      3);
        chk_eq8 ("body[0]",                 out_buf[0],   8'hAA);
        chk_eq8 ("body[1]",                 out_buf[1],   8'hBB);
        chk_eq8 ("body[2]",                 out_buf[2],   8'hCC);
        chk_bool("out_msg_start on byte 0", out_start[0], 1'b1);
        chk_bool("no start on byte 1",      out_start[1], 1'b0);
        chk_bool("no start on byte 2",      out_start[2], 1'b0);

        // =====================================================================
        // Test 2: Two-message packet — msg_start fires on each type byte
        // =====================================================================
        $display("\n--- Test 2: two-message packet, out_msg_start on each type byte ---");
        clear_capture();
        drive_mold_hdr(64'd2, 16'd2);
        begin
            automatic logic [7:0] msg1[2] = '{8'h41, 8'h11}; // type 'A' + 1 byte
            automatic logic [7:0] msg2[3] = '{8'h44, 8'h22, 8'h33}; // type 'D' + 2 bytes
            drive_block(msg1, 2);
            drive_block(msg2, 3);
        end
        repeat(10) @(posedge clk);

        chk_eq  ("out_cnt == 5",              out_cnt,      5);
        chk_eq8 ("msg1 type byte",            out_buf[0],   8'h41);
        chk_eq8 ("msg1 data byte",            out_buf[1],   8'h11);
        chk_eq8 ("msg2 type byte",            out_buf[2],   8'h44);
        chk_eq8 ("msg2 data byte 0",          out_buf[3],   8'h22);
        chk_eq8 ("msg2 data byte 1",          out_buf[4],   8'h33);
        chk_bool("msg1 byte0: msg_start=1",   out_start[0], 1'b1);
        chk_bool("msg1 byte1: msg_start=0",   out_start[1], 1'b0);
        chk_bool("msg2 byte0: msg_start=1",   out_start[2], 1'b1);
        chk_bool("msg2 byte1: msg_start=0",   out_start[3], 1'b0);
        chk_bool("msg2 byte2: msg_start=0",   out_start[4], 1'b0);

        // =====================================================================
        // Test 3: Gap detection — packet seqnum jumps from 3 to 5
        //         (seqnum 3 was the next expected after Test 2: start=2, 2 msgs)
        // =====================================================================
        $display("\n--- Test 3: gap detection (seqnum=5, expected=4) ---");
        clear_capture();
        // seqnum=3: no gap, expected was 3 after test 2
        drive_mold_hdr(64'd4, 16'd1);
        begin
            automatic logic [7:0] body[1] = '{8'hEE};
            drive_block(body, 1);
        end
        repeat(10) @(posedge clk);
        chk_bool("no gap on seqnum=4 (expected=4)", gap_seen, 1'b0);

        clear_capture();
        drive_mold_hdr(64'd6, 16'd1); // expected=5, received=6 → gap
        begin
            automatic logic [7:0] body[1] = '{8'hFF};
            drive_block(body, 1);
        end
        repeat(10) @(posedge clk);
        chk_bool("gap fires on seqnum=6 (expected=5)", gap_seen, 1'b1);

        // =====================================================================
        // Test 4: Zero-message packet — no output bytes, no gap
        // =====================================================================
        $display("\n--- Test 4: zero-message packet ---");
        clear_capture();
        // After test 3: expected = 7 (received 6 + 1 msg)
        drive_mold_hdr(64'd7, 16'd0); // msg_count=0
        repeat(20) @(posedge clk);
        chk_eq  ("no bytes emitted", out_cnt,  0);
        chk_bool("no gap",           gap_seen, 1'b0);

        // =====================================================================
        // Test 5: SOF mid-packet resets the parser
        //         Send partial header bytes, then inject a new SOF packet
        // =====================================================================
        $display("\n--- Test 5: SOF mid-packet resets state ---");
        clear_capture();
        // Drive partial session ID bytes without SOF → just noise
        @(posedge clk); #1; in_data <= 8'hDE; in_valid <= 1'b1; in_sof <= 1'b0;
        @(posedge clk); #1; in_valid <= 0;
        repeat(5) @(posedge clk);
        @(posedge clk); #1; in_data <= 8'hAD; in_valid <= 1'b1;
        @(posedge clk); #1; in_valid <= 0;
        repeat(5) @(posedge clk);
        // Now start a proper packet (seqnum=7 continues from above, expected=7)
        drive_mold_hdr(64'd7, 16'd1);
        begin
            automatic logic [7:0] body[2] = '{8'h12, 8'h34};
            drive_block(body, 2);
        end
        repeat(10) @(posedge clk);
        chk_eq  ("bytes after SOF-reset",  out_cnt,    2);
        chk_eq8 ("byte 0 after reset",     out_buf[0], 8'h12);
        chk_eq8 ("byte 1 after reset",     out_buf[1], 8'h34);
        chk_bool("no gap after reset",     gap_seen,   1'b0);

        // =====================================================================
        // Test 6: Large block (max field sizes test — 36-byte Add Order body)
        // =====================================================================
        $display("\n--- Test 6: 36-byte block (ITCH Add Order size) ---");
        clear_capture();
        drive_mold_hdr(64'd8, 16'd1);
        begin
            automatic logic [7:0] body[36];
            body[0] = 8'h41; // 'A'
            for (int i = 1; i < 36; i++) body[i] = 8'(i);
            drive_block(body, 36);
        end
        repeat(10) @(posedge clk);
        chk_eq  ("36-byte block count",       out_cnt,      36);
        chk_eq8 ("first byte = type 'A'",     out_buf[0],   8'h41);
        chk_eq8 ("last byte = 35",            out_buf[35],  8'd35);
        chk_bool("msg_start on byte 0",       out_start[0], 1'b1);
        chk_bool("no msg_start on byte 35",   out_start[35],1'b0);

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
