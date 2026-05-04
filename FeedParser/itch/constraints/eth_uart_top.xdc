## =============================================================================
## eth_uart_top — Arty A7-100T constraints
##
## MII RX is routed to PMOD JA (upper + lower row).
## If you are using a different PHY board or PMOD header, update the MII pins.
##
## PMOD JA pin map used here:
##   JA1  B11  → mii_rxd[0]
##   JA2  A11  → mii_rxd[1]
##   JA3  D12  → mii_rxd[2]
##   JA4  D13  → mii_rxd[3]
##   JA7  B18  → mii_rx_clk   (25 MHz from PHY)
##   JA8  A18  → mii_rx_dv
##   JA9  K16  → mii_rx_er
##   JA10 E15  → (spare / GND at PHY)
## =============================================================================

## System clock (100 MHz, bank 35)
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports { clk100 }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk100 }]

## Reset — BTN0 (active high)
set_property -dict { PACKAGE_PIN D9   IOSTANDARD LVCMOS33 } [get_ports { btn_reset }]

## UART TX → FTDI (/dev/ttyUSB1 on Linux)
set_property -dict { PACKAGE_PIN D10  IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]

## MII RX clock (25 MHz from PHY — create a real clock so Vivado times the RX path)
set_property -dict { PACKAGE_PIN B18  IOSTANDARD LVCMOS33 } [get_ports { mii_rx_clk }]
create_clock -add -name mii_rx_clk_pin -period 40.00 -waveform {0 20} [get_ports { mii_rx_clk }]

## MII RX data & control
set_property -dict { PACKAGE_PIN B11  IOSTANDARD LVCMOS33 } [get_ports { mii_rxd[0] }]
set_property -dict { PACKAGE_PIN A11  IOSTANDARD LVCMOS33 } [get_ports { mii_rxd[1] }]
set_property -dict { PACKAGE_PIN D12  IOSTANDARD LVCMOS33 } [get_ports { mii_rxd[2] }]
set_property -dict { PACKAGE_PIN D13  IOSTANDARD LVCMOS33 } [get_ports { mii_rxd[3] }]
set_property -dict { PACKAGE_PIN A18  IOSTANDARD LVCMOS33 } [get_ports { mii_rx_dv }]
set_property -dict { PACKAGE_PIN K16  IOSTANDARD LVCMOS33 } [get_ports { mii_rx_er }]

## LEDs
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN J5   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## =============================================================================
## Timing
## =============================================================================

## Async inputs — no timing relationship required
set_false_path -from [get_ports { btn_reset }]
set_false_path -to   [get_ports { uart_tx led[*] }]

## MII RX input timing (relative to mii_rx_clk_pin, period = 40 ns)
## Typical MII PHY: data valid 10 ns after clock edge, hold 10 ns.
## Adjust -max/-min to match your PHY datasheet.
set_input_delay -clock mii_rx_clk_pin -max 10.0 [get_ports { mii_rxd[*] mii_rx_dv mii_rx_er }]
set_input_delay -clock mii_rx_clk_pin -min  2.0 [get_ports { mii_rxd[*] mii_rx_dv mii_rx_er }]

## CDC: mii_rx_clk → sys_clk
## frame_done is held stable for hundreds of rx_clk cycles after assertion —
## the 2-FF synchroniser in the RTL is sufficient; treat as false path.
set_false_path -from [get_clocks mii_rx_clk_pin] -to [get_clocks sys_clk_pin]

## CDC: sys_clk → mii_rx_clk (frame_ack path)
## ack_sys is held for 8 sys_clk cycles (80 ns) — safe for the 2-FF synchroniser.
set_false_path -from [get_clocks sys_clk_pin] -to [get_clocks mii_rx_clk_pin]
