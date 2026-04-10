# Design 1: 8-bit Wallace Tree Multiplier

## Overview

This design implements an **8-bit unsigned Wallace Tree Multiplier** in Verilog. It takes two 8-bit inputs (`i_a` and `i_b`) and produces a 16-bit product (`o_product`). The design is fully synchronous, with registered inputs and outputs clocked by `i_clk`.

## Architecture

The multiplier consists of five stages:

```
  i_a[7:0], i_b[7:0]
        │
  ┌─────▼─────┐
  │ Input Regs│  ← Stage 1: Register inputs on clock edge
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Partial   │  ← Stage 2: 64 AND gates generate partial products
  │ Products  │
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Wallace   │  ← Stage 3: Carry-Save Adder tree reduces 8 rows
  │ Tree (CSA)│     to 2 rows using Full Adders
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Final Add │  ← Stage 4: Ripple-carry adder produces final sum
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Output Reg│  ← Stage 5: Register output on clock edge
  └─────┬─────┘
        │
    o_product[15:0]
```

### Key Components

| Component | Count | Purpose |
|-----------|-------|---------|
| AND gates | 64 | Generate partial products (a[j] & b[i]) |
| Full Adders (FA) | 80 | Reduce partial products in CSA stages + final add |
| Flip-Flops | 32 | 16 input bits + 16 output bits |

### Timing Characteristics

- **Combinational depth**: The longest path passes through 4 CSA stages plus a 16-bit ripple carry adder — making it interesting for timing analysis.
- **Single clock domain**: All registers use `i_clk`, simplifying the constraint setup.
- **Critical path**: Runs from the input registers through the Wallace tree reduction and final adder to the output registers.

## Port Description

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `i_clk` | Input | 1 | System clock |
| `i_rst_n` | Input | 1 | Active-low synchronous reset |
| `i_a` | Input | 8 | Multiplicand |
| `i_b` | Input | 8 | Multiplier |
| `o_product` | Output | 16 | Unsigned product (A × B) |

## Files

| File | Description |
|------|-------------|
| `wallace_multiplier.v` | RTL design (synthesizable Verilog) |
| `wallace_multiplier_tb.v` | Testbench with directed + random tests |
| `constraints.sdc` | Timing constraints for OpenSTA |
| `run_sta.tcl` | OpenSTA analysis script |

## How to Run Timing Analysis

```bash
# From inside the Docker container:
cd /workspace/designs/design1_simple_multiplier
sta run_sta.tcl
```
