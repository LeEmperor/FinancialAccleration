transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+axi_traffic_gen_0  -L xil_defaultlib -L xpm -L dist_mem_gen_v8_0_17 -L axi_traffic_gen_v3_0_21 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.axi_traffic_gen_0 xil_defaultlib.glbl

do {axi_traffic_gen_0.udo}

run 1000ns

endsim

quit -force
