///////////////////////////////////////////////////////////
// Bohdan Purtell
// University of Florida
// SmartSystems Laboratory, under Prof. Christophe Bobda
//
// Module: test_logic
// CDC: toggle-synchroniser (eth→sys), 64-byte FIFO, drives uart_tx.
//
// eth_rx_clk is 4× slower than sys_clk (25 MHz vs 100 MHz).
// A toggle held for 2 eth_rx_clk cycles = 8 sys_clk cycles, which is well
// above the 2-cycle 2FF sync window.  This lets every byte through, unlike
// the 4-phase handshake which had an 8-10 cycle round trip and dropped ~80%
// of bytes at full 100 Mb/s line rate.
///////////////////////////////////////////////////////////

module test_logic #(
  parameter int MAX_BYTES = 10   // max payload bytes forwarded per packet
) (
  input logic sys_clk,
  input logic eth_clk,

  input logic sys_rst,
  input logic eth_rst,

  input logic [7:0] eth_data,
  input logic       eth_data_valid,
  input logic       eth_sof,       // udp_sof: pulses on first payload byte of each frame

  // uart_tx interface (sys_clk domain)
  output logic [7:0] tx_data,
  output logic       tx_valid,
  input  logic       tx_ready
);

///////////////////////////////////////////////////////////
// Signal declarations
///////////////////////////////////////////////////////////

// eth_clk domain
logic [7:0]              eth_data_latch;
logic                    eth_toggle;       // flips on every valid byte (gated by counter)
logic [$clog2(MAX_BYTES+1)-1:0] payload_cnt;  // counts bytes since last sof

// 2FF toggle sync into sys_clk domain
logic       tog_meta;
logic       tog_sync;
logic       tog_prev;         // one cycle behind tog_sync for edge detect

// sys_clk domain
logic       new_byte;         // 1-cycle pulse: a new byte is ready

// FIFO
localparam int FIFO_DEPTH = 64;
localparam int FIFO_AW    = 6;

logic [7:0]       fifo_mem [FIFO_DEPTH];
logic [FIFO_AW:0] wr_ptr;
logic [FIFO_AW:0] rd_ptr;

wire fifo_full  = (wr_ptr[FIFO_AW] != rd_ptr[FIFO_AW]) &&
                  (wr_ptr[FIFO_AW-1:0] == rd_ptr[FIFO_AW-1:0]);
wire fifo_empty = (wr_ptr == rd_ptr);

///////////////////////////////////////////////////////////
// Domain: Eth (25 MHz)
// Latch byte and flip toggle on every valid strobe.
// eth_data_latch stays stable for the full 2-eth_clk byte window.
///////////////////////////////////////////////////////////
// When eth_sof and eth_data_valid fire on the same cycle (always true for the
// first payload byte), two NBAs would race on payload_cnt. Use a combinatorial
// "effective" count that applies the SOF reset before evaluating the gate.
logic [$clog2(MAX_BYTES+1)-1:0] effective_cnt;
assign effective_cnt = eth_sof ? '0 : payload_cnt;

always_ff @(posedge eth_clk or posedge eth_rst)
begin
  if (eth_rst) begin
    eth_data_latch <= '0;
    eth_toggle     <= 1'b0;
    payload_cnt    <= '0;
  end else begin
    payload_cnt <= effective_cnt; // apply SOF reset unconditionally

    if (eth_data_valid && effective_cnt < MAX_BYTES) begin
      eth_data_latch <= eth_data;
      eth_toggle     <= ~eth_toggle;
      payload_cnt    <= effective_cnt + 1; // overrides the line above
    end
  end
end

///////////////////////////////////////////////////////////
// 2FF synchroniser: eth_toggle → sys_clk domain
// + one extra register for edge detection
///////////////////////////////////////////////////////////
always_ff @(posedge sys_clk or posedge sys_rst)
begin
  if (sys_rst) begin
    tog_meta <= 1'b0;
    tog_sync <= 1'b0;
    tog_prev <= 1'b0;
  end else begin
    tog_meta <= eth_toggle;
    tog_sync <= tog_meta;
    tog_prev <= tog_sync;
  end
end

assign new_byte = tog_sync ^ tog_prev;   // fires once per byte crossing

///////////////////////////////////////////////////////////
// FIFO write (sys_clk)
// Bytes silently dropped when full — UART is ~1000× slower than line rate.
///////////////////////////////////////////////////////////
always_ff @(posedge sys_clk or posedge sys_rst)
begin
  if (sys_rst) begin
    wr_ptr <= '0;
  end else begin
    if (new_byte && !fifo_full) begin
      fifo_mem[wr_ptr[FIFO_AW-1:0]] <= eth_data_latch;
      wr_ptr <= wr_ptr + 1;
    end
  end
end

///////////////////////////////////////////////////////////
// FIFO read → uart_tx (sys_clk)
///////////////////////////////////////////////////////////
always_ff @(posedge sys_clk or posedge sys_rst)
begin
  if (sys_rst) begin
    rd_ptr   <= '0;
    tx_valid <= 1'b0;
    tx_data  <= '0;
  end else begin
    tx_valid <= 1'b0;

    // Guard with !tx_valid: tx_ready stays high for one extra cycle after we
    // assert tx_valid (uart_tx is an always_ff too and hasn't updated yet).
    // Without this, the reader fires twice and drops every other byte.
    if (!fifo_empty && tx_ready && !tx_valid) begin
      tx_data  <= fifo_mem[rd_ptr[FIFO_AW-1:0]];
      tx_valid <= 1'b1;
      rd_ptr   <= rd_ptr + 1;
    end
  end
end

endmodule
