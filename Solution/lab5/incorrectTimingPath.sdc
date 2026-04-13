set period 1
create_clock -period $period [get_ports CLK]
#set_max_delay 0.5 -from [get_ports * -filter "direction == input"] -to [all_registers]
#set_max_delay 0.5 -to [get_ports * -filter "direction == output"] -from [all_registers]

#group_path -from [get_ports * -filter "direction == input"] -to [all_registers ] -name inputGroup
#group_path -to [get_ports * -filter "direction == output"] -from [all_registers ] -name outGroup
#group_path -from [all_registers] -to [all_registers] -name reg2reg

#set_multicycle_path 2 -from dff1/CLK -to dff2/D -setup 
#set_false_path -through mux1/A0  -through mux2/A1
#set_false_path -through mux1/S
#set_false_path -through mux2/S
#
