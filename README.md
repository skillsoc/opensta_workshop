# OpenSTA Workshop — Phase 1 Materials

A hands-on 2-day workshop for learning **Static Timing Analysis (STA)** using the open-source **OpenSTA** tool, built around an 8-bit Wallace Tree Multiplier design.

## Directory Structure

```
opensta_workshop/
├── README.md                          ← You are here
├── designs/
│   ├── design1_simple_multiplier/     ← Labs 1-3: Basic STA
│   │   ├── wallace_multiplier.v       ← RTL (Verilog netlist)
│   │   ├── wallace_multiplier_tb.v    ← Testbench
│   │   ├── constraints.sdc            ← Timing constraints
│   │   ├── run_sta.tcl                ← OpenSTA analysis script
│   │   ├── DESIGN_DESCRIPTION.md      ← Architecture documentation
│   │   └── README.md                  ← Design-specific instructions
│   │
│   └── design2_multiplier_with_test_logic/  ← Lab 4: False Paths
│       ├── wallace_multiplier_with_test.v   ← RTL + test/scan logic
│       ├── wallace_multiplier_with_test_tb.v
│       ├── constraints.sdc                  ← SDC with false paths
│       ├── run_sta.tcl                      ← Comparison script
│       ├── DESIGN_DESCRIPTION.md            ← False path explanation
│       └── README.md
│
├── liberty_files/
│   └── workshop_typical.lib           ← Technology library for STA
│
└── docker/
    ├── Dockerfile.linux               ← Docker image for Linux
    ├── Dockerfile.wsl2                ← Docker image for Windows WSL2
    ├── docker-compose.yml             ← Docker Compose config
    ├── build.sh                       ← Build script
    ├── run.sh                         ← Run script
    └── README.md                      ← Docker setup instructions
```

## Quick Start

### 1. Build the Docker Environment

```bash
cd docker
chmod +x build.sh run.sh
./build.sh       # Takes ~5-10 minutes (builds OpenSTA from source)
```

### 2. Start the Container

```bash
./run.sh
```

This drops you into a shell with OpenSTA and Icarus Verilog ready to use.

### 3. Run Your First Timing Analysis

```bash
# Inside the container:
cd /workspace/designs/design1_simple_multiplier
sta run_sta.tcl
```

### 4. Run Functional Simulation (Optional)

```bash
cd /workspace/designs/design1_simple_multiplier
iverilog -o tb wallace_multiplier.v wallace_multiplier_tb.v
vvp tb
```

## Workshop Labs Overview

| Lab | Design | Topic |
|-----|--------|-------|
| Lab 1 | Design 1 | Introduction to OpenSTA reading netlists, libraries, and constraints |
| Lab 2 | Design 1 | Understanding timing reports arrival time, required time, slack |
| Lab 3 | Design 1 | Setup and hold analysis finding and interpreting violations |
| Lab 4 | Design 2 | False path constraints test mux and cross-domain paths |

## Design Descriptions

### Design 1: Simple Wallace Tree Multiplier
An 8-bit unsigned multiplier with registered inputs and outputs. Uses carry-save adder (CSA) reduction stages followed by a ripple-carry final adder. Single clock domain — ideal for learning basic STA concepts.

### Design 2: Multiplier with Test Logic
Extends Design 1 with:
- **Test mode MUX**: Static configuration signal that selects between functional output and a test pattern. Creates a false path scenario (static signal never toggles in normal operation).
- **Scan/debug register**: Operates on a separate asynchronous clock (`i_scan_clk`). Creates cross-clock-domain false paths.

## Technology Library

The `workshop_typical.lib` file is a simplified Liberty library modeling a fictional 45nm process. It includes:
- Basic logic cells: BUF, INV, AND2, OR2, XOR2, MUX2
- Sequential cells: DFF, DFFR (with async reset)
- 2x2 lookup tables for delay characterization
- Setup/hold timing constraints for flip-flops

## Prerequisites

- **Docker** (Docker Desktop for Windows/Mac, or Docker Engine for Linux)
- Basic familiarity with digital logic concepts
- A text editor for viewing/editing files

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `sta: command not found` | Ensure you're inside the Docker container |
| Docker build fails | Check internet connection; OpenSTA is cloned from GitHub |
| Permission denied on scripts | Run `chmod +x docker/build.sh docker/run.sh` |


