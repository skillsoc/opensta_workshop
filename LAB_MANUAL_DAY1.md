# OpenSTA Workshop — Day 1 Lab Manual

## 8-bit Wallace Tree Multiplier: A Hands-On Introduction to Static Timing Analysis

---

**Workshop Version:** 1.0  
**Target Audience:** Beginners with little to no STA knowledge  
**Prerequisites:** Basic digital logic knowledge, Docker environment set up per the Installation Guide  
**Design Files:** `/workspace/designs/` (inside Docker container)

---

## Table of Contents

1. [Lab 1: Introduction to OpenSTA and Basic Timing Reports](#lab-1-introduction-to-opensta-and-basic-timing-reports)
2. [Lab 2: Cell Delay and Net Delay Analysis](#lab-2-cell-delay-and-net-delay-analysis)
3. [Lab 3: Setup and Hold Time Analysis](#lab-3-setup-and-hold-time-analysis)
4. [Lab 4: False Paths — Concept and Implementation](#lab-4-false-paths--concept-and-implementation)

---

# Lab 1: Introduction to OpenSTA and Basic Timing Reports

## 1.1 Objectives

By the end of this lab you will be able to:

- Launch OpenSTA inside the Docker environment
- Load a design (Verilog netlist + Liberty library + SDC constraints)
- Run a basic timing analysis
- Read and interpret the structure of an OpenSTA timing report
- Identify the critical path of a design

## 1.2 Background Theory

### What Is Static Timing Analysis (STA)?

Static Timing Analysis is a method used to verify the timing performance of a digital circuit **without running a simulation**. Instead of applying test vectors and watching waveforms, STA mathematically calculates the signal propagation delay along **every possible path** in the design and checks whether timing constraints are met.

**Key advantages of STA over simulation:**

| Feature | Simulation | STA |
|---------|-----------|-----|
| Coverage | Only tested vectors | All paths (exhaustive) |
| Speed | Slow (vector-dependent) | Fast (mathematical) |
| Completeness | May miss corner cases | Guarantees all paths checked |

### Key Terminology

Before we begin, let's define the terms you'll encounter throughout this workshop:

```
  ┌──────────┐                                    ┌──────────┐
  │          │    Combinational Logic Path         │          │
  │  Launch  │──── Gate ── Wire ── Gate ── Wire ──►│ Capture  │
  │  Flip-   │                                     │  Flip-   │
  │  Flop    │                                     │  Flop    │
  │          │                                     │          │
  └────┬─────┘                                     └────┬─────┘
       │                                                │
       ▼                                                ▼
    i_clk                                            i_clk
```

| Term | Definition |
|------|-----------|
| **Timing Path** | A route from a *startpoint* (flip-flop clock pin or input port) to an *endpoint* (flip-flop data pin or output port) through combinational logic. |
| **Startpoint** | Where a timing path begins — typically a flip-flop's clock pin (data is *launched*) or a primary input port. |
| **Endpoint** | Where a timing path ends — typically a flip-flop's data pin (data is *captured*) or a primary output port. |
| **Critical Path** | The timing path with the **worst (smallest) slack** — the path that limits the maximum operating frequency. |
| **Slack** | The timing margin: `Slack = Required Arrival Time − Actual Arrival Time`. Positive = good, negative = violation. |
| **Clock Period** | The time between two consecutive rising edges of the clock. Our design uses 10 ns (100 MHz). |
| **Liberty File (.lib)** | Technology library containing timing characteristics (delays, setup/hold times) for each cell type. |
| **SDC File (.sdc)** | Synopsys Design Constraints — defines clocks, input/output delays, and timing exceptions. |

### The Design Under Test: 8-bit Wallace Tree Multiplier

Our design is an 8-bit unsigned multiplier that computes `o_product = i_a × i_b`. It has five pipeline stages:

```
  i_a[7:0], i_b[7:0]
        │
  ┌─────▼─────┐
  │ Input Regs │  ← Stage 1: Register inputs on clock edge
  │ (16 FFs)   │
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Partial    │  ← Stage 2: 64 AND gates generate partial products
  │ Products   │
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Wallace    │  ← Stage 3: Carry-Save Adder tree reduces 8 rows
  │ Tree (CSA) │     to 2 rows using Full Adders (4 CSA stages)
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Final Add  │  ← Stage 4: 16-bit Ripple-Carry Adder
  └─────┬─────┘
        │
  ┌─────▼─────┐
  │ Output Reg │  ← Stage 5: Register output on clock edge
  │ (16 FFs)   │
  └─────┬─────┘
        │
    o_product[15:0]
```

The **critical path** runs from the input registers, through the partial product AND gates, through all 4 CSA reduction stages, through the 16-bit ripple-carry adder, and into the output registers. This is a deep combinational path — perfect for learning STA!

## 1.3 Files Used in This Lab

| File | Path (inside Docker) | Purpose |
|------|---------------------|---------|
| Verilog Netlist | `designs/design1_simple_multiplier/wallace_multiplier.v` | The circuit design |
| SDC Constraints | `designs/design1_simple_multiplier/constraints.sdc` | Timing constraints |
| Liberty Library | `liberty_files/workshop_typical.lib` | Cell timing data |
| STA Script | `designs/design1_simple_multiplier/run_sta.tcl` | Pre-written analysis script |

## 1.4 Procedure

### Step 1: Launch the Docker Container

Open a terminal and start the OpenSTA Docker environment:

```bash
cd opensta_workshop
docker run -it -v $(pwd):/workspace opensta_workshop
```

You should see a Linux shell prompt inside the container. Verify OpenSTA is available:

```bash
sta -version
```

### Step 2: Navigate to the Design Directory

```bash
cd /workspace/designs/design1_simple_multiplier
```

List the files to confirm everything is in place:

```bash
ls -la
```

You should see: `wallace_multiplier.v`, `constraints.sdc`, `run_sta.tcl`

### Step 3: Examine the Constraints File

Before running the analysis, let's understand what constraints we're applying. Open the SDC file:

```bash
cat constraints.sdc
```

Key constraints defined:

```tcl
# Clock: 100 MHz (10 ns period) on port i_clk
create_clock -name clk -period 10.0 -waveform {0 5} [get_ports i_clk]

# Clock uncertainty: 0.2 ns for setup, 0.1 ns for hold
set_clock_uncertainty 0.2 -setup [get_clocks clk]
set_clock_uncertainty 0.1 -hold  [get_clocks clk]

# Input data arrives 2.0 ns after clock edge
set_input_delay  2.0 -clock clk [get_ports i_a*]
set_input_delay  2.0 -clock clk [get_ports i_b*]

# Output data must be ready 2.0 ns before next clock edge
set_output_delay 2.0 -clock clk [get_ports o_product*]

# Output load: 0.05 pF on all outputs
set_load -pin_load 0.05 [all_outputs]
```

> **💡 Think About It:** The clock period is 10 ns. Input delay is 2 ns and output delay is 2 ns. How much time does the combinational logic have to compute the result?
>
> *Answer: 10 − 2 − 2 − 0.2 (setup uncertainty) = 5.8 ns for the combinational logic, minus the flip-flop setup time and clock-to-Q delay.*

### Step 4: Run the Pre-Written STA Script

Execute the full analysis:

```bash
sta run_sta.tcl
```

This script performs the following steps automatically:

```tcl
# 1. Read the technology library
read_liberty ../../liberty_files/workshop_typical.lib

# 2. Read the design netlist
read_verilog wallace_multiplier.v

# 3. Link the design to the library
link_design wallace_multiplier

# 4. Apply timing constraints
read_sdc constraints.sdc

# 5. Report setup timing (worst path)
report_checks -path_delay max -format full

# 6. Report hold timing (worst path)
report_checks -path_delay min -format full
```

### Step 5: Run Commands Interactively (Recommended for Learning)

Instead of running the script, let's do it step by step. Launch OpenSTA in interactive mode:

```bash
sta
```

You'll see the OpenSTA Tcl prompt. Now enter each command one at a time:

```tcl
# Step 5a: Read the Liberty library
read_liberty ../../liberty_files/workshop_typical.lib
```

```tcl
# Step 5b: Read the Verilog netlist
read_verilog wallace_multiplier.v
```

```tcl
# Step 5c: Link the design
link_design wallace_multiplier
```

```tcl
# Step 5d: Read the SDC constraints
read_sdc constraints.sdc
```

```tcl
# Step 5e: Generate the setup timing report (critical path)
report_checks -path_delay max -format full
```

> **📝 Save the output!** Copy the timing report output — you'll need it for the exercises.

## 1.5 Understanding the Timing Report

The `report_checks` command produces a detailed report. Here is an annotated breakdown of a typical OpenSTA timing report:

```
Startpoint: a_reg[3]                          ← (1) Where the path BEGINS
             (rising edge-triggered flip-flop clocked by clk)
Endpoint:   o_product[15]                     ← (2) Where the path ENDS
             (rising edge-triggered flip-flop clocked by clk)
Path Group: clk                               ← (3) Clock domain
Path Type:  max                               ← (4) Setup check (max delay)

  Delay    Time   Description
---------------------------------------------------------
   0.00    0.00   clock clk (rise edge)       ← (5) Clock launches at T=0
   0.00    0.00   clock network delay (ideal)
   0.00    0.00 ^ a_reg[3]/CLK (DFFR)        ← (6) Clock arrives at launch FF
   0.10    0.10 ^ a_reg[3]/Q (DFFR)          ← (7) Clock-to-Q delay of launch FF
   0.06    0.16 ^ gen_pp_row[3].../Y (AND2)  ← (8) Partial product AND gate
   0.08    0.24 ^ gen_csa1a[3].../sum (FA)   ← (9) CSA Stage 1 full adder
   0.08    0.32 ^ gen_csa2a[3].../sum (FA)   ← (10) CSA Stage 2
   0.08    0.40 ^ gen_csa3[3].../sum (FA)    ← (11) CSA Stage 3
   0.08    0.48 ^ gen_csa4[3].../sum (FA)    ← (12) CSA Stage 4
   ...      ...   (ripple carry chain)        ← (13) Final adder stages
   0.08    1.44 ^ gen_final_add[15].../sum    ← (14) Last bit of final adder
           1.44   data arrival time           ← (15) TOTAL DATA ARRIVAL TIME

   10.00  10.00   clock clk (rise edge)       ← (16) Capture clock edge
   0.00   10.00   clock network delay (ideal)
  -0.20    9.80   clock uncertainty           ← (17) Subtract uncertainty
   0.00    9.80   o_product[15]/CLK (DFFR)
  -0.08    9.72 ^ o_product[15]/D setup       ← (18) Subtract setup time
           9.72   data required time          ← (19) DATA REQUIRED TIME

           9.72   data required time
          -1.44   data arrival time
---------------------------------------------------------
           8.28   slack (MET)                 ← (20) SLACK = Required - Arrival
```

### Report Sections Explained

| # | Section | What It Means |
|---|---------|--------------|
| (1) | **Startpoint** | The flip-flop (or input port) that *launches* the data. The path begins here. |
| (2) | **Endpoint** | The flip-flop (or output port) that *captures* the data. The path ends here. |
| (3) | **Path Group** | The clock domain this path belongs to. All our paths are in the `clk` group. |
| (4) | **Path Type** | `max` = setup check (longest/slowest path), `min` = hold check (shortest/fastest path). |
| (5-14) | **Data Path** | Stage-by-stage delay breakdown. Each row shows the incremental delay added by a cell or net, the cumulative time, and the cell instance. The `^` or `v` symbol indicates a rising or falling transition. |
| (15) | **Data Arrival Time** | The total time for data to travel from startpoint to endpoint. Sum of all delays. |
| (16-18) | **Clock Path + Constraints** | The capture clock edge (10 ns), minus clock uncertainty, minus the flip-flop's setup time requirement. |
| (19) | **Data Required Time** | The latest time data can arrive and still meet the setup constraint. |
| (20) | **Slack** | `Required − Arrival`. Positive = timing is MET. Negative = VIOLATED. |

### Key Insight: What Makes a Path "Critical"?

The critical path is the one with the **smallest slack**. In our multiplier, the critical path runs through the deepest chain of logic — from an input register bit, through the AND gate, through all 4 CSA stages, through the entire 16-bit ripple-carry adder, to the most-significant output register bit.

## 1.6 Exercises

### Exercise 1.1: Report Interpretation
Run the setup timing report and answer:
1. What is the startpoint of the critical path?
2. What is the endpoint of the critical path?
3. What is the data arrival time?
4. What is the data required time?
5. What is the slack? Is timing MET or VIOLATED?

### Exercise 1.2: Multiple Paths
Run the following command to see the top 5 worst paths:

```tcl
report_checks -path_delay max -format full -endpoint_count 5
```

Questions:
1. Do all 5 paths have the same startpoint? Why or why not?
2. Do all 5 paths have the same endpoint? Why or why not?
3. What is the slack difference between the worst and 5th-worst path?

### Exercise 1.3: Conceptual Questions
1. If the clock period were changed from 10 ns to 5 ns (200 MHz), would you expect the slack to be positive or negative? Why?
2. What would happen to the slack if we increased the `set_input_delay` from 2.0 ns to 4.0 ns?
3. Why does STA check *every* path instead of just simulating with test vectors?

### Exercise 1.4: Hands-On Exploration
Try these commands in the interactive OpenSTA shell and observe the output:

```tcl
# Report timing for a specific endpoint
report_checks -path_delay max -format full -to [get_pins o_product[0]]

# Report timing for a specific startpoint
report_checks -path_delay max -format full -from [get_pins a_reg[0]/Q]
```

Questions:
1. Is the path to `o_product[0]` shorter or longer than the path to `o_product[15]`? Why?
2. What does this tell you about the ripple-carry adder structure?

---

# Lab 2: Cell Delay and Net Delay Analysis

## 2.1 Objectives

By the end of this lab you will be able to:

- Distinguish between **cell delay** and **net delay**
- Extract individual delay components from a timing report
- Understand what factors affect cell delay (input slew, output load)
- Understand what factors affect net delay (parasitic RC)
- Manually calculate total path delay from its components

## 2.2 Background Theory

### The Two Components of Path Delay

Every timing path is made up of alternating **cells** (logic gates, flip-flops) and **nets** (wires connecting them). The total path delay is the sum of all cell delays and net delays along the path.

```
  ┌──────┐  net   ┌──────┐  net   ┌──────┐  net   ┌──────┐
  │ FF   ├───────►│ AND  ├───────►│ XOR  ├───────►│ FF   │
  │(clk→Q)│       │      │        │      │        │(D)   │
  └──────┘        └──────┘        └──────┘        └──────┘
  
  |←cell→| |←net→| |←cell→| |←net→| |←cell→| |←net→|
  delay     delay   delay     delay   delay     delay
  
  Total Path Delay = Σ(cell delays) + Σ(net delays)
```

### Cell Delay (Gate Delay)

Cell delay is the time a signal takes to propagate from an input pin to an output pin of a logic gate. It is **NOT a fixed value** — it depends on two factors:

```
                    ┌─────────────────────┐
  Input Slew ──────►│                     │
  (transition time) │    LOGIC CELL       ├──────► Output
                    │   (AND, XOR, FF)    │        Signal
                    │                     │
                    └──────────┬──────────┘
                               │
                          Output Load
                        (capacitance of
                         connected nets
                         and cell inputs)
```

| Factor | Effect on Cell Delay |
|--------|---------------------|
| **Input Slew (Transition Time)** | Slower input transitions → larger cell delay. A "sluggish" input signal takes longer to switch the gate. |
| **Output Load (Capacitance)** | Higher output capacitance → larger cell delay. The gate must charge/discharge more capacitance. |

The Liberty file (`.lib`) contains **lookup tables** that map (input_slew, output_load) → cell_delay. Here's an example from our library for the AND2 cell:

```
cell_rise (delay_template_2x2) {
    index_1 ("0.05, 0.4");     ← input transition (ns)
    index_2 ("0.01, 0.1");     ← output capacitance (pF)
    values ("0.06, 0.14",      ← delay values (ns)
            "0.10, 0.20");
}
```

Reading this table:
- Input slew = 0.05 ns, Load = 0.01 pF → delay = **0.06 ns**
- Input slew = 0.05 ns, Load = 0.10 pF → delay = **0.14 ns**
- Input slew = 0.40 ns, Load = 0.01 pF → delay = **0.10 ns**
- Input slew = 0.40 ns, Load = 0.10 pF → delay = **0.20 ns**

> **💡 Key Insight:** Doubling the output load roughly doubles the cell delay. This is why fanout (number of gates driven) matters!

### Net Delay (Interconnect Delay)

Net delay is the time a signal takes to travel along the wire connecting one cell's output to another cell's input. It is caused by the **parasitic resistance (R) and capacitance (C)** of the wire.

```
  Cell A Output ──── R ──── C ──── R ──── C ──── Cell B Input
                     │             │
                    GND           GND
                    
  (Simplified RC model of an interconnect wire)
```

| Factor | Effect on Net Delay |
|--------|-------------------|
| **Wire Length** | Longer wires → more R and C → larger delay |
| **Wire Width** | Wider wires → less R but more C (trade-off) |
| **Metal Layer** | Higher metal layers typically have lower resistance |
| **Fanout** | More destination pins → more total capacitance |

> **📝 Note:** In our workshop design, since we don't have a physical layout (no SPEF file), OpenSTA uses a simplified wire model. In real designs, parasitic extraction tools generate SPEF files with accurate RC values.

### Delay Breakdown in a Timing Report

In an OpenSTA timing report, each line shows the **incremental delay** contributed by either a cell or a net:

```
  Delay    Time   Description
---------------------------------------------------------
   0.10    0.10 ^ a_reg[3]/Q (DFFR)          ← Cell delay (Clk→Q)
   0.00    0.10 ^ net_a3 (net)                ← Net delay (wire)
   0.06    0.16 ^ gen_pp_row[3].../Y (AND2)   ← Cell delay (AND gate)
   0.00    0.16 ^ net_pp3 (net)               ← Net delay (wire)
   0.08    0.24 ^ gen_csa1a[3].../sum (FA)    ← Cell delay (Full Adder)
```

- **Cell delay lines** show the cell instance name and cell type (e.g., `DFFR`, `AND2`)
- **Net delay lines** show the net name
- The **Time** column is cumulative (running total)
- The **Delay** column is the incremental delay of that single element

## 2.3 Procedure

### Step 1: Launch OpenSTA and Load the Design

```bash
cd /workspace/designs/design1_simple_multiplier
sta
```

```tcl
read_liberty ../../liberty_files/workshop_typical.lib
read_verilog wallace_multiplier.v
link_design wallace_multiplier
read_sdc constraints.sdc
```

### Step 2: Generate a Detailed Timing Report

```tcl
report_checks -path_delay max -format full
```

### Step 3: Analyze the Critical Path Delay Breakdown

Examine the report output carefully. For each line in the data path section, identify:
- Is this a **cell delay** or a **net delay**?
- What is the **incremental delay** value?
- What is the **cumulative time** at this point?

Create a table like this in your notes:

| # | Element | Type | Incr. Delay (ns) | Cumulative (ns) |
|---|---------|------|-------------------|------------------|
| 1 | a_reg[x]/Q (DFFR) | Cell (Clk→Q) | 0.10 | 0.10 |
| 2 | net_... | Net | 0.00 | 0.10 |
| 3 | gen_pp_row[x].../Y (AND2) | Cell | 0.06 | 0.16 |
| 4 | net_... | Net | 0.00 | 0.16 |
| ... | ... | ... | ... | ... |

### Step 4: Examine Delays for Different Path Endpoints

Compare the path to the LSB vs. MSB of the output:

```tcl
# Path to the least-significant output bit
report_checks -path_delay max -format full -to [get_pins o_product[0]]
```

```tcl
# Path to the most-significant output bit
report_checks -path_delay max -format full -to [get_pins o_product[15]]
```

> **💡 Think About It:** Why is the path to `o_product[15]` longer than to `o_product[0]`?
>
> *Answer: The ripple-carry adder propagates the carry from bit 0 to bit 15. The MSB must wait for the carry to ripple through all 16 stages.*

### Step 5: Examine the Liberty File Cell Delays

Let's look at the actual delay values in the library. In a separate terminal (or after exiting `sta`):

```bash
cat ../../liberty_files/workshop_typical.lib
```

Find the AND2 cell and note the `cell_rise` and `cell_fall` delay tables. Compare these values with what you see in the timing report.

### Step 6: Understand the Effect of Output Load

Try changing the output load and observe the effect:

```tcl
# Remove existing load and set a larger one
set_load -pin_load 0.2 [all_outputs]

# Re-run timing
report_checks -path_delay max -format full
```

Note how the delay of the **last cell** in the path changes. Then restore the original:

```tcl
set_load -pin_load 0.05 [all_outputs]
```

## 2.4 Timing Report Deep Dive: Delay Breakdown

Let's trace through a simplified critical path and calculate the total delay manually.

### Example Path: `a_reg[7]/Q → ... → o_product[15]/D`

```
  Component                    Cell Delay   Net Delay   Cumulative
  ─────────────────────────────────────────────────────────────────
  a_reg[7]/CLK (clock edge)       —            —          0.00 ns
  a_reg[7]/Q   (DFFR Clk→Q)    0.10 ns        —          0.10 ns
  net → AND gate                   —         ~0.00 ns     0.10 ns
  AND2 (partial product)         0.06 ns        —          0.16 ns
  net → CSA1 FA                    —         ~0.00 ns     0.16 ns
  FA (CSA Stage 1)               0.08 ns        —          0.24 ns
  net → CSA2 FA                    —         ~0.00 ns     0.24 ns
  FA (CSA Stage 2)               0.08 ns        —          0.32 ns
  net → CSA3 FA                    —         ~0.00 ns     0.32 ns
  FA (CSA Stage 3)               0.08 ns        —          0.40 ns
  net → CSA4 FA                    —         ~0.00 ns     0.40 ns
  FA (CSA Stage 4)               0.08 ns        —          0.48 ns
  net → Final Adder bit 0         —         ~0.00 ns     0.48 ns
  FA (Final Adder bit 0)         0.08 ns        —          0.56 ns
  ... (carry ripples through 15 more FAs) ...
  FA (Final Adder bit 15)        0.08 ns        —         ~1.76 ns
  net → output register            —         ~0.00 ns    ~1.76 ns
  ─────────────────────────────────────────────────────────────────
  Total Data Arrival Time:                                ~1.76 ns
```

> **📝 Note:** The actual values from OpenSTA may differ slightly because the tool interpolates the lookup tables based on actual slew and load conditions at each stage. The values above are approximate.

### Delay Composition Summary

For a typical path through our multiplier:

```
  ┌─────────────────────────────────────────────────┐
  │           Total Path Delay Composition           │
  │                                                   │
  │  Clk-to-Q (DFFR)  : ~0.10 ns  (  ~6%)          │
  │  AND gate          : ~0.06 ns  (  ~3%)          │
  │  CSA Stages (×4)   : ~0.32 ns  ( ~18%)          │
  │  Final Adder (×16) : ~1.28 ns  ( ~73%)          │
  │  Net delays        : ~0.00 ns  (  ~0%)  *       │
  │  ─────────────────────────────────────           │
  │  TOTAL             : ~1.76 ns  (100%)           │
  │                                                   │
  │  * Net delays are minimal without SPEF data      │
  └─────────────────────────────────────────────────┘
```

> **💡 Key Insight:** The ripple-carry adder dominates the critical path delay (~73%). This is why real multiplier designs use faster adder architectures (carry-lookahead, carry-select) for the final addition stage.

## 2.5 Exercises

### Exercise 2.1: Delay Extraction
From your timing report, extract and fill in this table for the critical path:

| Stage | Cell Type | Cell Delay (ns) | Net Delay (ns) |
|-------|-----------|-----------------|-----------------|
| Launch FF (Clk→Q) | DFFR | | |
| Partial Product | AND2 | | |
| CSA Stage 1 | FA | | |
| CSA Stage 2 | FA | | |
| CSA Stage 3 | FA | | |
| CSA Stage 4 | FA | | |
| Final Adder bit 0 | FA | | |
| Final Adder bit 1 | FA | | |
| ... | ... | ... | ... |
| Final Adder bit 15 | FA | | |

**Questions:**
1. What is the total cell delay along the critical path?
2. What is the total net delay along the critical path?
3. What percentage of the total path delay is cell delay vs. net delay?

### Exercise 2.2: Load Sensitivity
1. Run timing with `set_load -pin_load 0.01 [all_outputs]` and record the critical path slack.
2. Run timing with `set_load -pin_load 0.10 [all_outputs]` and record the critical path slack.
3. Run timing with `set_load -pin_load 0.50 [all_outputs]` and record the critical path slack.
4. How does increasing the output load affect the slack? Which cell's delay changes the most?

### Exercise 2.3: Path Comparison
Run timing reports for these two paths:

```tcl
report_checks -path_delay max -format full -to [get_pins o_product[0]]
report_checks -path_delay max -format full -to [get_pins o_product[15]]
```

1. How many full adder stages are in the path to `o_product[0]`?
2. How many full adder stages are in the path to `o_product[15]`?
3. What is the delay difference between the two paths?
4. Explain why the path to `o_product[15]` passes through more adder stages.

### Exercise 2.4: Manual Delay Calculation
Given the following Liberty data for the AND2 cell:

```
cell_rise values: ("0.06, 0.14",    ← (slew=0.05, load=0.01), (slew=0.05, load=0.1)
                   "0.10, 0.20");   ← (slew=0.4,  load=0.01), (slew=0.4,  load=0.1)
```

If the input slew is 0.05 ns and the output load is 0.01 pF, what is the cell rise delay?

If the input slew is 0.4 ns and the output load is 0.1 pF, what is the cell rise delay?

If the input slew is 0.2 ns and the output load is 0.05 pF, estimate the delay using linear interpolation.

---

# Lab 3: Setup and Hold Time Analysis

## 3.1 Objectives

By the end of this lab you will be able to:

- Explain the concepts of **setup time** and **hold time**
- Understand why both checks are necessary for reliable circuit operation
- Run setup and hold timing analysis in OpenSTA
- Calculate **slack** for both setup and hold checks
- Identify setup and hold violations and understand their causes

## 3.2 Background Theory

### Why Do We Need Setup and Hold Checks?

A flip-flop is a memory element that captures data on a clock edge. But the flip-flop is not magic — it needs the data signal to be **stable** for a certain window around the clock edge. If the data changes too close to the clock edge, the flip-flop may enter a **metastable state** and produce an unpredictable output.

```
                    Setup Time          Hold Time
                   ◄──────────►  ◄──────────►
                   │            │             │
  Data    ─────────┤  STABLE    │   STABLE    ├─────────
  Signal           │  REQUIRED  │   REQUIRED  │
                   │            │             │
  Clock   ─────────────────────┤▲├────────────────────
                               │
                          Active Clock Edge
                          (Rising Edge)
```

### Setup Time (T_setup)

**Definition:** The minimum time that data must be stable **BEFORE** the active clock edge.

```
  Data must be stable HERE
         │
         ▼
  ───────╔═══════════╗──────────
         ║  T_setup  ║
  ───────╚═══════════╝──────────
                     │
                     ▼
              Clock Rising Edge
```

- **Violation cause:** Data arrives **too late** (path is too slow)
- **Fix:** Reduce combinational logic delay, use faster cells, or increase clock period
- **In our library:** DFFR setup time ≈ 0.08–0.15 ns (depends on slew)

### Hold Time (T_hold)

**Definition:** The minimum time that data must remain stable **AFTER** the active clock edge.

```
              Clock Rising Edge
                     │
                     ▼
  ──────────╔═══════════╗───────
            ║  T_hold   ║
  ──────────╚═══════════╝───────
                     │
                     ▼
         Data must be stable HERE
```

- **Violation cause:** Data changes **too soon** after the clock edge (path is too fast)
- **Fix:** Add delay buffers to slow down the fast path
- **In our library:** DFFR hold time ≈ 0.03–0.05 ns (depends on slew)

### Setup Slack Calculation

```
  Setup Slack = Data Required Time − Data Arrival Time

  Where:
    Data Required Time = Capture Clock Edge
                       − Clock Uncertainty (setup)
                       − Flip-Flop Setup Time

    Data Arrival Time  = Launch Clock Edge
                       + Clock-to-Q Delay
                       + Combinational Path Delay
```

**Visual timeline for setup check:**

```
  Time ──────────────────────────────────────────────────►

  Launch Clock Edge                    Capture Clock Edge
  │                                    │
  ▼                                    ▼
  ├──── Clk-to-Q ──── Comb Logic ────►│
  │     delay          delay           │
  │                                    │
  │     ◄── Data Arrival Time ────►    │
  │                                    │
  │                          ◄─ setup ─┤
  │                          ◄─ uncert─┤
  │                                    │
  │     ◄── Data Required Time ───►    │
  │                                    │
  │     ◄──────── SLACK ──────────►    │  (if positive = MET)
```

### Hold Slack Calculation

```
  Hold Slack = Data Arrival Time − Data Required Time

  Where:
    Data Required Time = Launch Clock Edge
                       + Clock Uncertainty (hold)
                       + Flip-Flop Hold Time

    Data Arrival Time  = Launch Clock Edge
                       + Clock-to-Q Delay
                       + Combinational Path Delay (shortest)
```

> **⚠️ Important:** Notice that for hold checks, the formula is **reversed** compared to setup:
> - Setup: `Slack = Required − Arrival` (data must not arrive too LATE)
> - Hold: `Slack = Arrival − Required` (data must not arrive too EARLY)

**Visual timeline for hold check:**

```
  Time ──────────────────────────────────────────────────►

  Launch Clock Edge = Capture Clock Edge (same edge!)
  │
  ▼
  ├── Clk-to-Q ── Shortest Path ──►│
  │   delay        delay            │
  │                                 │
  │   ◄── Data Arrival Time ───►    │
  │                                 │
  ├─ hold ─►                        │
  ├─ uncert►                        │
  │                                 │
  │   ◄── SLACK ──────────────►     │  (if positive = MET)
```

### Setup vs. Hold: Summary Comparison

| Aspect | Setup Check | Hold Check |
|--------|------------|------------|
| **Question** | Is the data path slow enough to miss the next clock edge? | Is the data path fast enough to corrupt the current capture? |
| **Path analyzed** | Longest (slowest) path | Shortest (fastest) path |
| **OpenSTA flag** | `-path_delay max` | `-path_delay min` |
| **Violation cause** | Too much combinational delay | Too little combinational delay |
| **Fix** | Reduce delay or increase clock period | Add delay (buffers) |
| **Clock period dependent?** | YES — longer period helps | NO — independent of period |

## 3.3 Procedure

### Step 1: Load the Design

```bash
cd /workspace/designs/design1_simple_multiplier
sta
```

```tcl
read_liberty ../../liberty_files/workshop_typical.lib
read_verilog wallace_multiplier.v
link_design wallace_multiplier
read_sdc constraints.sdc
```

### Step 2: Run Setup Analysis

```tcl
report_checks -path_delay max -format full
```

Examine the report and identify:
- The **data arrival time**
- The **data required time**
- The **setup slack**
- Whether timing is **MET** or **VIOLATED**

### Step 3: Run Hold Analysis

```tcl
report_checks -path_delay min -format full
```

Examine the report and identify the same fields. Note how the hold report differs from the setup report:
- The path shown is the **shortest** path (minimum delay)
- The slack calculation uses the hold time instead of setup time
- The capture clock edge is the **same** edge as the launch (not the next one)

### Step 4: Check for Setup Violations

```tcl
# Report only paths with negative slack (violations)
report_checks -path_delay max -format full -slack_max 0
```

If no output appears, congratulations — there are no setup violations! The design meets timing at 100 MHz.

### Step 5: Check for Hold Violations

```tcl
report_checks -path_delay min -format full -slack_max 0
```

### Step 6: Experiment — Create a Setup Violation

Let's tighten the clock period to see what happens when the design can't meet timing:

```tcl
# Remove existing clock and create a faster one (1 ns = 1 GHz!)
create_clock -name clk -period 1.0 -waveform {0 0.5} [get_ports i_clk]

# Re-run setup analysis
report_checks -path_delay max -format full
```

> **💡 Observe:** The slack should now be **negative** — a setup violation! The combinational logic delay exceeds the available time window.

Now restore the original clock:

```tcl
create_clock -name clk -period 10.0 -waveform {0 5} [get_ports i_clk]
```

### Step 7: Understand the Slack Calculation Step by Step

Let's manually verify the setup slack from the report. Fill in the values from your actual report:

```
  SETUP SLACK CALCULATION
  ═══════════════════════════════════════════════════
  
  (A) Capture Clock Edge:           10.00 ns
  (B) Clock Uncertainty (setup):   − 0.20 ns
  (C) FF Setup Time:               − ____ ns  ← from report
  ─────────────────────────────────────────────
  (D) Data Required Time:            ____ ns  = A − B − C
  
  (E) Launch Clock Edge:              0.00 ns
  (F) Clk-to-Q Delay:              + ____ ns  ← from report
  (G) Combinational Delay:         + ____ ns  ← sum of all gates
  ─────────────────────────────────────────────
  (H) Data Arrival Time:             ____ ns  = E + F + G
  
  SLACK = D − H = ____ ns
  
  Status: MET / VIOLATED  (circle one)
```

## 3.4 Timing Report Analysis: Setup vs. Hold Reports

### Setup Report Structure

```
Startpoint: a_reg[7]
Endpoint:   o_product[15]
Path Group: clk
Path Type:  max                          ← SETUP check

  Delay    Time   Description
---------------------------------------------------------
   0.00    0.00   clock clk (rise edge)  ← Launch edge at T=0
   ...            (data path - LONGEST)
           X.XX   data arrival time

  10.00   10.00   clock clk (rise edge)  ← Capture edge at T=10ns
  -0.20    9.80   clock uncertainty
  -0.XX    9.XX   setup time
           9.XX   data required time

           slack (MET)                   ← Required − Arrival
```

### Hold Report Structure

```
Startpoint: a_reg[0]
Endpoint:   o_product[0]
Path Group: clk
Path Type:  min                          ← HOLD check

  Delay    Time   Description
---------------------------------------------------------
   0.00    0.00   clock clk (rise edge)  ← Launch edge at T=0
   ...            (data path - SHORTEST)
           X.XX   data arrival time

   0.00    0.00   clock clk (rise edge)  ← SAME edge (T=0)!
   0.10    0.10   clock uncertainty
   0.XX    0.XX   hold time
           0.XX   data required time

           slack (MET)                   ← Arrival − Required
```

> **⚠️ Key Difference:** In the hold report, the capture clock edge is at T=0 (same as launch), and the required time is calculated by **adding** hold time and uncertainty. The slack formula is also reversed.

## 3.5 Exercises

### Exercise 3.1: Setup Analysis
From your setup timing report, extract:
1. Data Arrival Time = ______ ns
2. Data Required Time = ______ ns
3. Setup Slack = ______ ns
4. Setup Time of the capture flip-flop = ______ ns
5. Clock Uncertainty (setup) = ______ ns

Verify: `Slack = Required − Arrival`. Does your calculation match the report?

### Exercise 3.2: Hold Analysis
From your hold timing report, extract:
1. Data Arrival Time = ______ ns
2. Data Required Time = ______ ns
3. Hold Slack = ______ ns
4. Hold Time of the capture flip-flop = ______ ns
5. Clock Uncertainty (hold) = ______ ns

### Exercise 3.3: Clock Period Sweep
Run setup analysis at different clock periods and fill in the table:

```tcl
# Example for 8 ns period:
create_clock -name clk -period 8.0 -waveform {0 4} [get_ports i_clk]
report_checks -path_delay max -format full
```

| Clock Period (ns) | Frequency (MHz) | Setup Slack (ns) | MET/VIOLATED |
|-------------------|-----------------|-------------------|--------------|
| 10.0 | 100 | | |
| 8.0 | 125 | | |
| 5.0 | 200 | | |
| 3.0 | 333 | | |
| 2.0 | 500 | | |

**Questions:**
1. At what clock period does the design first fail setup timing?
2. What is the maximum operating frequency of this design?
3. Does the hold slack change when you change the clock period? Why or why not?

### Exercise 3.4: Slack Calculation Practice

**Problem 1:** Given:
- Clock period = 10 ns
- Clock-to-Q delay = 0.12 ns
- Combinational path delay = 7.5 ns
- Setup time = 0.10 ns
- Clock uncertainty (setup) = 0.2 ns

Calculate the setup slack. Is timing MET or VIOLATED?

**Problem 2:** Given:
- Clock-to-Q delay = 0.10 ns
- Shortest combinational path delay = 0.05 ns
- Hold time = 0.04 ns
- Clock uncertainty (hold) = 0.1 ns

Calculate the hold slack. Is timing MET or VIOLATED?

**Problem 3:** A design has a critical path delay (Clk-to-Q + combinational) of 4.2 ns. The setup time is 0.1 ns and clock uncertainty is 0.15 ns. What is the minimum clock period needed to meet setup timing?

---

# Lab 4: False Paths — Concept and Implementation

## 4.1 Objectives

By the end of this lab you will be able to:

- Explain what a **false path** is and why it exists in real designs
- Identify common scenarios that create false paths
- Use the `set_false_path` SDC command to constrain false paths
- Compare timing results **before** and **after** applying false path constraints
- Understand the impact of false paths on timing analysis accuracy

## 4.2 Background Theory

### What Is a False Path?

A **false path** is a timing path that exists structurally in the circuit (the gates and wires are physically there) but can **never be exercised during normal functional operation**. Because STA analyzes all structural paths — regardless of whether they can actually be activated — it will report timing on false paths unless explicitly told to ignore them.

```
  ┌─────────────────────────────────────────────────────┐
  │                                                       │
  │   STRUCTURAL PATH:  Exists in the netlist (gates     │
  │                     and wires are connected)          │
  │                                                       │
  │   FUNCTIONAL PATH:  Can actually be activated by      │
  │                     real input patterns                │
  │                                                       │
  │   FALSE PATH:       Structural but NOT functional     │
  │                     (can never be exercised)           │
  │                                                       │
  └─────────────────────────────────────────────────────┘
```

### Why Do False Paths Matter?

If you don't tell the STA tool about false paths, several problems occur:

1. **Pessimistic Timing:** The tool may report the false path as the critical path, making the design appear slower than it actually is.
2. **Wasted Optimization Effort:** Engineers may spend time optimizing a path that doesn't matter.
3. **Meaningless Violations:** Cross-domain paths may show huge violations that are impossible to fix (and don't need fixing).
4. **Incorrect Slack Values:** The overall timing picture is distorted.

### Common False Path Scenarios

#### Scenario 1: Static Configuration Signals (Test Mode)

```
                         ┌──────────┐
  Functional Data ──────►│          │
                         │   MUX    ├──────► To Output Register
  Test Pattern ─────────►│          │
                         └────┬─────┘
                              │
  i_test_mode ───────────────►│  (STATIC — set once, never toggles)
  
  FALSE PATH: i_test_mode → MUX → Output Register
  REASON: i_test_mode is set during manufacturing test and
          never changes during normal chip operation.
```

#### Scenario 2: Asynchronous Clock Domain Crossing

```
  ┌──────────────┐                    ┌──────────────┐
  │  func_clk    │                    │  scan_clk    │
  │  Domain      │                    │  Domain      │
  │              │    Cross-Domain    │              │
  │  FF_A ───────┼───── Wire ────────┼──► FF_B      │
  │              │                    │              │
  └──────────────┘                    └──────────────┘
  
  FALSE PATH: FF_A (func_clk) → FF_B (scan_clk)
  REASON: The two clocks are asynchronous and never active
          simultaneously. No valid timing relationship exists.
```

#### Scenario 3: Mutually Exclusive Conditions

```
  if (MODE == READ)
      data_out = memory[addr];     ← Path A
  
  if (MODE == WRITE)
      memory[addr] = data_in;      ← Path B
  
  FALSE PATH: data_in → data_out (through both paths)
  REASON: READ and WRITE are mutually exclusive — both
          cannot be active at the same time.
```

### The SDC Command: `set_false_path`

```tcl
# Syntax:
set_false_path -from <startpoint> -to <endpoint>

# Common usage patterns:

# 1. All paths FROM a specific port
set_false_path -from [get_ports i_test_mode]

# 2. All paths between two clock domains
set_false_path -from [get_clocks clk_A] -to [get_clocks clk_B]

# 3. All paths TO a specific register
set_false_path -to [get_pins debug_reg/D]

# 4. A specific path from one point to another
set_false_path -from [get_pins mux/S] -to [get_pins out_reg/D]
```

## 4.3 The Design Under Test: Multiplier with Test Logic (Design 2)

Design 2 extends the basic Wallace multiplier with two test/debug features that create false path scenarios:

```
  i_a, i_b                 i_test_pattern    i_scan_clk
     │                          │                 │
  ┌──▼───┐                     │              ┌──▼───┐
  │Input │                     │              │ Scan │
  │ Regs │  (func_clk)        │              │ Reg  │ (scan_clk)
  └──┬───┘                     │              └──┬───┘
     │                          │                 │
  ┌──▼──────────┐              │            o_scan_data
  │ Wallace Tree│              │
  │ + Final Add ├────┐         │
  └─────────────┘    │         │
                  ┌──▼────────▼──┐
  i_test_mode ──►│   TEST MUX    │  ← FALSE PATH #1
                  └──────┬───────┘
                         │
                  ┌──────▼───────┐
                  │  Output Reg  │  (func_clk)
                  └──────┬───────┘
                         │
                     o_product
```

**False Path #1 — Test Mode MUX:**
- `i_test_mode` is a static configuration signal
- Set once during manufacturing test, never toggles in normal operation
- Path: `i_test_mode → MUX → o_product register`

**False Path #2 — Cross Clock Domain:**
- `func_clk` (100 MHz) and `scan_clk` (50 MHz) are asynchronous
- Never active simultaneously in normal operation
- Paths: `func_clk domain ↔ scan_clk domain`

## 4.4 Files Used in This Lab

| File | Path (inside Docker) | Purpose |
|------|---------------------|---------|
| Verilog Netlist | `designs/design2_multiplier_with_test_logic/wallace_multiplier_with_test.v` | Design with test logic |
| SDC Constraints | `designs/design2_multiplier_with_test_logic/constraints.sdc` | Constraints WITH false paths |
| STA Script | `designs/design2_multiplier_with_test_logic/run_sta.tcl` | Analysis script (Part A & B) |

## 4.5 Procedure

### Step 1: Navigate to Design 2

```bash
cd /workspace/designs/design2_multiplier_with_test_logic
```

### Step 2: Examine the Design

Review the Verilog to understand the test logic:

```bash
cat wallace_multiplier_with_test.v
```

Pay special attention to:
- The **test mux** (`muxed_product = i_test_mode ? i_test_pattern : func_product`)
- The **scan register** (clocked by `i_scan_clk`, captures `csa2a_sum`)

### Step 3: Examine the SDC Constraints

```bash
cat constraints.sdc
```

Note the false path commands at the bottom:

```tcl
# False Path 1: Static test mode signal
set_false_path -from [get_ports i_test_mode]
set_false_path -from [get_ports i_test_pattern*]

# False Path 2: Cross clock domain
set_false_path -from [get_clocks func_clk] -to [get_clocks scan_clk]
set_false_path -from [get_clocks scan_clk] -to [get_clocks func_clk]
```

### Step 4: Run Analysis WITHOUT False Path Constraints

Launch OpenSTA and load the design with only basic constraints (no false paths):

```bash
sta
```

```tcl
# Load design
read_liberty ../../liberty_files/workshop_typical.lib
read_verilog wallace_multiplier_with_test.v
link_design wallace_multiplier_with_test

# Apply ONLY basic constraints (no false paths)
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
```

Now run the timing reports:

```tcl
# Setup timing — observe what the tool reports as critical
puts "=== SETUP TIMING (NO FALSE PATHS) ==="
report_checks -path_delay max -format full
```

```tcl
# Check for cross-domain paths
puts "=== CROSS-DOMAIN PATHS (func_clk -> scan_clk) ==="
report_checks -path_delay max -format full -from [get_clocks func_clk] -to [get_clocks scan_clk]
```

> **📝 Record these results!** Write down:
> - The critical path startpoint and endpoint
> - The critical path slack
> - Whether any cross-domain paths are reported
> - Whether the test mux appears in any path

### Step 5: Add False Path Constraints

Now add the false path constraints:

```tcl
# False Path 1: Test mode (static configuration)
set_false_path -from [get_ports i_test_mode]
set_false_path -from [get_ports i_test_pattern*]

# False Path 2: Cross clock domain
set_false_path -from [get_clocks func_clk] -to [get_clocks scan_clk]
set_false_path -from [get_clocks scan_clk] -to [get_clocks func_clk]
```

### Step 6: Re-Run Analysis WITH False Path Constraints

```tcl
# Setup timing — observe the changes
puts "=== SETUP TIMING (WITH FALSE PATHS) ==="
report_checks -path_delay max -format full
```

```tcl
# Check cross-domain paths again
puts "=== CROSS-DOMAIN PATHS (should be empty now) ==="
report_checks -path_delay max -format full -from [get_clocks func_clk] -to [get_clocks scan_clk]
```

```tcl
# Hold timing
puts "=== HOLD TIMING (WITH FALSE PATHS) ==="
report_checks -path_delay min -format full
```

### Step 7: Compare Results

Fill in this comparison table:

```
  ┌─────────────────────────────────────────────────────────────┐
  │              BEFORE vs. AFTER False Path Constraints         │
  ├──────────────────────┬──────────────┬───────────────────────┤
  │ Metric               │ WITHOUT FP   │ WITH FP               │
  ├──────────────────────┼──────────────┼───────────────────────┤
  │ Critical Path Start  │              │                       │
  │ Critical Path End    │              │                       │
  │ Setup Slack          │              │                       │
  │ Cross-Domain Paths?  │ Yes / No     │ Yes / No              │
  │ Test Mux in Path?    │ Yes / No     │ Yes / No              │
  └──────────────────────┴──────────────┴───────────────────────┘
```

### Step 8: Run the Complete Script (Optional)

You can also run the pre-written script that performs both analyses:

```bash
sta run_sta.tcl
```

This script automatically runs Part A (without false paths) and Part B (with false paths) and prints comparison notes.

## 4.6 Timing Report Analysis: How False Paths Affect Reports

### Without False Paths

The tool may report paths like:

```
Startpoint: i_test_mode (input port clocked by func_clk)
Endpoint:   o_product[0] (rising edge-triggered flip-flop clocked by func_clk)
Path Group: func_clk
Path Type:  max

  Delay    Time   Description
---------------------------------------------------------
   0.00    0.00   clock func_clk (rise edge)
   2.00    2.00   input external delay          ← input_delay
   0.09    2.09 ^ i_test_mode (in)
   0.XX    X.XX ^ mux_product/Y (MUX2)         ← Test mux delay
           X.XX   data arrival time

  ...
           X.XX   slack (MET or VIOLATED)
```

This path through `i_test_mode` is **meaningless** in normal operation — the signal never toggles!

### With False Paths

After adding `set_false_path -from [get_ports i_test_mode]`, this path **disappears** from the reports entirely. The tool now correctly reports only the functional paths through the Wallace tree.

Similarly, cross-domain paths between `func_clk` and `scan_clk` are eliminated, removing any spurious violations.

### Impact Summary

```
  WITHOUT False Paths:
  ┌──────────────────────────────────────────────┐
  │ ✗ Test mux paths reported (meaningless)      │
  │ ✗ Cross-domain paths reported (meaningless)  │
  │ ✗ Critical path may be wrong                 │
  │ ✗ Slack values may be pessimistic            │
  │ ✗ Spurious violations confuse engineers      │
  └──────────────────────────────────────────────┘

  WITH False Paths:
  ┌──────────────────────────────────────────────┐
  │ ✓ Only functional paths analyzed             │
  │ ✓ Cross-domain paths correctly excluded      │
  │ ✓ True critical path identified              │
  │ ✓ Accurate slack values                      │
  │ ✓ Clean, actionable timing reports           │
  └──────────────────────────────────────────────┘
```

## 4.7 Exercises

### Exercise 4.1: Identify False Paths
Without looking at the SDC file, examine the Verilog design (`wallace_multiplier_with_test.v`) and list all the false paths you can identify. For each one, explain **why** it is a false path.

### Exercise 4.2: Before/After Comparison
Complete the comparison table from Step 7 with actual values from your analysis runs. Answer:
1. Did the critical path change after adding false path constraints?
2. Did the slack improve, worsen, or stay the same?
3. Were there any cross-domain paths reported before adding false paths?
4. Were there any cross-domain paths reported after adding false paths?

### Exercise 4.3: SDC Command Practice
Write the `set_false_path` commands for the following scenarios (do NOT look at the constraints file):

1. A reset signal `i_rst_n` that is asserted once at power-up and then released. You want to exclude all paths from this signal.

2. Two clocks `clk_fast` (500 MHz) and `clk_slow` (100 MHz) that are asynchronous. Exclude all paths between them.

3. A debug port `i_debug_sel` that selects between normal data and debug data through a mux. The signal is static during normal operation.

**Answers (write your commands here):**

```tcl
# 1. Reset signal:


# 2. Asynchronous clocks:


# 3. Debug port:

```

### Exercise 4.4: Scenario Analysis
For each scenario below, determine whether a false path constraint is appropriate. Explain your reasoning.

**Scenario A:** A chip has a JTAG test clock (`tck`) and a functional clock (`sys_clk`). The JTAG interface is used for boundary scan testing and is never active during normal operation.
- False path needed? ______
- Why? ______

**Scenario B:** A design has a clock divider that generates `clk_div2` from `clk`. Both clocks are synchronous (one is derived from the other).
- False path needed? ______
- Why? ______

**Scenario C:** A memory controller has separate read and write data paths. The `read_en` and `write_en` signals are mutually exclusive (both cannot be active at the same time).
- False path needed? ______
- Why? ______

**Scenario D:** A design has an input port `i_config[3:0]` that is loaded from non-volatile memory at boot time and never changes during operation. It controls the operating mode of a processing unit.
- False path needed? ______
- Why? ______

### Exercise 4.5: Critical Thinking
1. What could go wrong if you incorrectly mark a **real** timing path as a false path?
2. Is it better to be conservative (fewer false paths) or aggressive (more false paths)? Why?
3. In a real design flow, who is responsible for identifying false paths — the designer, the STA engineer, or both?

---

# Appendix A: Quick Reference — OpenSTA Commands

| Command | Description | Example |
|---------|-------------|---------|
| `read_liberty` | Load technology library | `read_liberty lib.lib` |
| `read_verilog` | Load Verilog netlist | `read_verilog design.v` |
| `link_design` | Link netlist to library | `link_design top_module` |
| `read_sdc` | Load timing constraints | `read_sdc constraints.sdc` |
| `create_clock` | Define a clock | `create_clock -name clk -period 10 [get_ports clk]` |
| `set_input_delay` | Set input arrival time | `set_input_delay 2.0 -clock clk [get_ports data_in]` |
| `set_output_delay` | Set output required time | `set_output_delay 2.0 -clock clk [get_ports data_out]` |
| `set_load` | Set output capacitance | `set_load -pin_load 0.05 [all_outputs]` |
| `set_false_path` | Mark a path as false | `set_false_path -from [get_ports test]` |
| `set_clock_uncertainty` | Add clock jitter/skew | `set_clock_uncertainty 0.2 -setup [get_clocks clk]` |
| `report_checks` | Generate timing report | `report_checks -path_delay max -format full` |
| `report_checks` (filtered) | Report specific paths | `report_checks -path_delay max -to [get_pins reg/D]` |
| `report_checks` (violations) | Report only violations | `report_checks -path_delay max -slack_max 0` |
| `report_checks` (N paths) | Report top N paths | `report_checks -path_delay max -endpoint_count 5` |

# Appendix B: Quick Reference — Timing Formulas

### Setup Slack

```
Setup Slack = (Capture Clock Edge − Clock Uncertainty_setup − T_setup)
            − (Launch Clock Edge + T_clk-to-Q + T_combinational)

Simplified:
Setup Slack = Clock Period − Clock Uncertainty − T_setup − T_clk-to-Q − T_comb
```

### Hold Slack

```
Hold Slack = (Launch Clock Edge + T_clk-to-Q + T_comb_min)
           − (Capture Clock Edge + Clock Uncertainty_hold + T_hold)

Simplified (same-edge capture):
Hold Slack = T_clk-to-Q + T_comb_min − Clock Uncertainty_hold − T_hold
```

### Maximum Operating Frequency

```
T_min = T_clk-to-Q + T_comb_critical + T_setup + Clock Uncertainty

F_max = 1 / T_min
```

# Appendix C: Glossary

| Term | Definition |
|------|-----------|
| **AAT** | Actual Arrival Time — when data actually arrives at a point |
| **RAT** | Required Arrival Time — when data must arrive by |
| **Slack** | RAT − AAT (for setup); AAT − RAT (for hold) |
| **Critical Path** | Path with worst (smallest) slack |
| **Setup Time** | Data must be stable this long BEFORE clock edge |
| **Hold Time** | Data must remain stable this long AFTER clock edge |
| **Clock-to-Q** | Delay from clock edge to data appearing at FF output |
| **Cell Delay** | Propagation delay through a logic gate |
| **Net Delay** | Propagation delay through an interconnect wire |
| **False Path** | Structural path that cannot be functionally exercised |
| **SDC** | Synopsys Design Constraints format |
| **Liberty (.lib)** | Technology library with cell timing data |
| **SPEF** | Standard Parasitic Exchange Format (wire RC data) |
| **Slew** | Transition time of a signal (rise or fall time) |
| **Fanout** | Number of inputs driven by a single output |
| **Metastability** | Unstable state when setup/hold is violated |

---

*End of Day 1 Lab Manual — OpenSTA Workshop*
