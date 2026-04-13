read_liberty ../lib/sky130hd_libs/sky130_fd_custom_tt_025C_1v80.lib

read_verilog incorrectTimingPath.v
link_design two_stage_dff_with_mux
read_sdc incorrectTimingPath.sdc


