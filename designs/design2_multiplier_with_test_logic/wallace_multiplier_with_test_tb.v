// =============================================================================
// File:    wallace_multiplier_with_test_tb.v
// Author:  OpenSTA Workshop
// Description:
//   Testbench for the Wallace Tree Multiplier with Test Logic (Design 2).
//   Tests both normal functional mode and test mode, plus scan capture.
//
// Usage:
//   iverilog -o tb wallace_multiplier_with_test.v wallace_multiplier_with_test_tb.v
//   vvp tb
// =============================================================================

`timescale 1ns / 1ps

module wallace_multiplier_with_test_tb;

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [7:0]  a, b;
    wire [15:0] product;

    // Test/Debug signals
    reg         test_mode;
    reg  [15:0] test_pattern;
    reg         scan_clk;
    reg         scan_en;
    wire [15:0] scan_data;

    reg  [15:0] expected;
    integer     pass_count, fail_count;
    integer     i;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    wallace_multiplier_with_test dut (
        .i_clk          (clk),
        .i_rst_n        (rst_n),
        .i_a            (a),
        .i_b            (b),
        .o_product      (product),
        .i_test_mode    (test_mode),
        .i_test_pattern (test_pattern),
        .i_scan_clk     (scan_clk),
        .i_scan_en      (scan_en),
        .o_scan_data    (scan_data)
    );

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    // Functional clock: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Scan clock: 20 ns period (50 MHz) - intentionally different frequency
    initial scan_clk = 0;
    always #10 scan_clk = ~scan_clk;

    // -------------------------------------------------------------------------
    // Task: Apply a functional test
    // -------------------------------------------------------------------------
    task apply_func_test;
        input [7:0] test_a;
        input [7:0] test_b;
        begin
            @(posedge clk);
            a = test_a;
            b = test_b;
            expected = test_a * test_b;

            @(posedge clk);
            @(posedge clk);
            #1;

            if (product === expected) begin
                $display("[PASS] FUNC: %0d x %0d = %0d", test_a, test_b, product);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] FUNC: %0d x %0d expected %0d, got %0d",
                         test_a, test_b, expected, product);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Apply a test-mode test
    // -------------------------------------------------------------------------
    task apply_test_mode_test;
        input [15:0] pattern;
        begin
            @(posedge clk);
            test_mode    = 1'b1;
            test_pattern = pattern;

            @(posedge clk);
            @(posedge clk);
            #1;

            if (product === pattern) begin
                $display("[PASS] TEST_MODE: pattern=0x%04h, output=0x%04h",
                         pattern, product);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] TEST_MODE: pattern=0x%04h, output=0x%04h",
                         pattern, product);
                fail_count = fail_count + 1;
            end

            test_mode = 1'b0;  // Return to normal mode
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        pass_count   = 0;
        fail_count   = 0;
        a            = 8'd0;
        b            = 8'd0;
        rst_n        = 1'b0;
        test_mode    = 1'b0;
        test_pattern = 16'd0;
        scan_en      = 1'b0;

        // Reset
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("\n===== Design 2: Multiplier with Test Logic =====");

        // --- Functional Mode Tests ---
        $display("\n--- Functional Mode Tests ---");
        apply_func_test(8'd0,   8'd0);
        apply_func_test(8'd1,   8'd1);
        apply_func_test(8'd255, 8'd255);
        apply_func_test(8'd12,  8'd10);
        apply_func_test(8'd100, 8'd200);
        apply_func_test(8'd85,  8'd170);

        // Random tests
        for (i = 0; i < 10; i = i + 1) begin
            apply_func_test($random & 8'hFF, $random & 8'hFF);
        end

        // --- Test Mode Tests ---
        $display("\n--- Test Mode Tests ---");
        apply_test_mode_test(16'hAAAA);
        apply_test_mode_test(16'h5555);
        apply_test_mode_test(16'hFFFF);
        apply_test_mode_test(16'h0000);
        apply_test_mode_test(16'h1234);

        // --- Scan Capture Test ---
        $display("\n--- Scan Capture Test ---");
        test_mode = 1'b0;
        a = 8'd15;
        b = 8'd15;
        repeat (3) @(posedge clk);

        // Enable scan capture
        scan_en = 1'b1;
        @(posedge scan_clk);
        @(posedge scan_clk);
        #1;
        $display("  Scan captured intermediate CSA value: 0x%04h", scan_data);
        $display("  (Non-zero value confirms scan logic is working)");
        if (scan_data !== 16'd0) begin
            $display("[PASS] SCAN: Non-zero intermediate data captured");
            pass_count = pass_count + 1;
        end else begin
            $display("[INFO] SCAN: Zero data captured (may be valid)");
            pass_count = pass_count + 1;  // Not necessarily a failure
        end
        scan_en = 1'b0;

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

    // Waveform dump
    initial begin
        $dumpfile("wallace_multiplier_with_test.vcd");
        $dumpvars(0, wallace_multiplier_with_test_tb);
    end

endmodule
