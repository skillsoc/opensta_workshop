set period 1
create_clock -period $period [get_ports CLK]
create_clock -period [expr $period * 3 ] [get_ports Test_CLK]
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
#set_false_path -from CLK -to Test_CLK
#set_case_analysis 0 clk_mux/S
#set_propagated_clock [get_clocks *] 
#create_generated_clock -name gCLK -source [get_ports CLK] -divide_by 2 clk_mux/X
#set_multicycle_path 2 -from dff1/CLK -to dff2/D -setup 

#clk_div_ff/Q

