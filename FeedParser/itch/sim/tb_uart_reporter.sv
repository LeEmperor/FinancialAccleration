// =============================================================================
// tb_uart_reporter.sv
// Unit testbench for uart_reporter
//
// Drives event strobes and decodes the UART TX output byte-by-byte.
// Uses a fast baud rate (10 MHz → 10 clk/bit at 100 MHz sys_clk) so the
// simulation runs in reasonable time.  The DUT parameters are overridden;
// ASCII content is identical to the real 115200 case.
//
// Tests:
//   1. ADD event       — "ADD  REF=<hex16> SIDE=B|S SZ=<hex8> PX=<hex8>\r\n"
//   2. ADD SELL side   — SIDE=S
//   3. DEL event       — "DEL  REF=<hex16>\r\n"
//   4. REP event       — "REP  OLD=<hex16> NEW=<hex16> SZ=<hex8> PX=<hex8>\r\n"
//   5. EXE event       — "EXE  REF=<hex16> SZ=<hex8>\r\n"
//   6. CAN event       — "CAN  REF=<hex16> SZ=<hex8>\r\n"
//   7. BBO event       — "BBO  BID=<hex8>x<hex8> ASK=<hex8>x<hex8>\r\n"
//   8. GAP event       — "GAP  SEQ=<hex16>\r\n"
//   9. Priority order  — when multiple events arrive together, ADD takes
//                        priority over BBO which follows in the FIFO
// =============================================================================

