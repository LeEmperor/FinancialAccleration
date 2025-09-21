onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /orderbook_tb/t_clk
add wave -noupdate /orderbook_tb/t_rst
add wave -noupdate /orderbook_tb/t_en
add wave -noupdate /orderbook_tb/clk_en
add wave -noupdate /orderbook_tb/t_dataout
add wave -noupdate /orderbook_tb/t_bid1price
add wave -noupdate -radix binary /orderbook_tb/t_occupiedmask
add wave -noupdate /orderbook_tb/t_indata
add wave -noupdate /orderbook_tb/t_valid
add wave -noupdate /orderbook_tb/dut/clk_hifreq
add wave -noupdate /orderbook_tb/dut/rst
add wave -noupdate /orderbook_tb/dut/en
add wave -noupdate /orderbook_tb/dut/in_data
add wave -noupdate /orderbook_tb/dut/valid
add wave -noupdate /orderbook_tb/dut/rdy
add wave -noupdate -radix decimal /orderbook_tb/dut/new_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid1_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid2_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid3_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid4_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid5_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid6_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid7_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid8_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid9_price
add wave -noupdate -group {bid price regs} /orderbook_tb/dut/bid10_price
add wave -noupdate -radix binary /orderbook_tb/dut/occupied_mask
add wave -noupdate -radix unsigned /orderbook_tb/dut/insertion_index
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {27309 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {144173 ps}
