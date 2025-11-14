vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/dist_mem_gen_v8_0_17
vlib modelsim_lib/msim/axi_traffic_gen_v3_0_21
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap dist_mem_gen_v8_0_17 modelsim_lib/msim/dist_mem_gen_v8_0_17
vmap axi_traffic_gen_v3_0_21 modelsim_lib/msim/axi_traffic_gen_v3_0_21
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" \
"/home/wayne/xilinx/vivado_install/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/wayne/xilinx/vivado_install/2025.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93  \
"/home/wayne/xilinx/vivado_install/2025.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work dist_mem_gen_v8_0_17 -64 -incr -mfcu  "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" \
"../../../ipstatic/simulation/dist_mem_gen_v8_0.v" \

vlog -work axi_traffic_gen_v3_0_21 -64 -incr -mfcu  "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" \
"../../../ipstatic/hdl/axi_traffic_gen_v3_0_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu  "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" \
"../../../../themashallah_ex.gen/sources_1/ip/axi_traffic_gen_0/sim/axi_traffic_gen_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

