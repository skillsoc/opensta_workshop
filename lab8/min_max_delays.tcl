
read_liberty -max ../lib/nangate45_lib/nangate45_slow.lib.gz
read_liberty -min ../lib/nangate45_lib/nangate45_fast.lib.gz
read_verilog ../design/gcd/gcd.v
link_design gcd
read_sdc ../design/gcd/gcd.sdc
report_timing -from [all_registers] -to [all_registers]
set_timing_derate -fast 0.9
set_timing_derate -slow 1.1
report_timing -from [all_registers] -to [all_registers]
## check the timing report
## what is the delay of the cell clkbuf_2_2__f_clk from the timing report?

