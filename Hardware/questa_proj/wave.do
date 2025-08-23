onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ethernet_v1_tb/t_clk
add wave -noupdate /ethernet_v1_tb/t_rst
add wave -noupdate /ethernet_v1_tb/clk_en
add wave -noupdate -radix hexadecimal /ethernet_v1_tb/t_dataout
add wave -noupdate -radix binary /ethernet_v1_tb/t_datain
add wave -noupdate /ethernet_v1_tb/t_packet
add wave -noupdate /ethernet_v1_tb/t_en
add wave -noupdate /ethernet_v1_tb/t_tvalid
add wave -noupdate /ethernet_v1_tb/t_CRS_DV
add wave -noupdate -radix unsigned /ethernet_v1_tb/i
add wave -noupdate -radix binary /ethernet_v1_tb/dut/RXD
add wave -noupdate /ethernet_v1_tb/dut/CRS_DV
add wave -noupdate /ethernet_v1_tb/dut/TX_EN
add wave -noupdate /ethernet_v1_tb/dut/TXD
add wave -noupdate /ethernet_v1_tb/dut/tx_tdata
add wave -noupdate /ethernet_v1_tb/dut/tx_tvalid
add wave -noupdate /ethernet_v1_tb/dut/tx_tready
add wave -noupdate /ethernet_v1_tb/dut/rx_tdata
add wave -noupdate /ethernet_v1_tb/dut/rx_tvalid
add wave -noupdate /ethernet_v1_tb/dut/rx_tready
add wave -noupdate /ethernet_v1_tb/dut/tx_current_state
add wave -noupdate /ethernet_v1_tb/dut/tx_next_state
add wave -noupdate -radix binary /ethernet_v1_tb/dut/send_byte
add wave -noupdate /ethernet_v1_tb/dut/byte_ptr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {27227 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 234
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {146458 ps}
