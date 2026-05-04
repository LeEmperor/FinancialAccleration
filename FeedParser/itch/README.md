# ITCH 5.0 Demo — Arty A7-100T

Byte-serial MoldUDP64 + ITCH 5.0 parser with a simple order book,
targeting the Digilent Arty A7-100T (xc7a100tcsg324-1).

---

## Architecture

```
LAN8720 PHY (RMII)
    │ 2-bit dibits @ 50 MHz
    ▼
eth_rmii_rx.sv
    Strips preamble/SFD, skips 42-byte Eth+IP+UDP header
    Emits: byte_out, byte_valid, udp_sof
    │ 1 byte per ~80ns (10 clk cycles @ 100MHz — very relaxed)
    ▼
moldudp64_parser.sv
    Parses 20-byte MoldUDP64 header (session, seqnum, msgcount)
    Detects sequence gaps
    Iterates message blocks: strips 2-byte length prefix
    Emits: itch_byte, itch_valid, itch_msg_start
    │
    ▼
itch_decoder.sv
    Byte-serial state machine, dispatches on type byte
    Decodes: A (Add), D (Delete), U (Replace), E (Execute), X (Cancel)
    Emits structured fields with single-cycle valid strobes
    │
    ├──────────────────────────┐
    ▼                          ▼
order_book.sv            uart_reporter.sv
Maintains:               Formats events as ASCII
  - Order ref table      Sends over 115200 8N1 UART
    (256 slots, BRAM)    to Arty USB-FTDI port
  - 8 price levels
    each side
  - BBO registers
```

---

## Files

```
rtl/
  eth_rmii_rx.sv        RMII → byte-serial (50MHz eth_clk domain)
  moldudp64_parser.sv   MoldUDP64 header stripper + gap detector
  itch_decoder.sv       ITCH A/D/U/E/X message decoder
  order_book.sv         Price level book + BBO tracker
  uart_reporter.sv      115200 UART + ASCII formatter
  itch_demo_top.sv      Top-level wiring

sim/
  tb_itch_demo.sv       Full pipeline testbench with 4 test packets

constraints/
  arty_a7_100t.xdc      Pin assignments + clock constraints

scripts/
  create_project.tcl    Vivado project setup
```

---

## Building

### 1. Create Vivado Project

```tcl
# In Vivado Tcl console:
cd /path/to/itch_demo
source scripts/create_project.tcl
```

### 2. Simulate

```tcl
launch_simulation
run all
```

Expected simulation output:
```
=== ITCH Demo Testbench ===

[850ns]  ADD  ref=0000000000001001 side=BUY  sz=1000 px=1234484
[1650ns] ADD  ref=0000000000001002 side=SELL sz=500  px=1235000
[2450ns] ADD  ref=0000000000001003 side=BUY  sz=300  px=1234400
[2500ns] BBO  bid=1234484 x 1000  ask=1235000 x 500
...
[PASS] best_bid_price = 0x000000000012D484
[PASS] best_bid_size  = 0x00000000000003E8
[PASS] best_ask_price = 0x000000000012D678
[PASS] best_ask_size  = 0x00000000000001F4
...
ALL TESTS PASSED
```

### 3. Synthesise + Implement

```tcl
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1
open_run impl_1
write_bitstream -force itch_demo.bit
```

### 4. Program Board

```tcl
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [get_hw_devices xc7a100t_0] -bitfile itch_demo.bit
```

### 5. View UART Output

Connect a terminal at **115200 8N1** to the Arty's USB port (usually `/dev/ttyUSB1` on Linux, `COM3`-ish on Windows):

```bash
minicom -b 115200 -D /dev/ttyUSB1
# or
screen /dev/ttyUSB1 115200
```

Expected output (one line per event):
```
ADD  REF=0000000000001001 SIDE=B SZ=000003E8 PX=0012D484
ADD  REF=0000000000001002 SIDE=S SZ=000001F4 PX=0012D678
BBO  BID=0012D484x000003E8 ASK=0012D678x000001F4
DEL  REF=0000000000001001
BBO  BID=0012D420x000000C8 ASK=0012D678x000001F4
GAP  SEQ=0000000000000008
```

---

## Hardware Setup

```
Your PC ──── USB ────► Arty A7-100T
                          │  RMII
                       LAN8720 PHY
                          │  RJ45
                       Network switch / direct cable to
                       ITCH feed source (replay tool or
                       live NASDAQ TotalView-ITCH feed)
```

For testing without a live feed, use **Wireshark + a packet replay tool**
(e.g. `tcpreplay`) to play back a captured ITCH pcap file into the Arty's
Ethernet port.

NASDAQ publishes sample ITCH 5.0 pcap files at:
`https://emi.nasdaq.com/ITCH/Nasdaq%20ITCH/`

---

## Price Interpretation

ITCH wire prices are `actual_price × 10000`:

```
0x0012D484 = 1,234,052  → wait, example:
$123.45 × 10000 = 1,234,500 = 0x0012D484 ✓

To convert in Python:
  wire_price = 0x0012D484
  actual = wire_price / 10000.0  # → 123.45
```

---

## Known Limitations (Demo Scope)

| Limitation | Production Fix |
|---|---|
| 256 order slots (low 8 bits of ref used as index) | URAM hash table, full 64-bit key |
| 8 price levels per side | Deeper BRAM array or sorted structure |
| No IP/UDP checksum validation | Add in eth_rmii_rx |
| No dest port filtering | Filter on UDP dst port 26477 (ITCH) |
| No FCS check | Add CRC32 in RMII RX path |
| False-path CDC (no async FIFO) | Add small 2FF sync or async FIFO at eth→sys boundary |
| Single symbol book | Add stock_locate dispatch to per-symbol books |
| No SoupBinTCP gap recovery | Add soft CPU (MicroBlaze) for TCP retransmit |
