// =============================================================================
// File:    wallace_multiplier.v
// Author:  OpenSTA Workshop
// Description:
//   An 8-bit Wallace Tree Multiplier implemented in synthesizable Verilog.
//   This design takes two 8-bit unsigned inputs (A and B) and produces a
//   16-bit unsigned product. It is a *gate-level structural* netlist
//   intended for use with OpenSTA timing analysis (Labs 1-3).
//
//   Architecture:
//     1. Partial Product Generation  - AND gates (64 partial products)
//     2. Wallace Tree Reduction      - Half & Full Adders reduce to 2 rows
//     3. Final Ripple-Carry Addition  - Produces the 16-bit result
//
//   All internal nodes are named for easy identification in timing reports.
// =============================================================================

// ---------------------------------------------------------------------------
// Half Adder  (2-input, produces Sum and Carry)
// ---------------------------------------------------------------------------
module ha (
    input  wire a,
    input  wire b,
    output wire sum,
    output wire carry
);
    assign sum   = a ^ b;   // XOR for sum
    assign carry = a & b;   // AND for carry
endmodule

// ---------------------------------------------------------------------------
// Full Adder  (3-input, produces Sum and Carry)
// ---------------------------------------------------------------------------
module fa (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire carry
);
    assign sum   = a ^ b ^ cin;              // XOR chain for sum
    assign carry = (a & b) | (b & cin) | (a & cin); // Majority for carry
endmodule

