# // main compile script
vlog -sv -incr \
  ../src/AXIS_interface_v1.sv \
  ../src/cutthrough_v1.sv \
    \
  ../testbenches/transfer_tb_v1.sv ;

# // main sim script
# // vsim -t 1ps -L work -voptargs="+acc" testbench_ALU_v1\ ;
vsim -t 1ps -L work -voptargs="+acc" axis_stream_tb_v1 ;
# // vsim -t 1ps -L work -voptargs="+acc" testbench_memory_v3;
# // vsim -t 1ps -L work -voptargs="+acc" testbench_registerFile_v1;
# // vsim -t 1ps -L work -voptargs="+acc" testbench_memory_v2;
# // add wave * ;
add wave -r *
# // do toplevel_wavelayout1.do
# // do wave.do
run -all ;
wave zoom full ;
view wave ;

# // main view script
# // vsim -view vsim.wlf -do "add wave *; wave zoom full; view objects" ;
# // vsim -view vsim.wlf
# // add wave *;
# // wave zoom full
# // view objects

