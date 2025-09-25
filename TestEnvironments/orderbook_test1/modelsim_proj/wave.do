onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /free_list_tb/t_clk1
add wave -noupdate /free_list_tb/clk1_en
add wave -noupdate /free_list_tb/t_rst
add wave -noupdate /free_list_tb/t_en
add wave -noupdate /free_list_tb/t_alloc_req
add wave -noupdate /free_list_tb/t_free_req
add wave -noupdate /free_list_tb/t_alloc_idx
add wave -noupdate /free_list_tb/t_rendre_idx
add wave -noupdate /free_list_tb/dut/clk
add wave -noupdate /free_list_tb/dut/rst
add wave -noupdate /free_list_tb/dut/en
add wave -noupdate /free_list_tb/dut/alloc_req
add wave -noupdate /free_list_tb/dut/alloc_slot_idx
add wave -noupdate /free_list_tb/dut/free_req
add wave -noupdate /free_list_tb/dut/free_slot_idx
add wave -noupdate /free_list_tb/dut/wire_push
add wave -noupdate /free_list_tb/dut/wire_pop
add wave -noupdate /free_list_tb/dut/wire_indata
add wave -noupdate /free_list_tb/dut/wire_outdata
add wave -noupdate /free_list_tb/dut/current_state
add wave -noupdate /free_list_tb/dut/next_state
add wave -noupdate /free_list_tb/dut/preload_counter
add wave -noupdate /free_list_tb/dut/preload_counter_next
add wave -noupdate /free_list_tb/dut/main_stack/clk
add wave -noupdate /free_list_tb/dut/main_stack/rst
add wave -noupdate /free_list_tb/dut/main_stack/en
add wave -noupdate /free_list_tb/dut/main_stack/push
add wave -noupdate /free_list_tb/dut/main_stack/pop
add wave -noupdate /free_list_tb/dut/main_stack/indata
add wave -noupdate /free_list_tb/dut/main_stack/outdata
add wave -noupdate /free_list_tb/dut/main_stack/stack_pointer
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {60667 ps} 0}
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
WaveRestoreZoom {0 ps} {180026 ps}
