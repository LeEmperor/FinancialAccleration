# Define a 250 MHz clock (4 ns period) on the 'clk' port
create_clock -name sys_clk -period 7.00 [get_ports clk]

# (Optional but nice) Add a little uncertainty for realism
set_clock_uncertainty 0.1 [get_clocks sys_clk]

# For this toy, we don't care about IO timing.
# Mark all inputs/outputs (except clk) as false paths so they don't spam reports.

# set_false_path -from [remove_from_collection [all_inputs] [get_ports clk]]
# set_false_path -to   [all_outputs]

set_property PACKAGE_PIN NA [get_ports *]
set_property IOSTANDARD NONE [get_ports *]
