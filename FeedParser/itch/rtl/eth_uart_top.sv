// Top-level: MII RX → UART TX
//
// Captures the first CAPTURE_BYTES bytes of each incoming Ethernet frame and
// streams them over UART, followed by "\r\n", so a serial terminal on the host
// shows each frame as a line of raw bytes.
//
// Clock domains
//   sys_clk    100 MHz  – UART drain FSM, latch, CDC registers
//   mii_rx_clk  25 MHz  – PHY MII RX (provided by PHY for 100 Mb/s)
//
// MII pin assignment
//   The Arty A7-100T onboard PHY is RMII (LAN8720).  If you are using an
//   external MII PHY, route it through PMOD JA or JB and update the XDC.
//   See constraints/eth_uart_top.xdc for a PMOD JA example.

module eth_uart_top #(
    parameter int CAPTURE_BYTES  = 24,
    parameter int CLK_FREQ_HZ    = 100_000_000,
    parameter int BAUD_RATE      = 115_200,
    parameter int PAYLOAD_OFFSET = 14
) (
    // Board
    input  wire        clk100,
    input  wire        btn_reset,      // BTN0, active-high

    // MII RX from PHY (25 MHz rx_clk at 100 Mb/s)
    input  wire        mii_rx_clk,
    input  wire        mii_rx_dv,
    input  wire        mii_rx_er,
    input  wire [3:0]  mii_rxd,

    // UART TX → USB-FTDI → host laptop
    output wire        uart_tx,

    // PHY Control
    output wire mii_ref_clk,
    output wire mii_rstn,

    // Debug LEDs
    output logic [3:0] led
);

// ── Reset synchronisers ───────────────────────────────────────────────────────
logic sys_rst_a, sys_rst;
always_ff @(posedge clk100) begin
    sys_rst_a <= btn_reset;
    sys_rst   <= sys_rst_a;
end

logic rx_rst_a, rx_rst;
always_ff @(posedge mii_rx_clk) begin
    rx_rst_a <= btn_reset;
    rx_rst   <= rx_rst_a;
end

////////////////////////////////////////////////////////////////////////////////////////
// PHY Ref Clk -> Manually instead of via MCMM
logic [1:0] ref_clk_cnt;
always_ff @(posedge clk100)
begin
  if (btn_reset) begin
    ref_clk_cnt <= 0;
  end else begin
    ref_clk_cnt <= ref_clk_cnt + 1;
  end
end
assign mii_ref_clk = ref_clk_cnt[1];
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// PHY Reset: Hold Low for a bit after RESET, then release
logic [19:0] phy_rst_cnt;
logic        phy_rst_done;
always_ff @(posedge clk100)
begin
  if (btn_reset) begin
    phy_rst_cnt  <= 0;
    phy_rst_done <= 0;
  end else begin
    phy_rst_cnt <= phy_rst_cnt + 1;
    if (phy_rst_cnt == 20'hF_FFFF) begin
      phy_rst_done <= 1;
    end
  end
end
assign mii_rstn = phy_rst_done;
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// Heartbeat LED (0.5s toggle)
logic [25:0] hb_cnt;
always_ff @(posedge clk100)
begin
  if (btn_reset) begin
    hb_cnt <= 0;
  end else begin
    hb_cnt <= hb_cnt + 1;
  end
end
assign led[0] = hb_cnt[25];
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
//


////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// MII RX (rx_clk domain)

wire              mii_frame_done;           // asserted in rx_clk domain
logic             mii_frame_ack;            // accepted in rx_clk domain
wire [7:0]        mii_frame_bytes [CAPTURE_BYTES];

mii_rx #(
    .CAPTURE_BYTES (CAPTURE_BYTES)
) mii_rx_i0 (
    .rx_clk      (mii_rx_clk),
    .reset       (rx_rst || !phy_rst_done),
    .rx_dv       (mii_rx_dv),
    .rx_er       (mii_rx_er),
    .rxd         (mii_rxd),
    .frame_ack   (frame_ack),
    .frame_done  (frame_done),
    .frame_bytes (frame_bytes)
);

////////////////////////////////////////////////////////////////////////////////////////
// CDC: frame_done  rx_clk → sys_clk (2FF sync)
logic frame_done_meta;
logic frame_done_sync;
logic frame_done_prev;

always_ff @(posedge clk100)
begin
  if (btn_reset) begin // does this rst have to be synced?
    frame_done_meta <= 0;
    frame_done_sync <= 0;
    frame_done_prev <= 0;
  end else begin
    frame_done_meta <= mii_frame_done;
    frame_done_sync <= frame_done_meta;
    frame_done_prev <= frame_done_sync;
  end
end
wire frame_done_rise = frame_done_sync && !frame_done_prev;

// CDC: frame_ack  sys_clk -> rx_clk (2FF sync)
logic frame_ack_sys; // sys domain
logic frame_ack_meta;
logic frame_ack_rx;  // rx domain
always_ff @(posedge clk100) 
begin
  if (btn_reset) begin
    frame_ack_meta <= 0;
    frame_ack_rx   <= 0;
  end else begin
    frame_ack_meta <= frame_ack_sys;
    frame_ack_rx   <= frame_ack_meta;
  end
