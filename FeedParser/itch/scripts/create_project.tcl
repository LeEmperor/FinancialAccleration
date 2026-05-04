## =============================================================================
## create_project.tcl
## Run from Vivado Tcl console:
##   cd /path/to/itch_demo
##   source scripts/create_project.tcl
## =============================================================================

set project_name "itch_demo"
set project_dir  [file normalize "./vivado"]
set part         "xc7a100tcsg324-1"  ;# Arty A7-100T

# Create project
create_project $project_name $project_dir -part $part -force

# Set project properties
set_property target_language SystemVerilog [current_project]
set_property simulator_language Mixed      [current_project]

# Add RTL sources
set rtl_files [list \
    [file normalize "./rtl/eth_rmii_rx.sv"]       \
    [file normalize "./rtl/moldudp64_parser.sv"]   \
    [file normalize "./rtl/itch_decoder.sv"]       \
    [file normalize "./rtl/order_book.sv"]         \
    [file normalize "./rtl/uart_reporter.sv"]      \
    [file normalize "./rtl/itch_demo_top.sv"]      \
]
add_files -norecurse $rtl_files
set_property file_type SystemVerilog [get_files *.sv]

# Add simulation sources
add_files -fileset sim_1 -norecurse [file normalize "./sim/tb_itch_demo.sv"]
set_property top tb_itch_demo [get_filesets sim_1]

# Add constraints
add_files -fileset constrs_1 -norecurse \
    [file normalize "./constraints/itch_demo_constraints_arty100t.xdc"]

# Set top module
set_property top itch_demo_top [current_fileset]

# Synthesis settings
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]

# Implementation settings  
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]

puts "\nProject created successfully."
puts "To simulate:    launch_simulation"
puts "To synthesize:  launch_runs synth_1 -jobs 4"
puts "To implement:   launch_runs impl_1 -jobs 4"
puts "To generate bit: open_run impl_1; write_bitstream -force ./itch_demo.bit\n"
