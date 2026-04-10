# =============================================================================
# File:    run_sta.tcl
# Author:  OpenSTA Workshop
# Description:
#   OpenSTA Tcl script for Design 2 analysis (Lab 4).
#   Demonstrates the effect of false path constraints.
#
# Usage:
#   sta run_sta.tcl
# =============================================================================

puts "============================================"
puts " OpenSTA Workshop - Design 2 Analysis"
puts " Wallace Multiplier with Test Logic"
puts " Lab 4: False Path Constraints"
puts "============================================\n"

# ---- Read library and design ----
puts "Reading Liberty file..."
read_liberty ../../liberty_files/workshop_typical.lib

puts "Reading Verilog netlist..."
read_verilog wallace_multiplier_with_test.v

puts "Linking design..."
link_design wallace_multiplier_with_test

# ===========================================================================
# PART A: Analysis WITHOUT false path constraints
# ===========================================================================
puts "\n============================================"
puts " PART A: WITHOUT False Path Constraints"
puts " (Applying only basic clock constraints)"
puts "============================================\n"

# Apply only basic constraints (no false paths)
create_clock -name func_clk -period 10.0 -waveform {0 5} [get_ports i_clk]
create_clock -name scan_clk -period 20.0 -waveform {0 10} [get_ports i_scan_clk]
set_clock_uncertainty 0.2 -setup [get_clocks func_clk]
set_clock_uncertainty 0.1 -hold  [get_clocks func_clk]
set_clock_uncertainty 0.3 -setup [get_clocks scan_clk]
set_clock_uncertainty 0.1 -hold  [get_clocks scan_clk]
set_input_delay  2.0 -clock func_clk [get_ports i_a*]
set_input_delay  2.0 -clock func_clk [get_ports i_b*]
set_input_delay  0.0 -clock func_clk [get_ports i_rst_n]
set_input_delay  2.0 -clock func_clk [get_ports i_test_mode]
set_input_delay  2.0 -clock func_clk [get_ports i_test_pattern*]
set_input_delay  4.0 -clock scan_clk [get_ports i_scan_en]
set_output_delay 2.0 -clock func_clk [get_ports o_product*]
set_output_delay 4.0 -clock scan_clk [get_ports o_scan_data*]
set_load -pin_load 0.05 [all_outputs]
set_input_transition 0.2 [all_inputs]

puts "--- Setup Timing (no false paths) ---"
report_checks -path_delay max -format full

puts "\n--- Cross-Domain Paths (no false paths) ---"
report_checks -path_delay max -format full -from [get_clocks func_clk] -to [get_clocks scan_clk]

# ===========================================================================
# PART B: Analysis WITH false path constraints
# ===========================================================================
puts "\n\n============================================"
puts " PART B: WITH False Path Constraints"
puts " (Applying complete SDC from constraints.sdc)"
puts "============================================\n"

# Clear previous constraints and re-read with false paths
# (In practice, we just add the false path commands)
set_false_path -from [get_ports i_test_mode]
set_false_path -from [get_ports i_test_pattern*]
set_false_path -from [get_clocks func_clk] -to [get_clocks scan_clk]
set_false_path -from [get_clocks scan_clk] -to [get_clocks func_clk]

puts "--- Setup Timing (with false paths) ---"
report_checks -path_delay max -format full

puts "\n--- Hold Timing (with false paths) ---"
report_checks -path_delay min -format full

puts "\n--- Verify: Cross-Domain Paths Should Be Empty ---"
report_checks -path_delay max -format full -from [get_clocks func_clk] -to [get_clocks scan_clk]

puts "\n============================================"
puts " Compare Part A vs Part B:"
puts "  - Notice the cross-domain paths disappear"
puts "  - The critical path changes (test mux removed)"
puts "  - Slack values may improve"
puts "============================================\n"

exit
