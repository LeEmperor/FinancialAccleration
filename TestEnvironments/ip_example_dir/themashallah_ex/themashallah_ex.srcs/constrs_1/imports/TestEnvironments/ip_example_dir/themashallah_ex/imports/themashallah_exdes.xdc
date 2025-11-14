# This XDC is used only for exdes

# create_clock -name clock_in -period 5 [get_ports clk_in1_p]

#set_property LOC AD11 [ get_ports clk_in1_n]
#set_property IOSTANDARD DIFF_SSTL15 [ get_ports clk_in1_n]
#set_property LOC AD12 [ get_ports clk_in1_p]
#set_property IOSTANDARD DIFF_SSTL15 [ get_ports clk_in1_p]

#set_property LOC K24 [ get_ports tx]
#set_property IOSTANDARD LVCMOS25 [ get_ports tx]
#set_property LOC M19 [ get_ports rx]
#set_property IOSTANDARD LVCMOS25 [ get_ports rx]
#set_property LOC AB7 [ get_ports reset]
#set_property IOSTANDARD LVCMOS15 [ get_ports reset]
#set_property LOC Y29 [ get_ports start]
#set_property IOSTANDARD LVCMOS25 [ get_ports start]

#set_property CFGBVS VCCO [current_design]
#set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]

# clock
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {clk_100mhz}]

// two ports
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {tx}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {rx}]

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]




