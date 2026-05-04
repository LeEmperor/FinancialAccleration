// uart_tx_test.sv — bare-minimum UART TX loopback sanity check
// Arty A7-100T, 100 MHz sys_clk, 115200 8N1
//
// Sends "A\r\n", "B\r\n", ... "Z\r\n", then wraps — one line per second.
// LED[0] heartbeats ~1.5 s so you can tell the board is alive without UART.
// Press BTN0 to reset and restart from 'A'.
//
// NOTE: Arty A7 buttons are active-HIGH (pulled low, go high when pressed).
// Power-on reset auto-releases after 4 cycles — no button press needed.

module uart_tx_test (
    input  logic       sys_clk,  // 100 MHz (E3)
    input  logic       rst_btn,  // BTN0 active-HIGH (D9), press to reset
    output logic       uart_tx,  // USB-UART TX (D10)
    output logic [3:0] led
);

    localparam int CLKS_PER_BIT = 100_000_000 / 115_200; // 868
    localparam int ONE_SEC       = 100_000_000;

    // -------------------------------------------------------------------------
    // Reset: power-on reset auto-releases + BTN0 manual reset (active-high)
    // -------------------------------------------------------------------------
    logic [3:0] por_pipe;
    always_ff @(posedge sys_clk)
        por_pipe <= {por_pipe[2:0], 1'b1};

    wire rst = !por_pipe[3] | rst_btn; // active-high, synchronous

    // -------------------------------------------------------------------------
    // Heartbeat — bit 26 of a 27-bit counter, toggles ~0.75 Hz
    // -------------------------------------------------------------------------
    logic [26:0] hb;
    always_ff @(posedge sys_clk)
        if (rst) hb <= '0; else hb <= hb + 1;
    assign led = {3'b0, hb[26]};

    // -------------------------------------------------------------------------
    // UART TX — bare 8N1 shifter
    // -------------------------------------------------------------------------
    logic [9:0] shift;
    logic [9:0] baud_cnt;
    logic [3:0] bit_cnt;
    logic       tx_busy;

    assign uart_tx = tx_busy ? shift[0] : 1'b1; // idle high

    // -------------------------------------------------------------------------
    // 3-byte send FIFO: [char, CR, LF]
    // -------------------------------------------------------------------------
    logic [7:0] fifo [3];
    logic [1:0] fifo_rd;
    logic [1:0] fifo_cnt;

    // -------------------------------------------------------------------------
    // 1-second sequencer + UART drainer — single always_ff
    // -------------------------------------------------------------------------
    logic [26:0] sec_cnt;
    logic [7:0]  ch;

    always_ff @(posedge sys_clk) begin
        if (rst) begin
            shift    <= 10'h3FF;
            baud_cnt <= '0;
            bit_cnt  <= '0;
            tx_busy  <= 1'b0;
            fifo_rd  <= '0;
            fifo_cnt <= '0;
            sec_cnt  <= '0;
            ch       <= 8'h41; // 'A'
            fifo[0]  <= 8'h41;
            fifo[1]  <= 8'h0D;
            fifo[2]  <= 8'h0A;
        end else begin

            // -- 1-second timer: load FIFO when empty -----------------------
            if (fifo_cnt == 0) begin
                if (sec_cnt == 27'(ONE_SEC - 1)) begin
                    sec_cnt  <= '0;
                    fifo[0]  <= ch;
                    fifo[1]  <= 8'h0D; // CR
                    fifo[2]  <= 8'h0A; // LF
                    fifo_rd  <= '0;
                    fifo_cnt <= 2'd3;
                    ch       <= (ch == 8'h5A) ? 8'h41 : ch + 8'h1; // A-Z wrap
                end else begin
                    sec_cnt <= sec_cnt + 1;
                end
            end

            // -- UART drainer -----------------------------------------------
            if (!tx_busy && fifo_cnt != 0) begin
                shift    <= {1'b1, fifo[fifo_rd], 1'b0}; // stop|data|start
                baud_cnt <= '0;
                bit_cnt  <= '0;
                tx_busy  <= 1'b1;
                fifo_rd  <= fifo_rd + 2'h1;
                fifo_cnt <= fifo_cnt - 2'h1;
            end else if (tx_busy) begin
                if (baud_cnt == 10'(CLKS_PER_BIT - 1)) begin
                    baud_cnt <= '0;
                    shift    <= {1'b1, shift[9:1]};
                    if (bit_cnt == 4'd9) tx_busy <= 1'b0;
                    else                  bit_cnt <= bit_cnt + 1;
                end else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end

        end
    end

endmodule