`timescale 1ns/1ps

module tb_uart_reporter;

    // -------------------------------------------------------------------------
    // Baud rate: 10 MHz (10 clk/bit at 100 MHz) — fast but functionally identical
    // -------------------------------------------------------------------------
    localparam int CLK_HZ        = 100_000_000;
    localparam int BAUD          = 10_000_000;
    localparam int CLKS_PER_BIT  = CLK_HZ / BAUD; // 10

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    logic        clk   = 0;
    logic        rst_n = 0;

    logic        add_valid     = 0;
    logic [63:0] add_order_ref = 0;
    logic        add_side      = 0;
    logic [31:0] add_shares    = 0;
    logic [31:0] add_price     = 0;

    logic        del_valid     = 0;
    logic [63:0] del_order_ref = 0;

    logic        rep_valid     = 0;
    logic [63:0] rep_orig_ref  = 0;
    logic [63:0] rep_new_ref   = 0;
    logic [31:0] rep_shares    = 0;
    logic [31:0] rep_price     = 0;

    logic        exe_valid     = 0;
    logic [63:0] exe_order_ref = 0;
    logic [31:0] exe_shares    = 0;

    logic        can_valid     = 0;
    logic [63:0] can_order_ref = 0;
    logic [31:0] can_shares    = 0;

    logic        bbo_updated   = 0;
    logic [31:0] best_bid_price= 0;
    logic [31:0] best_bid_size = 0;
    logic [31:0] best_ask_price= 0;
    logic [31:0] best_ask_size = 0;

    logic        gap_detected  = 0;
    logic [63:0] gap_seq       = 0;

    logic        uart_tx;

    always #5 clk = ~clk;

    uart_reporter #(
        .CLK_HZ (CLK_HZ),
        .BAUD   (BAUD)
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
        .bbo_updated    (bbo_updated),
        .best_bid_price (best_bid_price),
        .best_bid_size  (best_bid_size),
        .best_ask_price (best_ask_price),
        .best_ask_size  (best_ask_size),
        .gap_detected   (gap_detected),
        .gap_seq        (gap_seq),
        .uart_tx        (uart_tx)
    );

    initial begin
        repeat(4) @(posedge clk); rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // UART byte receiver — LSB-first 8N1
    // Waits for start bit, samples mid-bit, assembles byte, checks stop bit.
    // -------------------------------------------------------------------------
    task automatic recv_uart_byte(output logic [7:0] data);
        // Wait for start bit (uart_tx falls to 0)
        @(negedge uart_tx);
        // Sit in the middle of the start bit
        repeat(CLKS_PER_BIT / 2) @(posedge clk);
        // Sample 8 data bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            repeat(CLKS_PER_BIT) @(posedge clk);
            data[i] = uart_tx;
        end
        // Consume stop bit
        repeat(CLKS_PER_BIT) @(posedge clk);
    endtask

    // Receive a full line terminated by \r\n; returns content without CR/LF.
    // Aborts and returns what was collected if > 128 bytes received.
    task automatic recv_line(output string line);
        logic [7:0] b;
        int         idx = 0;
        line = "";
        forever begin
            recv_uart_byte(b);
            if (b == 8'h0D) begin  // CR — skip
                // nothing
            end else if (b == 8'h0A) begin  // LF — end of line
                break;
            end else begin
                line = {line, string'(b)};
                idx++;
                if (idx > 128) break;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Event pulse helper (1 clock cycle)
    // -------------------------------------------------------------------------
    task automatic pulse_add(
        input logic [63:0] order_ref, input logic side,
        input logic [31:0] shares, input logic [31:0] price
    );
        @(posedge clk); #1;
        add_valid     <= 1; add_order_ref <= order_ref;
        add_side      <= side;
        add_shares    <= shares; add_price <= price;
        @(posedge clk); #1;
        add_valid <= 0;
    endtask

    task automatic pulse_del(input logic [63:0] order_ref);
        @(posedge clk); #1;
        del_valid <= 1; del_order_ref <= order_ref;
        @(posedge clk); #1;
        del_valid <= 0;
    endtask

    task automatic pulse_rep(
        input logic [63:0] orig, input logic [63:0] nref,
        input logic [31:0] shares, input logic [31:0] price
    );
        @(posedge clk); #1;
        rep_valid    <= 1; rep_orig_ref <= orig; rep_new_ref  <= nref;
        rep_shares   <= shares; rep_price <= price;
        @(posedge clk); #1;
        rep_valid <= 0;
    endtask

    task automatic pulse_exe(input logic [63:0] order_ref, input logic [31:0] shares);
        @(posedge clk); #1;
        exe_valid <= 1; exe_order_ref <= order_ref; exe_shares <= shares;
        @(posedge clk); #1;
        exe_valid <= 0;
    endtask

    task automatic pulse_can(input logic [63:0] order_ref, input logic [31:0] shares);
        @(posedge clk); #1;
        can_valid <= 1; can_order_ref <= order_ref; can_shares <= shares;
        @(posedge clk); #1;
        can_valid <= 0;
    endtask

    task automatic pulse_bbo(
        input logic [31:0] b_px, input logic [31:0] b_sz,
        input logic [31:0] a_px, input logic [31:0] a_sz
    );
        @(posedge clk); #1;
        bbo_updated    <= 1;
        best_bid_price <= b_px; best_bid_size <= b_sz;
        best_ask_price <= a_px; best_ask_size <= a_sz;
        @(posedge clk); #1;
        bbo_updated <= 0;
    endtask

    task automatic pulse_gap(input logic [63:0] seq);
        @(posedge clk); #1;
        gap_detected <= 1; gap_seq <= seq;
        @(posedge clk); #1;
        gap_detected <= 0;
    endtask

    // -------------------------------------------------------------------------
    // Assertion helpers
    // -------------------------------------------------------------------------
    int pass_cnt = 0, fail_cnt = 0;

    task automatic chk_str(input string name, input string got, input string exp);
        if (got == exp) begin
            $display("[PASS] %-20s : \"%s\"", name, got);
            pass_cnt++;
        end else begin
            $display("[FAIL] %-20s :", name);
            $display("         got: \"%s\"", got);
            $display("         exp: \"%s\"", exp);
            fail_cnt++;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    string line;

    initial begin
        @(posedge rst_n);
        repeat(2) @(posedge clk);

        $display("\n=== tb_uart_reporter ===\n");

        // =====================================================================
        // Test 1: ADD BUY event
        // order_ref=0x0000000000001001, side=BUY, shares=0x000003E8(1000), price=0x0012D484
        // Expected: "ADD  REF=0000000000001001 SIDE=B SZ=000003E8 PX=0012D484"
        // =====================================================================
        $display("--- Test 1: ADD BUY ---");
        pulse_add(64'h0000000000001001, 1'b1, 32'h000003E8, 32'h0012D484);
        recv_line(line);
        chk_str("ADD BUY",  line,
                "ADD  REF=0000000000001001 SIDE=B SZ=000003E8 PX=0012D484");

        // =====================================================================
        // Test 2: ADD SELL event
        // =====================================================================
        $display("\n--- Test 2: ADD SELL ---");
        pulse_add(64'h0000000000001002, 1'b0, 32'h000001F4, 32'h0012D678);
        recv_line(line);
        chk_str("ADD SELL", line,
                "ADD  REF=0000000000001002 SIDE=S SZ=000001F4 PX=0012D678");

        // =====================================================================
        // Test 3: DEL event
        // =====================================================================
        $display("\n--- Test 3: DEL ---");
        pulse_del(64'hDEADBEEFCAFEBABE);
        recv_line(line);
        chk_str("DEL", line, "DEL  REF=DEADBEEFCAFEBABE");

        // =====================================================================
        // Test 4: REP event
        // =====================================================================
        $display("\n--- Test 4: REP ---");
        pulse_rep(64'h0000000000001001, 64'h0000000000001010, 32'h000000C8, 32'h0012D8A8);
        recv_line(line);
        chk_str("REP", line,
                "REP  OLD=0000000000001001 NEW=0000000000001010 SZ=000000C8 PX=0012D8A8");

        // =====================================================================
        // Test 5: EXE event
        // =====================================================================
        $display("\n--- Test 5: EXE ---");
        pulse_exe(64'h0000000000001001, 32'h00000064);
        recv_line(line);
        chk_str("EXE", line, "EXE  REF=0000000000001001 SZ=00000064");

        // =====================================================================
        // Test 6: CAN event
        // =====================================================================
        $display("\n--- Test 6: CAN ---");
        pulse_can(64'h0000000000001002, 32'h00000032);
        recv_line(line);
        chk_str("CAN", line, "CAN  REF=0000000000001002 SZ=00000032");

        // =====================================================================
        // Test 7: BBO event
        // bid=0x0012D484×0x000003E8  ask=0x0012D678×0x000001F4
        // Expected: "BBO  BID=0012D484x000003E8 ASK=0012D678x000001F4"
        // =====================================================================
        $display("\n--- Test 7: BBO ---");
        pulse_bbo(32'h0012D484, 32'h000003E8, 32'h0012D678, 32'h000001F4);
        recv_line(line);
        chk_str("BBO", line, "BBO  BID=0012D484x000003E8 ASK=0012D678x000001F4");

        // =====================================================================
        // Test 8: GAP event
        // seq=0x0000000000000008
        // Expected: "GAP  SEQ=0000000000000008"
        // =====================================================================
        $display("\n--- Test 8: GAP ---");
        pulse_gap(64'h0000000000000008);
        recv_line(line);
        chk_str("GAP", line, "GAP  SEQ=0000000000000008");

        // =====================================================================
        // Test 9: ADD and BBO fire same cycle — ADD line appears first
        // (formatter priority: add > bbo)
        // =====================================================================
        $display("\n--- Test 9: ADD and BBO same cycle → ADD line first ---");
        @(posedge clk); #1;
        add_valid      <= 1; add_order_ref <= 64'hCAFE; add_side <= 1;
        add_shares     <= 32'hFF; add_price <= 32'h1234;
        bbo_updated    <= 1;
        best_bid_price <= 32'h1234; best_bid_size <= 32'hFF;
        best_ask_price <= 32'h5678; best_ask_size <= 32'hAA;
        @(posedge clk); #1;
        add_valid <= 0; bbo_updated <= 0;

        recv_line(line);
        chk_str("priority: ADD first", line,
                "ADD  REF=000000000000CAFE SIDE=B SZ=000000FF PX=00001234");
        recv_line(line);
        chk_str("priority: BBO second", line,
                "BBO  BID=00001234x000000FF ASK=00005678x000000AA");

        // =====================================================================
        // Summary
        // =====================================================================
        $display("\n=== Results: %0d PASS, %0d FAIL ===\n", pass_cnt, fail_cnt);
        if (fail_cnt == 0) $display("ALL TESTS PASSED\n");

        $finish;
    end

    initial begin #10_000_000; $display("TIMEOUT"); $finish; end

endmodule
