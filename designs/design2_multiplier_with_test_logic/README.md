# Design 2 — Wallace Multiplier with Test Logic

This directory contains the RTL for an 8-bit Wallace Tree Multiplier with added test/debug logic, used in **Lab 4** of the OpenSTA workshop.

## Files

| File | Description |
|------|-------------|
| `wallace_multiplier_with_test.v` | RTL with test mux and scan register |
| `wallace_multiplier_with_test_tb.v` | Testbench (functional + test mode + scan) |
| `constraints.sdc` | SDC with false path constraints |
| `run_sta.tcl` | OpenSTA script comparing with/without false paths |
| `DESIGN_DESCRIPTION.md` | Design description with false path explanation |

## Quick Start — Simulation

```bash
iverilog -o tb wallace_multiplier_with_test.v wallace_multiplier_with_test_tb.v
vvp tb
```

## Quick Start — Timing Analysis

```bash
sta run_sta.tcl
```

The script runs timing analysis in two passes:
1. **Part A**: Without false paths — observe cross-domain paths and test-mux paths
2. **Part B**: With false paths — observe how those paths disappear

## Key Learning Points

- **`set_false_path -from`**: Removes timing analysis from a specific source
- **`set_false_path -from [clock] -to [clock]`**: Removes cross-domain analysis
- **Impact on slack**: False paths can change which path is critical

See `DESIGN_DESCRIPTION.md` for detailed explanation.
