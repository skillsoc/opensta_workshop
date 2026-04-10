// =============================================================================
// File:    wallace_multiplier_tb.v
// Author:  OpenSTA Workshop
// Description:
//   Testbench for the 8-bit Wallace Tree Multiplier.
//   Verifies correctness with directed test cases and random tests.
//
//   How to run (with Icarus Verilog):
//     iverilog -o tb wallace_multiplier.v wallace_multiplier_tb.v
//     vvp tb
// =============================================================================

`timescale 1ns / 1ps

module wallace_multiplier_tb;

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [7:0]  a, b;
    wire [15:0] product;

    // Expected result for checking
    reg  [15:0] expected;
    integer     pass_count, fail_count;
    integer     i;

    // -------------------------------------------------------------------------
    // Instantiate the Design Under Test (DUT)
    // -------------------------------------------------------------------------
    wallace_multiplier dut (
        .i_clk     (clk),
        .i_rst_n   (rst_n),
        .i_a       (a),
        .i_b       (b),
        .o_product (product)
    );

    // -------------------------------------------------------------------------
    // Clock Generation: 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Task: Apply a single test vector and check after 2 clock cycles
    //       (1 cycle for input register, 1 cycle for output register)
    // -------------------------------------------------------------------------
    task apply_test;
        input [7:0] test_a;
        input [7:0] test_b;
        begin
            @(posedge clk);
            a = test_a;
            b = test_b;
            expected = test_a * test_b;  // Golden reference

            // Wait 2 clock edges for pipeline: input_reg -> combo -> output_reg
            @(posedge clk);
            @(posedge clk);
            #1; // Small delay to let output settle

            if (product === expected) begin
                $display("[PASS] %0d x %0d = %0d (got %0d)",
                         test_a, test_b, expected, product);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0d x %0d = %0d (got %0d)",
                         test_a, test_b, expected, product);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Initialize
        pass_count = 0;
        fail_count = 0;
        a     = 8'd0;
        b     = 8'd0;
        rst_n = 1'b0;   // Assert reset

        // Hold reset for a few cycles
        repeat (3) @(posedge clk);
        rst_n = 1'b1;   // Release reset
        @(posedge clk);

        $display("\n===== Wallace Tree Multiplier Testbench =====");
        $display("--- Directed Tests ---");

        // --- Directed Test Cases ---
        // Edge cases
        apply_test(8'd0,   8'd0);     // 0 x 0 = 0
        apply_test(8'd0,   8'd255);   // 0 x 255 = 0
        apply_test(8'd255, 8'd0);     // 255 x 0 = 0
        apply_test(8'd1,   8'd1);     // 1 x 1 = 1
        apply_test(8'd1,   8'd255);   // 1 x 255 = 255
        apply_test(8'd255, 8'd1);     // 255 x 1 = 255
        apply_test(8'd255, 8'd255);   // 255 x 255 = 65025

        // Powers of 2
        apply_test(8'd2,   8'd2);     // 4
        apply_test(8'd4,   8'd8);     // 32
        apply_test(8'd16,  8'd16);    // 256
        apply_test(8'd128, 8'd2);     // 256

        // General values
        apply_test(8'd12,  8'd10);    // 120
        apply_test(8'd100, 8'd200);   // 20000
        apply_test(8'd85,  8'd170);   // 14450
        apply_test(8'd123, 8'd45);    // 5535

        // --- Random Tests ---
        $display("\n--- Random Tests (20 vectors) ---");
        for (i = 0; i < 20; i = i + 1) begin
            apply_test($random & 8'hFF, $random & 8'hFF);
        end

        // --- Summary ---
        $display("\n===== Test Summary =====");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("========================\n");

        if (fail_count > 0)
            $display("*** TEST FAILED ***");
        else
            $display("*** ALL TESTS PASSED ***");

        $finish;
    end

    // -------------------------------------------------------------------------
    // Optional: Dump waveforms for debugging
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("wallace_multiplier.vcd");
        $dumpvars(0, wallace_multiplier_tb);
    end

endmodule
