// =============================================================================
// File:    wallace_multiplier_with_test.v
// Author:  OpenSTA Workshop
// Description:
//   8-bit Wallace Tree Multiplier with added Test/Debug Logic.
//   Used in Lab 4 to demonstrate FALSE PATH constraints in STA.
//
//   This design adds two features that create false path scenarios:
//
//   1. TEST MUX (i_test_mode):
//      A static configuration signal that selects between normal
//      operation and a test pattern. In real silicon, this signal is
//      set once during manufacturing test and never toggles during
//      normal operation. The path from i_test_mode through the mux
//      to the output is a FALSE PATH.
//
//   2. SCAN/DEBUG REGISTER (i_scan_clk domain):
//      A separate scan clock domain captures the internal partial
//      product sum for debug observation. Since the scan clock and
//      the functional clock are asynchronous and never active at the
//      same time, all paths between the two clock domains are FALSE
//      PATHS.
// =============================================================================

// ---------------------------------------------------------------------------
// Half Adder
// ---------------------------------------------------------------------------
module ha (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

// ---------------------------------------------------------------------------
// Full Adder
// ---------------------------------------------------------------------------
module fa (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (b & cin) | (a & cin);
endmodule

// ---------------------------------------------------------------------------
// Top-Level: Wallace Multiplier with Test Logic
// ---------------------------------------------------------------------------
module wallace_multiplier_with_test (
    // --- Functional Clock Domain ---
    input  wire        i_clk,           // Functional system clock
    input  wire        i_rst_n,         // Active-low synchronous reset
    input  wire [7:0]  i_a,             // Multiplicand
    input  wire [7:0]  i_b,             // Multiplier
    output reg  [15:0] o_product,       // Product output

    // --- Test/Debug Interface ---
    input  wire        i_test_mode,     // Static test mode select (FALSE PATH source)
    input  wire [15:0] i_test_pattern,  // Test pattern input

    // --- Scan/Debug Clock Domain ---
    input  wire        i_scan_clk,      // Scan clock (async to i_clk)
    input  wire        i_scan_en,       // Scan enable
    output reg  [15:0] o_scan_data      // Debug observation port
);

    // =========================================================================
    // FUNCTIONAL DATAPATH (same as Design 1)
    // =========================================================================

    // --- Input Registers ---
    reg [7:0] a_reg, b_reg;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            a_reg <= 8'd0;
            b_reg <= 8'd0;
        end else begin
            a_reg <= i_a;
            b_reg <= i_b;
        end
    end

    // --- Partial Product Generation ---
    wire [7:0] pp [0:7];

    genvar gi, gj;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : gen_pp_row
            for (gj = 0; gj < 8; gj = gj + 1) begin : gen_pp_col
                assign pp[gi][gj] = a_reg[gj] & b_reg[gi];
            end
        end
    endgenerate

    // --- Expand partial products to 16-bit shifted values ---
    wire [15:0] pp_shifted [0:7];
    assign pp_shifted[0] = {8'b0, pp[0]};
    assign pp_shifted[1] = {7'b0, pp[1], 1'b0};
    assign pp_shifted[2] = {6'b0, pp[2], 2'b0};
    assign pp_shifted[3] = {5'b0, pp[3], 3'b0};
    assign pp_shifted[4] = {4'b0, pp[4], 4'b0};
    assign pp_shifted[5] = {3'b0, pp[5], 5'b0};
    assign pp_shifted[6] = {2'b0, pp[6], 6'b0};
    assign pp_shifted[7] = {1'b0, pp[7], 7'b0};

    // --- Wallace Tree Reduction (Carry-Save Adder Stages) ---
    // CSA Stage 1a: rows 0+1+2
    wire [15:0] csa1a_sum, csa1a_carry;
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa1a
            fa csa1a_fa (
                .a(pp_shifted[0][k]), .b(pp_shifted[1][k]),
                .cin(pp_shifted[2][k]),
                .sum(csa1a_sum[k]), .carry(csa1a_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa1a_carry_shifted = {csa1a_carry[14:0], 1'b0};

    // CSA Stage 1b: rows 3+4+5
    wire [15:0] csa1b_sum, csa1b_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa1b
            fa csa1b_fa (
                .a(pp_shifted[3][k]), .b(pp_shifted[4][k]),
                .cin(pp_shifted[5][k]),
                .sum(csa1b_sum[k]), .carry(csa1b_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa1b_carry_shifted = {csa1b_carry[14:0], 1'b0};

    // CSA Stage 2a: csa1a_sum + csa1a_carry + csa1b_sum
    wire [15:0] csa2a_sum, csa2a_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa2a
            fa csa2a_fa (
                .a(csa1a_sum[k]), .b(csa1a_carry_shifted[k]),
                .cin(csa1b_sum[k]),
                .sum(csa2a_sum[k]), .carry(csa2a_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa2a_carry_shifted = {csa2a_carry[14:0], 1'b0};

    // CSA Stage 2b: csa1b_carry + pp[6] + pp[7]
    wire [15:0] csa2b_sum, csa2b_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa2b
            fa csa2b_fa (
                .a(csa1b_carry_shifted[k]), .b(pp_shifted[6][k]),
                .cin(pp_shifted[7][k]),
                .sum(csa2b_sum[k]), .carry(csa2b_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa2b_carry_shifted = {csa2b_carry[14:0], 1'b0};

    // CSA Stage 3: csa2a_sum + csa2a_carry + csa2b_sum
    wire [15:0] csa3_sum, csa3_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa3
            fa csa3_fa (
                .a(csa2a_sum[k]), .b(csa2a_carry_shifted[k]),
                .cin(csa2b_sum[k]),
                .sum(csa3_sum[k]), .carry(csa3_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa3_carry_shifted = {csa3_carry[14:0], 1'b0};

    // CSA Stage 4: csa3_sum + csa3_carry + csa2b_carry
    wire [15:0] csa4_sum, csa4_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa4
            fa csa4_fa (
                .a(csa3_sum[k]), .b(csa3_carry_shifted[k]),
                .cin(csa2b_carry_shifted[k]),
                .sum(csa4_sum[k]), .carry(csa4_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa4_carry_shifted = {csa4_carry[14:0], 1'b0};

    // --- Final Addition ---
    wire [15:0] func_product;
    wire [16:0] final_carry;
    assign final_carry[0] = 1'b0;

    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_final_add
            fa final_fa (
                .a(csa4_sum[k]), .b(csa4_carry_shifted[k]),
                .cin(final_carry[k]),
                .sum(func_product[k]), .carry(final_carry[k+1])
            );
        end
    endgenerate

    // =========================================================================
    // TEST LOGIC 1: Test Mode MUX (FALSE PATH - static configuration)
    // =========================================================================
    // In normal operation, i_test_mode = 0 and the functional product passes
    // through. During manufacturing test, i_test_mode = 1 and a test pattern
    // is injected. Since i_test_mode is a static signal that does NOT toggle
    // during normal operation, the timing path through i_test_mode to
    // o_product is a FALSE PATH.
    //
    // Without the false path constraint, the STA tool would report the path
    // through the test mux as a real timing path, potentially skewing results.

    wire [15:0] muxed_product;
    assign muxed_product = i_test_mode ? i_test_pattern : func_product;

    // --- Output Register ---
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_product <= 16'd0;
        end else begin
            o_product <= muxed_product;
        end
    end

    // =========================================================================
    // TEST LOGIC 2: Scan/Debug Observation Register (FALSE PATH - cross-domain)
    // =========================================================================
    // This register operates in the i_scan_clk domain, which is completely
    // asynchronous to i_clk. It captures internal signals for debug/DFT.
    // ALL paths between i_clk-domain flip-flops and i_scan_clk-domain
    // flip-flops are FALSE PATHS because the two clocks are never active
    // simultaneously in normal operation.
    //
    // The scan register captures the intermediate CSA Stage 2a sum,
    // which is useful for diagnosing multiplier issues during testing.

    always @(posedge i_scan_clk) begin
        if (i_scan_en) begin
            o_scan_data <= csa2a_sum;   // Capture intermediate result
        end
    end

endmodule
