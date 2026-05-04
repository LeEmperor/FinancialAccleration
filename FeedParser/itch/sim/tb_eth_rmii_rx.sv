// =============================================================================
// tb_eth_rmii_rx.sv
// Unit testbench for eth_rmii_rx
//
// Tests:
//   1. Normal frame  — preamble / SFD / 42-byte header stripped, payload emitted
//   2. udp_sof       — fires exactly on the first payload byte, not before/after
//   3. Back-to-back  — second frame resets state cleanly
//   4. Aborted frame — rx_dv drops during header, no spurious payload bytes
//   5. Short preamble (1×0x55) — still detects SFD and works
//   6. Payload content — verify bytes arrive in order and uncorrupted
// =============================================================================

`timescale 1ns/1ps

module tb_eth_rmii_rx;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    logic        eth_clk = 0;
    logic        rst_n   = 0;
    logic [1:0]  rxd     = 2'b00;
    logic        rx_dv   = 1'b0;

    logic [7:0]  byte_out;
    logic        byte_valid;
    logic        udp_sof;

    eth_rmii_rx u_dut (
        .eth_clk    (eth_clk),
        .rst_n      (rst_n),
        .rxd        (rxd),
        .rx_dv      (rx_dv),
        .byte_out   (byte_out),
        .byte_valid (byte_valid),
        .udp_sof    (udp_sof)
    );

    // 50 MHz: 20 ns period
    always #10 eth_clk = ~eth_clk;

    initial begin
        repeat(4) @(posedge eth_clk);
        rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // RMII dibit driver
    // Each byte is 4 dibits, LSB-first (bits[1:0] first, then [3:2], [5:4], [7:6])
    // We drive rxd on the falling edge so it is stable on the rising sample edge.
    // -------------------------------------------------------------------------
    task automatic drive_dibit_byte(input logic [7:0] b);
        for (int d = 0; d < 4; d++) begin
            @(negedge eth_clk);
            rxd = b[2*d +: 2];
        end
    endtask

    // Drive a byte starting from the CURRENT negedge position (no initial wait).
    // Used when rx_dv is asserted at the same negedge as the first dibit, which
    // is what a real RMII PHY does — CRS_DV and RXD change simultaneously.
    task automatic drive_byte_from_negedge(input logic [7:0] b);
        rxd = b[1:0];                      // dibit 0 — we are already at negedge
        @(negedge eth_clk); rxd = b[3:2];  // dibit 1
        @(negedge eth_clk); rxd = b[5:4];  // dibit 2
        @(negedge eth_clk); rxd = b[7:6];  // dibit 3
    endtask

    // Drive a complete Ethernet frame.
    // preamble_reps: how many 0x55 bytes before SFD (spec = 7, min = 1)
    // payload[]: raw UDP payload bytes (after the 42-byte header)
    task automatic drive_frame(
        input int          preamble_reps,
        input logic [7:0]  payload[],
        input int          plen
    );
        // Assert rx_dv and the first preamble dibit at the SAME negedge so the
        // byte assembler sees no phantom dibit between rx_dv assertion and data.
        @(negedge eth_clk); rx_dv = 1'b1;
        drive_byte_from_negedge(8'h55);    // first preamble byte, in-phase with rx_dv
        // Preamble (remaining bytes)
        repeat(preamble_reps - 1) drive_dibit_byte(8'h55);
        // SFD
        drive_dibit_byte(8'hD5);
        // Ethernet header (14 bytes)
        repeat(14) drive_dibit_byte(8'hAA);
        // IP header (20 bytes, fixed, no options)
        repeat(20) drive_dibit_byte(8'hBB);
        // UDP header (8 bytes)
        repeat(8)  drive_dibit_byte(8'hCC);
        // UDP payload
        for (int i = 0; i < plen; i++)
            drive_dibit_byte(payload[i]);
        // End of frame — hold rx_dv for one extra cycle after the last dibit so
        // the RTL's byte assembler can deliver its final byte_ready pulse while
        // rx_dv is still high (the frame FSM checks !rx_dv before byte_ready).
        @(negedge eth_clk);
        @(negedge eth_clk); rx_dv = 1'b0; rxd = 2'b00;
    endtask

    // -------------------------------------------------------------------------
    // Output capture
    // -------------------------------------------------------------------------
    logic [7:0]  cap_bytes [256];
    int          cap_cnt;
    int          sof_byte_idx;   // which byte position udp_sof fired on (-1 = not seen)

    task automatic clear_capture();
        cap_cnt      = 0;
        sof_byte_idx = -1;
    endtask

    always @(posedge eth_clk) begin
        if (byte_valid) begin
            cap_bytes[cap_cnt] = byte_out;
            if (udp_sof) sof_byte_idx = cap_cnt;
            cap_cnt++;
        end
    end

    // -------------------------------------------------------------------------
    // Assertion helpers
    // -------------------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0;

    task automatic chk_eq(input string name,
                          input logic [31:0] got, input logic [31:0] exp);
        if (got === exp) begin
            $display("[PASS] %-40s : %0d", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-40s : got=%0d  exp=%0d", name, got, exp);
            fail_cnt++;
        end
    endtask

    task automatic chk_eq8(input string name,
                           input logic [7:0] got, input logic [7:0] exp);
        if (got === exp) begin
            $display("[PASS] %-40s : 0x%02X", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-40s : got=0x%02X  exp=0x%02X", name, got, exp);
            fail_cnt++;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge eth_clk);

        $display("\n=== tb_eth_rmii_rx ===\n");

        // =====================================================================
        // Test 1: Standard 7-preamble frame, 4-byte payload
        // =====================================================================
        $display("--- Test 1: standard frame, 4-byte payload ---");
        clear_capture();
        begin
            automatic logic [7:0] pl[4] = '{8'hDE, 8'hAD, 8'hBE, 8'hEF};
            drive_frame(7, pl, 4);
        end
        repeat(20) @(posedge eth_clk);

        chk_eq  ("byte count",           cap_cnt,           4);
        chk_eq  ("sof on byte 0",        sof_byte_idx,      0);
        chk_eq8 ("payload[0]",           cap_bytes[0],      8'hDE);
        chk_eq8 ("payload[1]",           cap_bytes[1],      8'hAD);
        chk_eq8 ("payload[2]",           cap_bytes[2],      8'hBE);
        chk_eq8 ("payload[3]",           cap_bytes[3],      8'hEF);

        // =====================================================================
        // Test 2: udp_sof fires only on the FIRST payload byte
        //         Send 8-byte payload, verify sof_byte_idx==0
        // =====================================================================
        $display("\n--- Test 2: udp_sof only on first payload byte ---");
        clear_capture();
        begin
            automatic logic [7:0] pl[8];
            for (int i = 0; i < 8; i++) pl[i] = 8'(i + 1);
            drive_frame(7, pl, 8);
        end
        repeat(20) @(posedge eth_clk);

        chk_eq("byte count",          cap_cnt,        8);
        chk_eq("sof index == 0",      sof_byte_idx,   0);

        // =====================================================================
        // Test 3: Back-to-back frames — second frame starts cleanly
        // =====================================================================
        $display("\n--- Test 3: back-to-back frames ---");
        begin
            automatic logic [7:0] pl_a[2] = '{8'h11, 8'h22};
            automatic logic [7:0] pl_b[2] = '{8'h33, 8'h44};

            clear_capture();
            drive_frame(7, pl_a, 2);
            repeat(4) @(posedge eth_clk);  // minimal inter-frame gap
            drive_frame(7, pl_b, 2);
            repeat(20) @(posedge eth_clk);
        end

        // Both frames' payloads should be captured (4 bytes total)
        chk_eq("back-to-back total bytes", cap_cnt,      4);
        chk_eq8("frame A byte 0",          cap_bytes[0], 8'h11);
        chk_eq8("frame A byte 1",          cap_bytes[1], 8'h22);
        chk_eq8("frame B byte 0",          cap_bytes[2], 8'h33);
        chk_eq8("frame B byte 1",          cap_bytes[3], 8'h44);

        // =====================================================================
        // Test 4: Aborted frame — rx_dv drops mid-header, no payload bytes
        // =====================================================================
        $display("\n--- Test 4: aborted frame (rx_dv drops during header) ---");
        clear_capture();
        begin
            @(negedge eth_clk); rx_dv = 1'b1;
            drive_byte_from_negedge(8'h55);    // first preamble byte, in-phase
            repeat(6) drive_dibit_byte(8'h55); // remaining 6 preamble bytes
            drive_dibit_byte(8'hD5);            // SFD
            repeat(15) drive_dibit_byte(8'hAA); // only 15 of 42 header bytes
            @(negedge eth_clk);
            @(negedge eth_clk); rx_dv = 1'b0; rxd = 2'b00;
        end
        repeat(20) @(posedge eth_clk);
        chk_eq("no bytes on abort", cap_cnt, 0);

        // Verify normal frame still works after abort
        begin
            automatic logic [7:0] pl[3] = '{8'hCA, 8'hFE, 8'h01};
            drive_frame(7, pl, 3);
        end
        repeat(20) @(posedge eth_clk);
        chk_eq  ("recovery byte count",   cap_cnt,      3);
        chk_eq8 ("recovery byte 0",       cap_bytes[0], 8'hCA);

        // =====================================================================
        // Test 5: Short preamble (1×0x55) — minimum allowed
        // =====================================================================
        $display("\n--- Test 5: short preamble (1 × 0x55) ---");
        clear_capture();
        begin
            automatic logic [7:0] pl[2] = '{8'hAB, 8'hCD};
            drive_frame(1, pl, 2);
        end
        repeat(20) @(posedge eth_clk);
        chk_eq  ("short-preamble byte count", cap_cnt,      2);
        chk_eq8 ("short-preamble byte 0",     cap_bytes[0], 8'hAB);
        chk_eq8 ("short-preamble byte 1",     cap_bytes[1], 8'hCD);

        // =====================================================================
        // Test 6: All-byte-values round-trip (0x00 through 0xFF in 16-byte frame)
        // =====================================================================
        $display("\n--- Test 6: all byte values 0x00..0xFF ---");
        begin
            automatic logic [7:0] pl[256];
            for (int i = 0; i < 256; i++) pl[i] = 8'(i);
            clear_capture();
            drive_frame(7, pl, 256);
        end
        repeat(20) @(posedge eth_clk);
        chk_eq("256-byte payload count", cap_cnt, 256);
        begin
            int mismatch = 0;
            for (int i = 0; i < 256; i++) begin
                if (cap_bytes[i] !== 8'(i)) mismatch++;
            end
            chk_eq("all byte values correct (mismatches)", mismatch, 0);
        end

        // =====================================================================
        // Summary
        // =====================================================================
        repeat(10) @(posedge eth_clk);
        $display("\n=== Results: %0d PASS, %0d FAIL ===\n", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED\n");
        $finish;
    end

    initial begin #20_000_000; $display("TIMEOUT"); $finish; end

endmodule
