# Compile Design

do system.do

vlog -novopt -work work tb.v

vsim -t 1ns -L cycloneiii_ver -L altera_ver -L altera_mf_ver -L lpm_ver -L sgate_ver -novopt tb

# Set Stimulus

do wave.do

# Run simulation

 run -all

view wave
wave zoomfull