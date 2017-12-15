onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/uut/video_frame_valid
add wave -noupdate /tb/uut/video_line_valid
add wave -noupdate /tb/uut/video_data_valid
add wave -noupdate -radix unsigned /tb/uut/video_data_in
add wave -noupdate -radix hexadecimal /tb/uut/video_address
add wave -noupdate /tb/uut/video_data_ready
add wave -noupdate -radix unsigned /tb/uut/video_data_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10450915 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 175
configure wave -valuecolwidth 115
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
WaveRestoreZoom {86081825 ns} {108828321 ns}