end
assign mii_frame_ack = frame_ack_rx;
////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////
// Activity LED: pulse stretch
logic rx_dv_meta, rx_dv_sync;
always_ff @(posedge clk100) 
begin
  if (btn_reset) begin
    rx_dv_meta <= 0;
    rx_dv_sync <= 0;
  end else begin
    rx_dv_meta <= mii_rx_dv;
    rx_dv_sync <= rx_dv_meta;
  end
end

// pulse stretcher
logic [22:0] activity_stretch;
always_ff @(posedge clk100)
begin
  if (btn_reset) begin
    activity_stretch <= 0;
  end else if (rx_dv_sync) begin // when rx_dv goes high -> frame time
    activity_stretch <= 1; // set the LED high
  end else if (activity_stretch != 0) begin // when the frame ends, dv is de-asserted, therefore we fallback to this level
    // decrem the stretch counter
    activity_stretch <= activity_stretch - 1;
  end
end
assign led[1] = (activity_stretch != 0);
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// Frame Counter LED
logic frame_led_reg;
always_ff @(posedge clk100)
begin
  if (btn_reset) begin
    frame_led_reg <= 0;
  end else if (frame_done_rise) begin
    frame_led_reg <= ~frame_led_reg;
  end
end

////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// Payload Buffer: Latch MII RX data when frame_done rises (from rx -> sys)
////////////////////////////////////////////////////////////////////////////////////////
logic [7:0] payload [CAPTURE_BYTES];
always_ff @(posedge clk100)
begin
  if (frame_done_rise) begin
    for(int i = 0; i < CAPTURE_BYTES; i++) begin
      payload[i] <= mii_frame_bytes[PAYLOAD_OFFSET + i];
    end
  end
end
////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////
// UART TX Interface
////////////////////////////////////////////////////////////////////////////////////////

logic [7:0] tx_byte;
logic tx_valid;
wire  tx_ready;
uart_tx #(
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .BAUD_RATE   (BAUD_RATE)
) u_uart_tx (
    .clk       (clk100),
    .rst       (sys_rst),
    .tx_data   (tx_byte),
    .tx_valid  (tx_valid),
    .tx_ready  (tx_ready),
    .tx_serial (uart_tx),
    .tx_busy   ()
);
////////////////////////////////////////////////////////////////////////////////////////






// ── frame_ack: generate in sys_clk, sync back to rx_clk ──────────────────────
//
// Assert for 8 sys_clk cycles so the 2-FF synchroniser in rx_clk reliably
// sees a level (25 MHz rx_clk → 40 ns period; 8 × 10 ns = 80 ns hold).

logic [3:0] ack_cnt;
logic       ack_sys;

always_ff @(posedge clk100) begin
    if (sys_rst) begin
        ack_sys <= 1'b0;
        ack_cnt <= '0;
    end else if (frame_done_rise) begin
        ack_sys <= 1'b1;
        ack_cnt <= 4'd8;
    end else if (ack_sys) begin
        if (ack_cnt == 4'd1)
            ack_sys <= 1'b0;
        ack_cnt <= ack_cnt - 4'd1;
    end
end

logic ack_rx1, ack_rx2;
always_ff @(posedge mii_rx_clk) begin
    ack_rx1   <= ack_sys;
    ack_rx2   <= ack_rx1;
end
assign frame_ack = ack_rx2;

// ── UART drain FSM (sys_clk domain) ──────────────────────────────────────────
//
// On each frame_done_rise, stream buf[0..CAPTURE_BYTES-1] then "\r\n".
// Total drain bytes = CAPTURE_BYTES + 2.

localparam int           DRAIN_TOTAL = CAPTURE_BYTES + 2;
localparam int           IDX_W       = $clog2(DRAIN_TOTAL + 1);
// Unsigned localparams avoid sign-compare warnings in the drain FSM
localparam logic [IDX_W-1:0] CAP_IDX   = IDX_W'(CAPTURE_BYTES);
localparam logic [IDX_W-1:0] DRAIN_IDX = IDX_W'(DRAIN_TOTAL - 1);

logic [IDX_W-1:0] drain_idx;
logic             draining;

logic [7:0]       tx_data;
logic             tx_valid;
logic             tx_ready;
logic             tx_busy;

always_ff @(posedge clk100) begin
    if (sys_rst) begin
        draining   <= 1'b0;
        drain_idx  <= '0;
        tx_valid   <= 1'b0;
        tx_data    <= '0;
    end else begin
        tx_valid <= 1'b0;                   // default: no new byte

        if (frame_done_rise) begin
            draining  <= 1'b1;
            drain_idx <= '0;
        end else if (draining && tx_ready && !tx_valid) begin
            // Select byte to send
            if (drain_idx < CAP_IDX)
                tx_data <= cap[drain_idx[$clog2(CAPTURE_BYTES)-1:0]];
            else if (drain_idx == CAP_IDX)
                tx_data <= 8'h0D;           // '\r'
            else
                tx_data <= 8'h0A;           // '\n'

            tx_valid <= 1'b1;

            if (drain_idx == DRAIN_IDX)
                draining <= 1'b0;
            else
                drain_idx <= drain_idx + 1'b1;
        end
    end
end


endmodule

