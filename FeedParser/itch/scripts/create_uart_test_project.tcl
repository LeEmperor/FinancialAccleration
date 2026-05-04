## =============================================================================
## create_uart_test_project.tcl
## Vivado project for uart_test_top — hardware UART validation
##
## Instantiates uart_reporter directly (no Ethernet/ITCH path).
## On reset the board sequences through 8 canned events and prints them
## over USB-UART at 115200 8N1.
##
## Run from the Vivado Tcl console:
##   cd /path/to/itch_demo
##   source scripts/create_uart_test_project.tcl
## =============================================================================

set project_name "uart_test"
set project_dir  [file normalize "./vivado_uart_test"]
set part         "xc7a100tcsg324-1"

create_project $project_name $project_dir -part $part -force
set_property target_language SystemVerilog [current_project]
set_property simulator_language Mixed      [current_project]

# RTL sources — only what uart_test_top needs
set rtl_files [list \
    [file normalize "./rtl/uart_reporter.sv"] \
    [file normalize "./rtl/uart_test_top.sv"] \
]
add_files -norecurse $rtl_files
set_property file_type SystemVerilog [get_files *.sv]

# Constraints — same XDC (uart_test_top uses identical pin names)
add_files -fileset constrs_1 -norecurse \
    [file normalize "./constraints/arty_a7_100t.xdc"]

# Top module
set_property top uart_test_top [current_fileset]

# Synthesis / implementation settings
set_property strategy "Vivado Synthesis Defaults"          [get_runs synth_1]
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

puts ""
puts "Project '$project_name' created."
puts ""
puts "To build the bitstream:"
puts "  launch_runs synth_1 -jobs 4"
puts "  wait_on_run synth_1"
puts "  launch_runs impl_1 -jobs 4"
puts "  wait_on_run impl_1"
puts "  open_run impl_1"
puts "  write_bitstream -force $project_dir/uart_test.bit"
puts ""
puts "To program the board:"
puts "  open_hw_manager"
puts "  connect_hw_server"
puts "  open_hw_target"
puts "  program_hw_devices \[get_hw_devices xc7a100t_0\] -bitfile $project_dir/uart_test.bit"
puts ""
puts "To validate over UART:"
puts "  python3 scripts/validate_uart.py --port /dev/ttyUSB1"
puts ""
