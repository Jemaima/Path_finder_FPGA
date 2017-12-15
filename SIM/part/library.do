set QUARTUS_INSTALL_DIR "C:/altera/13.1/quartus/"

vlib ./libraries/
vlib ./libraries/work/
vlib ./libraries/altera_ver/
vlib ./libraries/lpm_ver/ 
vlib ./libraries/sgate_ver/
vlib ./libraries/altera_mf_ver/
vlib ./libraries/altera_lnsim_ver/
vlib ./libraries/cycloneiii_ver/     
 
vmap altera_ver            ./libraries/altera_ver/
vmap lpm_ver               ./libraries/lpm_ver/
vmap sgate_ver             ./libraries/sgate_ver/ 
vmap altera_mf_ver         ./libraries/altera_mf_ver/
vmap altera_lnsim_ver      ./libraries/altera_lnsim_ver/
vmap cycloneiii_ver        ./libraries/cycloneiii_ver/
vmap work 				   ./libraries/work/

vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                     -work altera_ver           
vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                              -work lpm_ver              
vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                 -work sgate_ver            
vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                             -work altera_mf_ver        
vlog -sv "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                         -work altera_lnsim_ver            
vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/cycloneiii_atoms.v"                      -work cycloneiii_ver         

  