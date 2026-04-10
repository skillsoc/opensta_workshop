# =============================================================================
# File:    run_sta.tcl
# Author:  OpenSTA Workshop
# Description:
#   OpenSTA Tcl script for running timing analysis on the Wallace Tree
#   Multiplier design. This is the main script used in Labs 1-3.
#
# Usage:
#   sta run_sta.tcl
# =============================================================================

puts "============================================"
puts " OpenSTA Workshop - Design 1 Analysis"
puts " 8-bit Wallace Tree Multiplier"
puts "============================================\n"

# ---- Step 1: Read the technology library ----
puts "Step 1: Reading Liberty file..."
read_liberty ../../liberty_files/workshop_typical.lib
puts "  Done.\n"

# ---- Step 2: Read the design netlist ----
puts "Step 2: Reading Verilog netlist..."
read_verilog wallace_multiplier.v
puts "  Done.\n"

# ---- Step 3: Link the design ----
puts "Step 3: Linking design..."
link_design wallace_multiplier
puts "  Done.\n"

# ---- Step 4: Read timing constraints ----
puts "Step 4: Reading SDC constraints..."
read_sdc constraints.sdc
puts "  Done.\n"

# ---- Step 5: Report Setup Timing (max delay) ----
puts "\n============================================"
puts " SETUP TIMING REPORT (Worst Path)"
puts "============================================"
report_checks -path_delay max -format full

# ---- Step 6: Report Hold Timing (min delay) ----
puts "\n============================================"
puts " HOLD TIMING REPORT (Worst Path)"
puts "============================================"
report_checks -path_delay min -format full

# ---- Step 7: Report all setup violations (if any) ----
puts "\n============================================"
puts " ALL SETUP VIOLATIONS"
puts "============================================"
report_checks -path_delay max -format full -slack_max 0

# ---- Step 8: Report design statistics ----
puts "\n============================================"
puts " DESIGN STATISTICS"
puts "============================================"
report_design_area

puts "\n============================================"
puts " Analysis Complete"
puts "============================================\n"

exit
