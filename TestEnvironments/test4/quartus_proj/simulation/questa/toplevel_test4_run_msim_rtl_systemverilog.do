transcript on
if ![file isdirectory toplevel_test4_iputf_libs] {
	file mkdir toplevel_test4_iputf_libs
}

if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

if ![file isdirectory vhdl_libs] {
	file mkdir vhdl_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {c:/intelfpga_lite/24.1std/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

###### Libraries for IPUTF cores 
vlib toplevel_test4_iputf_libs/i_tse_mac
vmap i_tse_mac ./toplevel_test4_iputf_libs/i_tse_mac
###### End libraries for IPUTF cores 
###### MIF file copy and HDL compilation commands for IPUTF cores 


vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_eth_tse_mac.v"                     -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_clk_cntl.v"                    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_crc328checker.v"               -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_crc328generator.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_crc32ctl8.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_crc32galois8.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_gmii_io.v"                     -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_lb_read_cntl.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_lb_wrt_cntl.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_hashing.v"                     -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_host_control.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_host_control_small.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mac_control.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_register_map.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_register_map_small.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_counter_cntl.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_shared_mac_control.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_shared_register_map.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_counter_cntl.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_lfsr_10.v"                     -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_loopback_ff.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_altshifttaps.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_fifoless_mac_rx.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mac_rx.v"                      -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_fifoless_mac_tx.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mac_tx.v"                      -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_magic_detection.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mdio.v"                        -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mdio_clk_gen.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mdio_cntl.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_mdio.v"                    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mii_rx_if.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_mii_tx_if.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_pipeline_base.v"               -work i_tse_mac
vlog -sv "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_pipeline_stage.sv"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_dpram_16x32.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_dpram_8x32.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_dpram_ecc_16x32.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_fifoless_retransmit_cntl.v"    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_retransmit_cntl.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rgmii_in1.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rgmii_in4.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_nf_rgmii_module.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rgmii_module.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rgmii_out1.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rgmii_out4.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_ff.v"                       -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_min_ff.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_ff_cntrl.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_ff_cntrl_32.v"              -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_ff_cntrl_32_shift16.v"      -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_ff_length.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_rx_stat_extract.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_timing_adapter32.v"            -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_timing_adapter8.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_timing_adapter_fifo32.v"       -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_timing_adapter_fifo8.v"        -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_1geth.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_fifoless_1geth.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_w_fifo.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_w_fifo_10_100_1000.v"      -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_wo_fifo.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_wo_fifo_10_100_1000.v"     -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_top_gen_host.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff.v"                       -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_min_ff.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff_cntrl.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff_cntrl_32.v"              -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff_cntrl_32_shift16.v"      -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff_length.v"                -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_ff_read_cntl.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_tx_stat_extract.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_eth_tse_std_synchronizer.v"        -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_eth_tse_std_synchronizer_bundle.v" -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_eth_tse_ptp_std_synchronizer.v"    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_false_path_marker.v"           -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_reset_synchronizer.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_clock_crosser.v"               -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_13.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_24.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_34.v"                   -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_opt_1246.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_opt_14_44.v"            -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_a_fifo_opt_36_10.v"            -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_gray_cnt.v"                    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_sdpm_altsyncram.v"             -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_altsyncram_dpm_fifo.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_bin_cnt.v"                     -work i_tse_mac
vlog -sv "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ph_calculator.sv"              -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_sdpm_gen.v"                    -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x10.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x10.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x10_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x14.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x14.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x14_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x2.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x2.v"                  -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x2_wrapper.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x23.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x23.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x23_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x36.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x36.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x36_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x40.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x40.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x40_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_dec_x30.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x30.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_enc_x30_wrapper.v"         -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/mentor/altera_tse_ecc_status_crosser.v"          -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/altera_eth_tse_mac/altera_std_synchronizer_nocut.v"                 -work i_tse_mac
vlog     "C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ethernet_ip_folder_sim/ethernet_ip_folder.v"                                                              

vlog -vlog01compat -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4 {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/toplevel_test4.v}
vlog -vlog01compat -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ram_ip_folder {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/ram_ip_folder/ram_v2.v}
vlog -sv -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4 {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/source.sv}
vlog -sv -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4 {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/display.sv}
vlog -sv -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4 {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/clk_div1.sv}

vlog -sv -work work +incdir+C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/../testbenches {C:/FPGA_stuff/FinancialAccleration/TestEnvironments/test4/quartus_proj/../testbenches/toplevel_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -L i_tse_mac -voptargs="+acc"  toplevel_tb

add wave *
view structure
view signals
run -all
