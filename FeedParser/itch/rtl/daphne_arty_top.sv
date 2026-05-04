///////////////////////////////////////////////////////////
// Bohdan Purtell
// University of Florida
// SmartSystems Laboratory, under Prof. Christophe Bobda
//
// Module: daphne_arty_top
// Top-level encompassing module for DAPHNE system testing on Arty A7 100T
// board.
// 
///////////////////////////////////////////////////////////

module daphne_arty_top
  import daphne_arty_top_pkg::*;
# (
  parameter int LEVEL_COUNT = daphne_arty_top_pkg::LEVEL_COUNT
) (
  // reg spec
  input  logic   clk, // 100 MHz board oscillator

  // Board IO
  input  logic [3:0]  buttons,
  input  logic [3:0]  switches,
  output logic [3:0]  leds,

  // Ethernet MII
  input  logic        eth_rx_clk,   // 25 MHz from PHY (RX clock)
  input  logic        eth_tx_clk,   // 25 MHz from PHY (TX clock)

  input  logic [3:0]  eth_rxd,
  input  logic        eth_rx_dv,
  input  logic        eth_rxerr,
  output logic        eth_rst_n,

  output logic        eth_tx_en,
  output logic [3:0]  eth_txd,
  output logic        eth_ref_clk,  // 25 MHz reference clock → PHY XTAL1/CLKIN

  // UART
  output logic        uart_tx
);

///////////////////////////////////////////////////////////
// Async reset — button active-low, so pressed = logic low = async_rst high
///////////////////////////////////////////////////////////
logic async_rst; assign async_rst = buttons[0];

///////////////////////////////////////////////////////////
// MMCM — generate 25 MHz eth_ref_clk from 100 MHz board clock
//
// CLKIN1 = 100 MHz → VCO = 100 × 10 = 1000 MHz (within 600–1200 MHz Artix-7 range)
// CLKOUT0 = 1000 / 40 = 25 MHz → BUFG → ODDR → eth_ref_clk pin
///////////////////////////////////////////////////////////
logic clk_25_unbuf;
logic clk_25;
logic mmcm_fb;
logic mmcm_locked;

