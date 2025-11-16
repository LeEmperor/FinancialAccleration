# 1) Define your core clock (change period as needed)
create_clock -name core_clk -period 3.2 [get_ports clk]  ;# 312.5 MHz

# 2) Ignore I/O timing (we only care reg-to-reg internally)
#    Mark paths between ports and registers as false
set_false_path -from [get_ports *] -to [get_clocks core_clk]
set_false_path -from [get_clocks core_clk] -to [get_ports *]