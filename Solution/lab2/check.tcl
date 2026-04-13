read_liberty ../lib/sky130hd_libs/sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog simpleDff.v
link_design dff_with_buffer
create_clock -name clk -period 10 {clk}
#set_input_delay -clock clk 0 {in1 in2}
report_checks


