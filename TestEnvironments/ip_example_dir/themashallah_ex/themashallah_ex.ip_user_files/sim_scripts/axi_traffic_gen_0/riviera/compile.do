transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/dist_mem_gen_v8_0_17
vlib riviera/axi_traffic_gen_v3_0_21
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap dist_mem_gen_v8_0_17 riviera/dist_mem_gen_v8_0_17
vmap axi_traffic_gen_v3_0_21 riviera/axi_traffic_gen_v3_0_21
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" -l xpm -l dist_mem_gen_v8_0_17 -l axi_traffic_gen_v3_0_21 -l xil_defaultlib \
"/home/wayne/xilinx/vivado_install/2025.1/Vivado/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/wayne/xilinx/vivado_install/2025.1/Vivado/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"/home/wayne/xilinx/vivado_install/2025.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work dist_mem_gen_v8_0_17  -incr -v2k5 "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" -l xpm -l dist_mem_gen_v8_0_17 -l axi_traffic_gen_v3_0_21 -l xil_defaultlib \
"../../../ipstatic/simulation/dist_mem_gen_v8_0.v" \

vlog -work axi_traffic_gen_v3_0_21  -incr -v2k5 "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" -l xpm -l dist_mem_gen_v8_0_17 -l axi_traffic_gen_v3_0_21 -l xil_defaultlib \
"../../../ipstatic/hdl/axi_traffic_gen_v3_0_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../ipstatic/hdl/src/verilog" "+incdir+../../../../../../../../../xilinx/vivado_install/2025.1/data/rsb/busdef" -l xpm -l dist_mem_gen_v8_0_17 -l axi_traffic_gen_v3_0_21 -l xil_defaultlib \
"../../../../themashallah_ex.gen/sources_1/ip/axi_traffic_gen_0/sim/axi_traffic_gen_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

