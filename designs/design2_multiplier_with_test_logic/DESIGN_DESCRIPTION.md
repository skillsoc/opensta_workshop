# Design 2: 8-bit Wallace Tree Multiplier with Test Logic

## Overview

This design extends the basic Wallace Tree Multiplier (Design 1) with **test and debug logic** that creates realistic scenarios requiring **false path constraints** in Static Timing Analysis.

## Architecture

```
  i_a, i_b                 i_test_pattern    i_scan_clk
     │                          │                 │
  ┌───▼───┐                     │              ┌───▼───┐
  │ Input │                     │              │ Scan  │
  │ Regs  │                     │              │ Reg   │ ← i_scan_clk domain
  └───┬───┘                     │              └───┬───┘
      │                         │                  │
  ┌───▼────────┐                │              o_scan_data
  │ Wallace    │                │
  │ Tree +Final├──────┐         │
  │ Adder      │      │         │
  └────────────┘      │         │
                    ┌───▼──────▼─┐
  i_test_mode ────►│  TEST MUX   │ ← FALSE PATH source
                    └─────┬──────┘
                          │
                    ┌─────▼─────┐
                    │ Output Reg│
                    └─────┬─────┘
                          │
                      o_product
```

## Why False Paths Are Needed

This design has **two types of false paths**:

### 1. Test Mode MUX (Static Configuration)

- **Signal**: `i_test_mode`, `i_test_pattern[15:0]`
- **Reason**: `i_test_mode` is a static signal set during manufacturing test. It does **not toggle** during normal chip operation. Without a false path constraint, the STA tool would analyze timing paths through the test mux and potentially:
  - Report pessimistic timing on the critical path
  - Waste optimization effort on a path that doesn't matter in practice
- **SDC Command**: `set_false_path -from [get_ports i_test_mode]`

### 2. Asynchronous Clock Domain Crossing

- **Clocks**: `func_clk` (i_clk, 100 MHz) and `scan_clk` (i_scan_clk, 50 MHz)
- **Reason**: These two clocks are **asynchronous**  they have no defined phase relationship. The scan clock is only used during DFT/debug, never simultaneously with the functional clock. Without false path constraints, the STA tool would:
  - Try to compute setup/hold relationships between the two domains
  - Report meaningless violations (or false passes)
  - Potentially cause over-constraining of the design
- **SDC Commands**:
  ```tcl
  set_false_path -from [get_clocks func_clk] -to [get_clocks scan_clk]
  set_false_path -from [get_clocks scan_clk] -to [get_clocks func_clk]
  ```

## Port Description

| Port | Direction | Width | Clock Domain | Description |
|------|-----------|-------|-------------|-------------|
| `i_clk` | Input | 1 |  | Functional clock |
| `i_rst_n` | Input | 1 | func_clk | Active-low reset |
| `i_a` | Input | 8 | func_clk | Multiplicand |
| `i_b` | Input | 8 | func_clk | Multiplier |
| `o_product` | Output | 16 | func_clk | Product |
| `i_test_mode` | Input | 1 | static | Test mode select |
| `i_test_pattern` | Input | 16 | static | Test pattern |
| `i_scan_clk` | Input | 1 |  | Scan/debug clock |
| `i_scan_en` | Input | 1 | scan_clk | Scan enable |
| `o_scan_data` | Output | 16 | scan_clk | Debug data |

## Lab 4 Exercise

Students will:
1. Run STA **without** false path constraints and observe spurious violations
2. Add false path constraints and re-run STA
3. Compare the timing reports to understand the impact
