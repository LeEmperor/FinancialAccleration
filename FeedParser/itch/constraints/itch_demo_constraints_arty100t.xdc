## =============================================================================
## Arty A7-100T — ITCH Demo Constraints
## Pin locations sourced from Arty-A7-100-Master.xdc (Digilent, Rev. D/E)
## =============================================================================

## System clock (100 MHz, bank 35)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { sys_clk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { sys_clk }]

## Reset — BTN0 (active high on Arty; press to assert reset)
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { rst_btn }]

## SW0 — slide up (logic 1) = run, slide down (logic 0) = hold in reset
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { sw0 }]

## UART TX → FTDI (labelled uart_rxd_out on schematic; /dev/ttyUSB1)
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]

## ============================================================================
## Ethernet — MII (all bank 15)
##
## eth_rx_clk is driven by the PHY at 25 MHz for 100BASE-TX.
## F15 is an SRCC (Single-Region Clock Capable) pin — suitable as a clock input.
## No generated clock needed; the FPGA does not source the PHY reference clock.
## ============================================================================

## MII RX clock from PHY (25 MHz for 100BASE-TX)
set_property -dict { PACKAGE_PIN F15   IOSTANDARD LVCMOS33 } [get_ports { eth_rx_clk }]
create_clock -add -name eth_rx_clk_pin -period 40.00 -waveform {0 20} [get_ports { eth_rx_clk }]

## MII RX data + control
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { eth_rx_dv   }]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[0]  }]
set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[1]  }]
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[2]  }]
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[3]  }]
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { eth_rxerr   }]

## MII TX (tied off — demo is receive-only; no eth_tx_clk needed)
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { eth_tx_en   }]
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[0]  }]
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[1]  }]
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[2]  }]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { eth_txd[3]  }]

## PHY hard reset (active low; C16 = Sch:eth_rstn)
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { eth_rst_n }]

## ============================================================================
## LEDs (bank 35 / bank 14)
## ============================================================================
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## ============================================================================
## MII I/O timing (relative to eth_rx_clk_pin, period = 40 ns)
## Typical SMSC/Microchip PHY MII output: data valid 2–14 ns after rising edge.
## ============================================================================
set_input_delay  -clock eth_rx_clk_pin -max 14.0 [get_ports {eth_rxd[*] eth_rx_dv eth_rxerr}]
set_input_delay  -clock eth_rx_clk_pin -min  2.0 [get_ports {eth_rxd[*] eth_rx_dv eth_rxerr}]

## TX outputs are driven constant (tied off); no timing relationship required.
set_false_path -to [get_ports {eth_txd[*] eth_tx_en}]

## Async I/O — no timing relationship to any clock
set_false_path -from [get_ports {rst_btn sw0}]
set_false_path -to   [get_ports {uart_tx led[*] eth_rst_n}]

## ============================================================================
## Clock domain crossing — eth_rx_clk (25 MHz) → sys_clk (100 MHz)
##
## Toggle-synchroniser is used for the byte_valid strobe; byte_out and
## mii_is_sof are stable data (registered on the same eth_rx_clk edge as
## the toggle flip, so stable ≥80 ns before the synchronised pulse fires).
## Only the eth→sys direction has registered crossings.
## ============================================================================
set_false_path -from [get_clocks eth_rx_clk_pin] -to [get_clocks sys_clk_pin]
