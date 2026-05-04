## =============================================================================
## eth_readback.xdc — daphne_arty_top (Arty A7-100T)
##
## Ethernet MII RX → CDC handshake → UART TX loopback.
## Port names match daphne_arty_top.sv exactly.
## Pin locations sourced from arty_master.xdc (Digilent Rev. D/E).
## =============================================================================

## System clock (100 MHz, bank 35, MRCC)
set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk -period 10.00 -waveform {0 5} [get_ports { clk }]

## =============================================================================
## Ethernet PHY — MII (bank 15)
## eth_rx_clk is driven by the PHY at 25 MHz for 100BASE-TX.
## F15 is SRCC-capable — use as a real clock source.
## eth_tx_clk is also driven by the PHY at 25 MHz; used only for the eth-domain
## reset synchroniser, so its CDC path is false-pathed.
## =============================================================================

set_property -dict { PACKAGE_PIN F15  IOSTANDARD LVCMOS33 } [get_ports { eth_rx_clk }]
create_clock -add -name eth_rx_clk -period 40.00 -waveform {0 20} [get_ports { eth_rx_clk }]

set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS33 } [get_ports { eth_tx_clk }]
create_clock -add -name eth_tx_clk -period 40.00 -waveform {0 20} [get_ports { eth_tx_clk }]

## MII RX data + control
set_property -dict { PACKAGE_PIN G16  IOSTANDARD LVCMOS33 } [get_ports { eth_rx_dv    }]
set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[0]   }]
set_property -dict { PACKAGE_PIN E17  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[1]   }]
set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[2]   }]
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports { eth_rxd[3]   }]
set_property -dict { PACKAGE_PIN C17  IOSTANDARD LVCMOS33 } [get_ports { eth_rxerr    }]

## MII TX (driven constant — receive-only demo)
set_property -dict { PACKAGE_PIN H15  IOSTANDARD LVCMOS33 } [get_ports { eth_tx_en    }]
set_property -dict { PACKAGE_PIN H14  IOSTANDARD LVCMOS33 } [get_ports { eth_txd[0]   }]
set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS33 } [get_ports { eth_txd[1]   }]
set_property -dict { PACKAGE_PIN J13  IOSTANDARD LVCMOS33 } [get_ports { eth_txd[2]   }]
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports { eth_txd[3]   }]

## PHY hard reset (active-low; Sch=eth_rstn)
set_property -dict { PACKAGE_PIN C16  IOSTANDARD LVCMOS33 } [get_ports { eth_rst_n    }]

## eth_ref_clk — 25 MHz MMCM output → PHY XTAL1/CLKIN (Sch=eth_ref_clk, pin G18)
## Driven through ODDR; declare as generated clock so Vivado propagates timing correctly.
set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33 } [get_ports { eth_ref_clk  }]
create_generated_clock -name eth_ref_clk \
  -source [get_pins mmcm_i/CLKOUT0] \
  -divide_by 1 \
  [get_ports { eth_ref_clk }]

## =============================================================================
## UART TX → FTDI USB-serial (Sch=uart_rxd_out, /dev/ttyUSB1 on Linux)
## =============================================================================
set_property -dict { PACKAGE_PIN D10  IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]

## =============================================================================
## Buttons (active-low: logic-high when not pressed, logic-low when pressed)
## buttons[0] = BTN0 = reset
## =============================================================================
set_property -dict { PACKAGE_PIN D9   IOSTANDARD LVCMOS33 } [get_ports { buttons[0] }]
set_property -dict { PACKAGE_PIN C9   IOSTANDARD LVCMOS33 } [get_ports { buttons[1] }]
set_property -dict { PACKAGE_PIN B9   IOSTANDARD LVCMOS33 } [get_ports { buttons[2] }]
set_property -dict { PACKAGE_PIN B8   IOSTANDARD LVCMOS33 } [get_ports { buttons[3] }]

## Switches
set_property -dict { PACKAGE_PIN A8   IOSTANDARD LVCMOS33 } [get_ports { switches[0] }]
set_property -dict { PACKAGE_PIN C11  IOSTANDARD LVCMOS33 } [get_ports { switches[1] }]
set_property -dict { PACKAGE_PIN C10  IOSTANDARD LVCMOS33 } [get_ports { switches[2] }]
set_property -dict { PACKAGE_PIN A10  IOSTANDARD LVCMOS33 } [get_ports { switches[3] }]

## LEDs
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { leds[0] }]
set_property -dict { PACKAGE_PIN J5   IOSTANDARD LVCMOS33 } [get_ports { leds[1] }]
set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { leds[2] }]
set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { leds[3] }]

## =============================================================================
## Input timing — MII RX (relative to eth_rx_clk, period = 40 ns)
## SMSC LAN8720 MII output: data valid 2–14 ns after rising clock edge.
## =============================================================================
set_input_delay -clock eth_rx_clk -max 14.0 [get_ports { eth_rxd[*] eth_rx_dv eth_rxerr }]
set_input_delay -clock eth_rx_clk -min  2.0 [get_ports { eth_rxd[*] eth_rx_dv eth_rxerr }]

## =============================================================================
## Async / output false paths
## =============================================================================

## Buttons feed an async reset — no setup/hold relationship to any clock
set_false_path -from [get_ports { buttons[*] switches[*] }]

## Outputs with no timing requirement
set_false_path -to [get_ports { uart_tx leds[*] eth_rst_n eth_tx_en eth_txd[*] eth_ref_clk }]

## =============================================================================
## Clock domain crossings
## =============================================================================

## eth_rx_clk → sys_clk  (4-phase handshake in test_logic; 2-FF synchroniser)
set_false_path -from [get_clocks eth_rx_clk] -to [get_clocks sys_clk]

## sys_clk → eth_rx_clk  (ack path of the same handshake)
set_false_path -from [get_clocks sys_clk] -to [get_clocks eth_rx_clk]

## eth_tx_clk is only used for the reset synchroniser — all paths are false
set_false_path -from [get_clocks eth_tx_clk]
set_false_path -to   [get_clocks eth_tx_clk]
