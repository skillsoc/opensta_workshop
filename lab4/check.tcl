read_liberty ../lib/sky130hd_libs/sky130_fd_custom_tt_025C_1v80.lib

read_verilog highComboDelay.v
link_design flop_buffer_netlist
read_sdc highComboDelay.sdc


