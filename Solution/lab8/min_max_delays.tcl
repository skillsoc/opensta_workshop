read_liberty -max ../lib/nangate45_lib/nangate45_slow.lib.gz
read_liberty -min ../lib/nangate45_lib/nangate45_fast.lib.gz
read_verilog ../design/gcd/gcd.v
link_design gcd
read_sdc ../design/gcd/gcd.sdc

