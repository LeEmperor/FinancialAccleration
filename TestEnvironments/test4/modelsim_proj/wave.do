onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /toplevel_tb/t_clk
add wave -noupdate /toplevel_tb/t_leds_red
add wave -noupdate /toplevel_tb/t_leds_green
add wave -noupdate /toplevel_tb/t_datain
add wave -noupdate /toplevel_tb/t_en
add wave -noupdate /toplevel_tb/t_switches
add wave -noupdate /toplevel_tb/dut/CLOCK_50
add wave -noupdate /toplevel_tb/dut/LEDR
add wave -noupdate /toplevel_tb/dut/KEY
add wave -noupdate -radix binary /toplevel_tb/dut/SW
add wave -noupdate /toplevel_tb/dut/wire_data
add wave -noupdate /toplevel_tb/dut/wire_valid
add wave -noupdate /toplevel_tb/dut/wire_ready
add wave -noupdate /toplevel_tb/dut/u_display/clk_hifreq
add wave -noupdate /toplevel_tb/dut/u_display/rst
add wave -noupdate /toplevel_tb/dut/u_display/data_in
add wave -noupdate /toplevel_tb/dut/u_display/valid
add wave -noupdate /toplevel_tb/dut/u_display/ready
add wave -noupdate /toplevel_tb/dut/u_display/switches
add wave -noupdate /toplevel_tb/dut/u_display/buttons
add wave -noupdate /toplevel_tb/dut/u_display/leds_green
add wave -noupdate /toplevel_tb/dut/u_display/leds_red
add wave -noupdate /toplevel_tb/dut/u_display/wire_pulse
add wave -noupdate /toplevel_tb/dut/u_display/wire_clk1
add wave -noupdate /toplevel_tb/dut/u_display/pulse_generator/clk50
add wave -noupdate /toplevel_tb/dut/u_display/pulse_generator/rst
add wave -noupdate /toplevel_tb/dut/u_display/pulse_generator/clk1
add wave -noupdate /toplevel_tb/dut/u_display/pulse_generator/pulse
add wave -noupdate -radix unsigned /toplevel_tb/dut/u_display/pulse_generator/counter
add wave -noupdate /toplevel_tb/dut/u_source/clk_hifreq
add wave -noupdate /toplevel_tb/dut/u_source/rst
add wave -noupdate /toplevel_tb/dut/u_source/data_out
add wave -noupdate /toplevel_tb/dut/u_source/valid
add wave -noupdate /toplevel_tb/dut/u_source/ready
add wave -noupdate /toplevel_tb/dut/u_source/wire_ram_data_out
add wave -noupdate /toplevel_tb/dut/u_source/counter
add wave -noupdate /toplevel_tb/dut/u_source/ram/address
add wave -noupdate /toplevel_tb/dut/u_source/ram/clock
add wave -noupdate /toplevel_tb/dut/u_source/ram/data
add wave -noupdate /toplevel_tb/dut/u_source/ram/wren
add wave -noupdate /toplevel_tb/dut/u_source/ram/q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {95569 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 367
configure wave -valuecolwidth 178
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {341232 ps}
