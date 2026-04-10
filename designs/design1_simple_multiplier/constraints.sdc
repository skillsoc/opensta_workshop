# =============================================================================
# File:    constraints.sdc
# Author:  OpenSTA Workshop
# Description:
#   SDC (Synopsys Design Constraints) file for the 8-bit Wallace Tree
#   Multiplier. Used in Labs 1-3 for basic timing analysis with OpenSTA.
#
#   This file defines:
#     - Clock definition (period, waveform)
#     - Input/output delay constraints
#     - Output load
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Define the Clock
# -----------------------------------------------------------------------------
# Create a clock named "clk" on port i_clk with a 10 ns period (100 MHz).
# The waveform rises at 0 ns and falls at 5 ns (50% duty cycle).
create_clock -name clk -period 10.0 -waveform {0 5} [get_ports i_clk]

# Add clock uncertainty (jitter + skew) of 0.2 ns for setup analysis
set_clock_uncertainty 0.2 -setup [get_clocks clk]
# Add clock uncertainty of 0.1 ns for hold analysis
set_clock_uncertainty 0.1 -hold  [get_clocks clk]

# Model clock transition (slew rate) at the clock port
set_clock_transition 0.15 [get_clocks clk]

# -----------------------------------------------------------------------------
# 2. Input Delay Constraints
# -----------------------------------------------------------------------------
# These tell OpenSTA when data arrives at input ports relative to the clock.
# A value of 2.0 ns means data arrives 2.0 ns after the clock edge.
set_input_delay  2.0 -clock clk [get_ports i_a*]
set_input_delay  2.0 -clock clk [get_ports i_b*]
set_input_delay  0.0 -clock clk [get_ports i_rst_n]

# -----------------------------------------------------------------------------
# 3. Output Delay Constraints
# -----------------------------------------------------------------------------
# These tell OpenSTA when data must be stable at output ports before the
# next clock edge. A value of 2.0 ns means data must arrive at least
# 2.0 ns before the capturing clock edge.
set_output_delay 2.0 -clock clk [get_ports o_product*]

# -----------------------------------------------------------------------------
# 4. Output Load
# -----------------------------------------------------------------------------
# Apply a capacitive load of 0.05 pF on all output ports.
# This affects the delay of the last gate driving the output.
set_load -pin_load 0.05 [all_outputs]

# -----------------------------------------------------------------------------
# 5. Input Transition
# -----------------------------------------------------------------------------
# Set the input slew rate to 0.2 ns for all input signals.
set_input_transition 0.2 [all_inputs]
