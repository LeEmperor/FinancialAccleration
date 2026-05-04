// =============================================================================
// uart_reporter.sv 
// Arty A7-100T ITCH Demo
//
// Status: Verified Functional With Basic State Reset Probing
//
// 115200 8N1 UART transmitter.
// Formats ITCH events and BBO updates as human-readable ASCII strings
// and sends them over the Arty's USB-UART (connected to FTDI on IO0).
//
// String format examples:
//   ADD  REF=0000000000001A2B SIDE=B SZ=00001000 PX=01234500
//   DEL  REF=0000000000001A2B
//   REP  OLD=0000000000001A2B NEW=0000000000001A2C SZ=00001000 PX=01234500
//   EXE  REF=0000000000001A2B SZ=00000500
//   CAN  REF=0000000000001A2B SZ=00000200
//   BBO  BID=01234500x00010000 ASK=01234600x00005000
//   GAP  SEQ=0000000000001000
// =============================================================================

module uart_reporter #(
    parameter int CLK_HZ   = 100_000_000,
    parameter int BAUD     = 115_200
)(
    input  logic        clk,
    input  logic        rst_n,

    // Events from decoder / book
    input  logic        add_valid,
    input  logic [63:0] add_order_ref,
    input  logic        add_side,
    input  logic [31:0] add_shares,
    input  logic [31:0] add_price,

    input  logic        del_valid,
    input  logic [63:0] del_order_ref,

    input  logic        rep_valid,
    input  logic [63:0] rep_orig_ref,
    input  logic [63:0] rep_new_ref,
    input  logic [31:0] rep_shares,
    input  logic [31:0] rep_price,

    input  logic        exe_valid,
    input  logic [63:0] exe_order_ref,
    input  logic [31:0] exe_shares,

    input  logic        can_valid,
    input  logic [63:0] can_order_ref,
    input  logic [31:0] can_shares,

    input  logic        bbo_updated,
    input  logic [31:0] best_bid_price,
    input  logic [31:0] best_bid_size,
    input  logic [31:0] best_ask_price,
    input  logic [31:0] best_ask_size,

    input  logic        gap_detected,
    input  logic [63:0] gap_seq,

    // UART output
    output logic        uart_tx
);

    // -------------------------------------------------------------------------
    // Baud rate generator
    // -------------------------------------------------------------------------
    localparam int CLKS_PER_BIT = CLK_HZ / BAUD; // 868 @ 100MHz/115200

    // -------------------------------------------------------------------------
    // Transmit byte FIFO — 256 bytes deep
    // -------------------------------------------------------------------------
    localparam int FIFO_DEPTH = 256;
    logic [7:0]  fifo [FIFO_DEPTH];
    logic [7:0]  wr_ptr, rd_ptr;
    logic        fifo_empty;
    assign fifo_empty = (wr_ptr == rd_ptr);

    // UART state machine
    logic [9:0]  baud_cnt;
    logic [3:0]  bit_idx;
    logic [9:0]  shift_reg;   // {stop, data[7:0], start}
    logic        tx_busy;

    assign uart_tx = tx_busy ? shift_reg[0] : 1'b1; // idle high

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            baud_cnt  <= '0;
            bit_idx   <= '0;
            shift_reg <= 10'h3FF;
            tx_busy   <= 1'b0;
            rd_ptr    <= '0;
        end else begin
            if (!tx_busy) begin
                if (!fifo_empty) begin
                    // Load next byte: start(0) + data + stop(1)
                    shift_reg <= {1'b1, fifo[rd_ptr], 1'b0};
                    rd_ptr    <= rd_ptr + 1'b1;
                    tx_busy   <= 1'b1;
                    baud_cnt  <= '0;
                    bit_idx   <= '0;
                end
            end else begin
                if (baud_cnt == CLKS_PER_BIT - 1) begin
                    baud_cnt  <= '0;
                    shift_reg <= {1'b1, shift_reg[9:1]};
                    if (bit_idx == 4'd9) begin
                        tx_busy <= 1'b0;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end else begin
                    baud_cnt <= baud_cnt + 1'b1;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // Message formatter — pushes ASCII bytes into FIFO
    // -------------------------------------------------------------------------
    // We use a simple sequencer that builds strings into a local buffer then
    // drains them into the FIFO.

    logic [7:0]  msg_buf [80];  // max message length
    logic [6:0]  msg_len;
    logic [6:0]  msg_drain_idx;
    logic        draining;

    // Write pointer managed by formatter
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr        <= '0;
            msg_len       <= '0;
            msg_drain_idx <= '0;
            draining      <= 1'b0;
        end else begin
            if (draining) begin
                if (msg_drain_idx < msg_len) begin
                    fifo[wr_ptr]  <= msg_buf[msg_drain_idx];
                    wr_ptr        <= wr_ptr + 1'b1;
                    msg_drain_idx <= msg_drain_idx + 1'b1;
                end else begin
                    draining <= 1'b0;
                end
            end else begin
                // Format next event if any
                if (add_valid)      format_add();
                else if (del_valid) format_del();
                else if (rep_valid) format_rep();
                else if (exe_valid) format_exe();
                else if (can_valid) format_can();
                else if (bbo_updated) format_bbo();
                else if (gap_detected) format_gap();
            end
        end
    end

    // -------------------------------------------------------------------------
    // Hex conversion helper
    // -------------------------------------------------------------------------
    function automatic logic [7:0] hex_char(input logic [3:0] nibble);
        return (nibble < 4'd10) ? (8'h30 + nibble) : (8'h41 + nibble - 4'd10);
    endfunction

    // Write hex64 into msg_buf starting at offset, returns next offset
    function automatic logic [6:0] write_hex64(
        input logic [6:0]  offset,
        input logic [63:0] val
    );
        for (int i = 15; i >= 0; i--) begin
            msg_buf[offset + (15 - i)] <= hex_char(val[i*4 +: 4]);
        end
        return offset + 7'd16;
    endfunction

    function automatic logic [6:0] write_hex32(
        input logic [6:0]  offset,
        input logic [31:0] val
    );
        for (int i = 7; i >= 0; i--) begin
            msg_buf[offset + (7 - i)] <= hex_char(val[i*4 +: 4]);
        end
        return offset + 7'd8;
    endfunction

    function automatic logic [6:0] write_str(
        input logic [6:0]   offset,
        input logic [7:0]   s [16],
        input logic [3:0]   len
    );
        for (int i = 0; i < 16; i++) begin
            if (i < len) msg_buf[offset + i] <= s[i];
        end
        return offset + len;
    endfunction

    // -------------------------------------------------------------------------
    // Formatters
    // -------------------------------------------------------------------------
    task automatic start_drain(input logic [6:0] len);
        msg_buf[len]   <= 8'h0D; // CR
        msg_buf[len+1] <= 8'h0A; // LF
        msg_len        <= len + 7'd2;
        msg_drain_idx  <= 7'd0;
        draining       <= 1'b1;
    endtask

    task automatic format_add();
        logic [6:0] p;
        p = 0;
        // "ADD  REF="
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h41,8'h44,8'h44,8'h20,8'h20,8'h52,8'h45,8'h46,8'h3D};
        p = 9;
        p = write_hex64(p, add_order_ref);
        // " SIDE="
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3],msg_buf[p+4],msg_buf[p+5]} <=
            {8'h20,8'h53,8'h49,8'h44,8'h45,8'h3D};
        p = p + 6;
        msg_buf[p] <= add_side ? 8'h42 : 8'h53; // 'B' or 'S'
        p = p + 1;
        // " SZ="
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h53,8'h5A,8'h3D};
        p = p + 4;
        p = write_hex32(p, add_shares);
        // " PX="
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h50,8'h58,8'h3D};
        p = p + 4;
        p = write_hex32(p, add_price);
        start_drain(p);
    endtask

    task automatic format_del();
        logic [6:0] p;
        p = 0;
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h44,8'h45,8'h4C,8'h20,8'h20,8'h52,8'h45,8'h46,8'h3D};
        p = 9;
        p = write_hex64(p, del_order_ref);
        start_drain(p);
    endtask

    task automatic format_rep();
        logic [6:0] p;
        p = 0;
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h52,8'h45,8'h50,8'h20,8'h20,8'h4F,8'h4C,8'h44,8'h3D};
        p = 9;
        p = write_hex64(p, rep_orig_ref);
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h4E,8'h45,8'h57}; // " NEW"
        msg_buf[p+4] <= 8'h3D;
        p = p + 5;
        p = write_hex64(p, rep_new_ref);
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h53,8'h5A,8'h3D};
        p = p + 4;
        p = write_hex32(p, rep_shares);
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h50,8'h58,8'h3D};
        p = p + 4;
        p = write_hex32(p, rep_price);
        start_drain(p);
    endtask

    task automatic format_exe();
        logic [6:0] p;
        p = 0;
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h45,8'h58,8'h45,8'h20,8'h20,8'h52,8'h45,8'h46,8'h3D};
        p = 9;
        p = write_hex64(p, exe_order_ref);
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h53,8'h5A,8'h3D};
        p = p + 4;
        p = write_hex32(p, exe_shares);
        start_drain(p);
    endtask

    task automatic format_can();
        logic [6:0] p;
        p = 0;
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h43,8'h41,8'h4E,8'h20,8'h20,8'h52,8'h45,8'h46,8'h3D};
        p = 9;
        p = write_hex64(p, can_order_ref);
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3]} <=
            {8'h20,8'h53,8'h5A,8'h3D};
        p = p + 4;
        p = write_hex32(p, can_shares);
        start_drain(p);
    endtask

    task automatic format_bbo();
        logic [6:0] p;
        p = 0;
        // "BBO  BID="
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h42,8'h42,8'h4F,8'h20,8'h20,8'h42,8'h49,8'h44,8'h3D};
        p = 9;
        p = write_hex32(p, best_bid_price);
        msg_buf[p] <= 8'h78; // 'x'
        p = p + 1;
        p = write_hex32(p, best_bid_size);
        // " ASK="
        {msg_buf[p],msg_buf[p+1],msg_buf[p+2],msg_buf[p+3],msg_buf[p+4]} <=
            {8'h20,8'h41,8'h53,8'h4B,8'h3D};
        p = p + 5;
        p = write_hex32(p, best_ask_price);
        msg_buf[p] <= 8'h78;
        p = p + 1;
        p = write_hex32(p, best_ask_size);
        start_drain(p);
    endtask

    task automatic format_gap();
        logic [6:0] p;
        p = 0;
        {msg_buf[0],msg_buf[1],msg_buf[2],msg_buf[3],msg_buf[4],
         msg_buf[5],msg_buf[6],msg_buf[7],msg_buf[8]} <=
            {8'h47,8'h41,8'h50,8'h20,8'h20,8'h53,8'h45,8'h51,8'h3D};
        p = 9;
        p = write_hex64(p, gap_seq);
        start_drain(p);
    endtask

endmodule

