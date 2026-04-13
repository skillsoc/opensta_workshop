set period 5
create_clock -period $period [get_ports clk]
set_max_delay 0.5 -from [get_ports * -filter "direction == input"] -to [all_registers]
set_max_delay 0.5 -to [get_ports * -filter "direction == output"] -from [all_registers]

#group_path -from [get_ports * -filter "direction == input"] -to [all_registers ] -name inputGroup
#group_path -to [get_ports * -filter "direction == output"] -from [all_registers ] -name outGroup
#group_path -from [all_registers] -to [all_registers] -name reg2reg