MMCME2_BASE #(
  .CLKIN1_PERIOD    (10.0),   // 100 MHz
  .CLKFBOUT_MULT_F  (10.0),   // VCO = 1000 MHz
  .CLKOUT0_DIVIDE_F (40.0),   // 25 MHz
  .DIVCLK_DIVIDE    (1),
  .CLKOUT0_DUTY_CYCLE(0.5),
  .CLKOUT0_PHASE    (0.0),
  .CLKFBOUT_PHASE   (0.0),
  .BANDWIDTH        ("OPTIMIZED"),
  .CLKOUT4_CASCADE  ("FALSE"),
  .REF_JITTER1      (0.010),
  .STARTUP_WAIT     ("FALSE")
) mmcm_i (
  .CLKIN1   (clk),
  .CLKFBIN  (mmcm_fb),
  .CLKFBOUT (mmcm_fb),
  .CLKFBOUTB(),
  .CLKOUT0  (clk_25_unbuf),
  .CLKOUT0B (),
  .CLKOUT1  (), .CLKOUT1B(),
  .CLKOUT2  (), .CLKOUT2B(),
  .CLKOUT3  (), .CLKOUT3B(),
  .CLKOUT4  (),
  .CLKOUT5  (),
  .CLKOUT6  (),
  .LOCKED   (mmcm_locked),
  .PWRDWN   (1'b0),
  .RST      (async_rst)        // reset MMCM when button held
);

BUFG bufg_25 (
  .I(clk_25_unbuf),
  .O(clk_25)
);

// eth_rx_clk / eth_tx_clk arrive on SRCC pins — Vivado won't auto-insert
// a BUFG for these, so they must be explicitly buffered before being used
// as clocks anywhere in the design.
logic eth_rx_clk_buf;
logic eth_tx_clk_buf;

BUFG bufg_eth_rx (.I(eth_rx_clk), .O(eth_rx_clk_buf));
BUFG bufg_eth_tx (.I(eth_tx_clk), .O(eth_tx_clk_buf));

// Forward clk_25 out through ODDR — standard IOB clock-forwarding pattern.
// D1=1/D2=0 on SAME_EDGE produces a 50 % duty-cycle output toggling at clk_25.
ODDR #(
  .DDR_CLK_EDGE("SAME_EDGE"),
  .INIT        (1'b0),
  .SRTYPE      ("SYNC")
) oddr_eth_ref (
  .C  (clk_25),
  .CE (1'b1),
  .D1 (1'b1),
  .D2 (1'b0),
  .R  (1'b0),
  .S  (1'b0),
  .Q  (eth_ref_clk)
);

///////////////////////////////////////////////////////////
// 2FF Synchronizers
///////////////////////////////////////////////////////////
logic rst_meta_sys;
logic rst_sync_sys;
always_ff @(posedge clk or posedge async_rst)
begin
  if (async_rst) begin
    rst_meta_sys <= 0;
    rst_sync_sys <= 0;
  end else begin
    rst_meta_sys <= 1;
    rst_sync_sys <= rst_meta_sys;
  end
end

logic rst_meta_eth;
logic rst_sync_eth;
always_ff @(posedge eth_tx_clk_buf or posedge async_rst)
begin
  if (async_rst) begin
    rst_meta_eth <= 0;
    rst_sync_eth <= 0;
  end else begin
    rst_meta_eth <= 1'b1;
    rst_sync_eth <= rst_meta_eth;
  end
end

///////////////////////////////////////////////////////////
// Ethernet MII Receiver
///////////////////////////////////////////////////////////
logic [7:0] byte_out;
logic       byte_valid;
logic       udp_sof;

eth_mii_rx eth_mii_rx_i (
  .eth_rx_clk(eth_rx_clk_buf),
  .rst       (~rst_sync_eth),   // eth_mii_rx rst is active-high; sync is active-high-deasserted
  .rxd       (eth_rxd),
  .rx_dv     (eth_rx_dv),
  .rxerr     (eth_rxerr),
  .byte_out  (byte_out),
  .byte_valid(byte_valid),
  .udp_sof   (udp_sof)
);

///////////////////////////////////////////////////////////
// Test logic: CDC handshake + 64-byte FIFO
///////////////////////////////////////////////////////////
logic [7:0] tx_data;
logic       tx_valid;
logic       tx_ready;

test_logic test_logic_i (
  .sys_clk       (clk),
  .eth_clk       (eth_rx_clk_buf),
  .sys_rst       (~rst_sync_sys),
  .eth_rst       (~rst_sync_eth),
  .eth_data      (byte_out),
  .eth_data_valid(byte_valid),
  .eth_sof       (udp_sof),
  .tx_data       (tx_data),
  .tx_valid      (tx_valid),
  .tx_ready      (tx_ready)
);

///////////////////////////////////////////////////////////
// UART TX
///////////////////////////////////////////////////////////
logic tx_busy;

uart_tx #(
  .CLK_FREQ_HZ(daphne_arty_top_pkg::SYS_CLK_FREQ),
  .BAUD_RATE  (daphne_arty_top_pkg::UART_BAUD_RATE)
) uart_tx_i (
  .clk      (clk),
  .rst      (~rst_sync_sys),
  .tx_data  (tx_data),
  .tx_valid (tx_valid),
  .tx_ready (tx_ready),
  .tx_serial(uart_tx),
  .tx_busy  (tx_busy)
);

///////////////////////////////////////////////////////////
// LED indicators
///////////////////////////////////////////////////////////
logic [26:0] hb_cnt;
always_ff @(posedge clk) hb_cnt <= hb_cnt + 1;

assign leds[0] = hb_cnt[26];    // ~0.67 Hz heartbeat — confirms sys_clk alive
assign leds[1] = byte_valid;    // any Ethernet payload byte received
assign leds[2] = tx_busy;       // UART transmitting
assign leds[3] = mmcm_locked;   // MMCM locked = 25 MHz ref good

///////////////////////////////////////////////////////////
// Unused Ethernet TX (driven constant — receive-only demo)
///////////////////////////////////////////////////////////
assign eth_tx_en = 1'b0;
assign eth_txd   = 4'h0;

// Release PHY from reset only after MMCM is locked and button is not held.
// eth_rst_n is active-low; rst_sync_sys=1 and mmcm_locked=1 → PHY running.
assign eth_rst_n = rst_sync_sys & mmcm_locked;

endmodule