// ---------------------------------------------------------------------------
// Top-Level: 8-bit Wallace Tree Multiplier
// ---------------------------------------------------------------------------
module wallace_multiplier (
    input  wire        i_clk,       // System clock
    input  wire        i_rst_n,     // Active-low synchronous reset
    input  wire [7:0]  i_a,         // Multiplicand (8-bit unsigned)
    input  wire [7:0]  i_b,         // Multiplier   (8-bit unsigned)
    output reg  [15:0] o_product    // Product      (16-bit unsigned)
);

    // =========================================================================
    // STAGE 1: Input Registers
    // =========================================================================
    // Register inputs for clean timing analysis (launch flops)
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

    // =========================================================================
    // STAGE 2: Partial Product Generation
    // =========================================================================
    // Each partial product pp[i][j] = a_reg[j] & b_reg[i]
    // pp[i] represents the i-th row, shifted left by i positions.
    wire [7:0] pp [0:7];   // 8 rows of 8-bit partial products

    genvar gi, gj;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : gen_pp_row
            for (gj = 0; gj < 8; gj = gj + 1) begin : gen_pp_col
                assign pp[gi][gj] = a_reg[gj] & b_reg[gi];
            end
        end
    endgenerate

    // =========================================================================
    // STAGE 3: Wallace Tree Reduction
    // =========================================================================
    // The goal is to reduce 8 rows of partial products down to 2 rows
    // using half adders (HA) and full adders (FA).
    //
    // Reduction layers:
    //   Layer 1: 8 rows -> 6 rows
    //   Layer 2: 6 rows -> 4 rows
    //   Layer 3: 4 rows -> 3 rows
    //   Layer 4: 3 rows -> 2 rows
    //
    // For simplicity and clarity in this workshop design, we implement
    // a carry-save reduction approach that is functionally equivalent
    // to a Wallace tree.

    // --- Carry-Save Adder Stage 1: Reduce rows 0,1,2 and rows 3,4,5 ---
    // CSA1a: rows 0 + 1 + 2
    wire [15:0] csa1a_sum, csa1a_carry;
    // CSA1b: rows 3 + 4 + 5
    wire [15:0] csa1b_sum, csa1b_carry;

    // Expand partial products into 16-bit shifted values
    wire [15:0] pp_shifted [0:7];
    assign pp_shifted[0] = {8'b0, pp[0]};
    assign pp_shifted[1] = {7'b0, pp[1], 1'b0};
    assign pp_shifted[2] = {6'b0, pp[2], 2'b0};
    assign pp_shifted[3] = {5'b0, pp[3], 3'b0};
    assign pp_shifted[4] = {4'b0, pp[4], 4'b0};
    assign pp_shifted[5] = {3'b0, pp[5], 5'b0};
    assign pp_shifted[6] = {2'b0, pp[6], 6'b0};
    assign pp_shifted[7] = {1'b0, pp[7], 7'b0};

    // CSA1a: pp_shifted[0] + pp_shifted[1] + pp_shifted[2]
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa1a
            fa csa1a_fa (
                .a     (pp_shifted[0][k]),
                .b     (pp_shifted[1][k]),
                .cin   (pp_shifted[2][k]),
                .sum   (csa1a_sum[k]),
                .carry (csa1a_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa1a_carry_shifted = {csa1a_carry[14:0], 1'b0};

    // CSA1b: pp_shifted[3] + pp_shifted[4] + pp_shifted[5]
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa1b
            fa csa1b_fa (
                .a     (pp_shifted[3][k]),
                .b     (pp_shifted[4][k]),
                .cin   (pp_shifted[5][k]),
                .sum   (csa1b_sum[k]),
                .carry (csa1b_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa1b_carry_shifted = {csa1b_carry[14:0], 1'b0};

    // --- Carry-Save Adder Stage 2: Reduce further ---
    // CSA2a: csa1a_sum + csa1a_carry_shifted + csa1b_sum
    wire [15:0] csa2a_sum, csa2a_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa2a
            fa csa2a_fa (
                .a     (csa1a_sum[k]),
                .b     (csa1a_carry_shifted[k]),
                .cin   (csa1b_sum[k]),
                .sum   (csa2a_sum[k]),
                .carry (csa2a_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa2a_carry_shifted = {csa2a_carry[14:0], 1'b0};

    // CSA2b: csa1b_carry_shifted + pp_shifted[6] + pp_shifted[7]
    wire [15:0] csa2b_sum, csa2b_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa2b
            fa csa2b_fa (
                .a     (csa1b_carry_shifted[k]),
                .b     (pp_shifted[6][k]),
                .cin   (pp_shifted[7][k]),
                .sum   (csa2b_sum[k]),
                .carry (csa2b_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa2b_carry_shifted = {csa2b_carry[14:0], 1'b0};

    // --- Carry-Save Adder Stage 3: 4 rows -> 3 rows ---
    // CSA3: csa2a_sum + csa2a_carry_shifted + csa2b_sum
    wire [15:0] csa3_sum, csa3_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa3
            fa csa3_fa (
                .a     (csa2a_sum[k]),
                .b     (csa2a_carry_shifted[k]),
                .cin   (csa2b_sum[k]),
                .sum   (csa3_sum[k]),
                .carry (csa3_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa3_carry_shifted = {csa3_carry[14:0], 1'b0};

    // --- Carry-Save Adder Stage 4: 3 rows -> 2 rows ---
    // CSA4: csa3_sum + csa3_carry_shifted + csa2b_carry_shifted
    wire [15:0] csa4_sum, csa4_carry;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_csa4
            fa csa4_fa (
                .a     (csa3_sum[k]),
                .b     (csa3_carry_shifted[k]),
                .cin   (csa2b_carry_shifted[k]),
                .sum   (csa4_sum[k]),
                .carry (csa4_carry[k])
            );
        end
    endgenerate
    wire [15:0] csa4_carry_shifted = {csa4_carry[14:0], 1'b0};

    // =========================================================================
    // STAGE 4: Final Addition (Ripple Carry Adder)
    // =========================================================================
    // Add the final two rows: csa4_sum + csa4_carry_shifted
    wire [15:0] final_product;
    wire [16:0] final_carry;  // One extra bit for carry chain

    assign final_carry[0] = 1'b0;

    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_final_add
            fa final_fa (
                .a     (csa4_sum[k]),
                .b     (csa4_carry_shifted[k]),
                .cin   (final_carry[k]),
                .sum   (final_product[k]),
                .carry (final_carry[k+1])
            );
        end
    endgenerate

    // =========================================================================
    // STAGE 5: Output Register
    // =========================================================================
    // Register the output (capture flop) for clean timing analysis
    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_product <= 16'd0;
        end else begin
            o_product <= final_product;
        end
    end

endmodule
