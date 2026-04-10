# =============================================================================
# File:    constraints.sdc
# Author:  OpenSTA Workshop
# Description:
#   SDC constraints for the Wallace Multiplier with Test Logic (Design 2).
#   Used in Lab 4 to demonstrate FALSE PATH constraints.
#
#   This file shows how to:
#     1. Define multiple clocks
#     2. Set false paths for test mode logic
#     3. Set false paths between asynchronous clock domains
# =============================================================================

# =============================================================================
# 1. CLOCK DEFINITIONS
# =============================================================================

# Functional clock: 100 MHz (10 ns period)
create_clock -name func_clk -period 10.0 -waveform {0 5} [get_ports i_clk]

# Scan/debug clock: 50 MHz (20 ns period)
# This is an asynchronous clock used only during DFT/debug operations
create_clock -name scan_clk -period 20.0 -waveform {0 10} [get_ports i_scan_clk]

# Clock uncertainty
set_clock_uncertainty 0.2 -setup [get_clocks func_clk]
set_clock_uncertainty 0.1 -hold  [get_clocks func_clk]
set_clock_uncertainty 0.3 -setup [get_clocks scan_clk]
set_clock_uncertainty 0.1 -hold  [get_clocks scan_clk]

# Clock transition
set_clock_transition 0.15 [get_clocks func_clk]
set_clock_transition 0.20 [get_clocks scan_clk]

# =============================================================================
# 2. INPUT / OUTPUT DELAYS
# =============================================================================

# Functional domain inputs
set_input_delay  2.0 -clock func_clk [get_ports i_a*]
set_input_delay  2.0 -clock func_clk [get_ports i_b*]
set_input_delay  0.0 -clock func_clk [get_ports i_rst_n]

# Test interface inputs (constrained to func_clk since the mux feeds func_clk regs)
set_input_delay  2.0 -clock func_clk [get_ports i_test_mode]
set_input_delay  2.0 -clock func_clk [get_ports i_test_pattern*]

# Scan domain inputs
set_input_delay  4.0 -clock scan_clk [get_ports i_scan_en]

# Functional domain outputs
set_output_delay 2.0 -clock func_clk [get_ports o_product*]

# Scan domain outputs
set_output_delay 4.0 -clock scan_clk [get_ports o_scan_data*]

# =============================================================================
# 3. LOAD AND TRANSITION
# =============================================================================
set_load -pin_load 0.05 [all_outputs]
set_input_transition 0.2 [all_inputs]

# =============================================================================
# 4. FALSE PATH CONSTRAINTS
# =============================================================================
# These are the key constraints for Lab 4!

# --- False Path 1: Test Mode MUX ---
# The i_test_mode signal is a static configuration pin. It is set once
# before the chip starts operating and never changes during normal
# functional operation. Therefore, any timing path that passes through
# i_test_mode does not need to be analyzed for setup/hold timing.
#
# Without this constraint, the STA tool would analyze paths like:
#   i_test_mode -> mux -> o_product register
# and might report false violations or pessimistic slack.
set_false_path -from [get_ports i_test_mode]

# Similarly, the test pattern input is only used during test mode,
# never during normal operation.
set_false_path -from [get_ports i_test_pattern*]

# --- False Path 2: Cross Clock Domain ---
# The functional clock (func_clk) and the scan clock (scan_clk) are
# asynchronous to each other. They are never active at the same time
# in normal operation. The STA tool must NOT analyze timing paths
# that cross between these two clock domains.
#
# Without this constraint, the tool would try to check setup/hold
# relationships between func_clk flip-flops and scan_clk flip-flops,
# which would produce meaningless (and likely failing) results.
set_false_path -from [get_clocks func_clk] -to [get_clocks scan_clk]
set_false_path -from [get_clocks scan_clk] -to [get_clocks func_clk]
