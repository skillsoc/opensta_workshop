# Design 1 — Simple Wallace Tree Multiplier

This directory contains the RTL and supporting files for an 8-bit Wallace Tree Multiplier used in **Labs 1, 2, and 3** of the OpenSTA workshop.

## Files

| File | Description |
|------|-------------|
| `wallace_multiplier.v` | Synthesizable Verilog RTL |
| `wallace_multiplier_tb.v` | Testbench (Icarus Verilog compatible) |
| `constraints.sdc` | SDC timing constraints (100 MHz clock) |
| `run_sta.tcl` | OpenSTA Tcl script for timing analysis |
| `DESIGN_DESCRIPTION.md` | One-page design description |

## Quick Start Functional Simulation

If you have Icarus Verilog installed:

```bash
# Compile
iverilog -o tb wallace_multiplier.v wallace_multiplier_tb.v

# Run
vvp tb

# View waveforms (optional, requires GTKWave)
gtkwave wallace_multiplier.vcd &
```

## Quick Start Timing Analysis with OpenSTA

```bash
# From this directory, inside the Docker container:
sta run_sta.tcl
```

This will:
1. Read the Liberty technology library
2. Read the Verilog netlist
3. Link the design
4. Apply SDC constraints
5. Report setup and hold timing paths

## What to Look For

- **Setup timing report**: Shows the critical (longest) path through the multiplier.
- **Hold timing report**: Shows the shortest path check for hold violations.
- **Slack values**: Positive slack = timing met. Negative slack = violation.

See `DESIGN_DESCRIPTION.md` for a detailed explanation of the architecture.
