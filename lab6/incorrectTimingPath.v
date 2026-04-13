// Two-stage D Flip-Flop Chain with Buffer, MUX, and Divide-by-2 Clock using sky130_fd_sc_hd__dfxtp_1

module two_stage_dff_with_buffer (
    input wire CLK,       // Clock signal
    input wire Test_CLK,       // Clock signal
    input wire D_in,      // Data input
    input wire select,    // Select signal for MUX (0: CLK, 1: CLK_div2)
    output wire Q_out     // Data output
);

    wire Q1, BUF_out, CLK_div2, MUX_out, INV_out;  // Intermediate signals

    // Inverter Instance for Clock Divider
    sky130_fd_sc_hd__inv_1 clk_inverter (
        .A(CLK_div2),   // Input signal
        .Y(INV_out)     // Inverted output
    );

   sky130_fd_sc_hd__inv_1 clk_inverter2 (
        .A(CLK_div2),   // Input signal
        .Y(INV_out_invertedClk)     // Inverted output
    );

 sky130_fd_sc_hd__dfxtp_1 clk_div_ff (
        .CLK(CLK),      // Clock input
        .D(INV_out),    // Toggling the output to divide clock by 2
        .Q(CLK_div2)    // Divided clock output
    );

    // Clock Divider by 2 using sky130_fd_sc_hd__dfxtp_1 D Flip-Flop
  //  sky130_fd_sc_hd__dfxtp_1 clk_div_ff (
  //      .CLK(CLK),      // Clock input
  //      .D(CLK_div2),    // Toggling the output to divide clock by 2
  //      .Q(CLK_div2)    // Divided clock output
  //  );

    // First D Flip-Flop Instance
    sky130_fd_sc_hd__dfxtp_1 dff1 (
        .CLK(CLK),  // Clock input
        .D(D_in),   // Data input
        .Q(Q1)      // Data output
    );

    // Buffer Instance
    sky130_fd_sc_hd__buf_12 buf1 (
        .A(Q1),     // Input from first DFF
        .X(BUF_out) // Buffered output to second DFF
    );

    // MUX Instance to select between CLK and CLK_div2
    sky130_fd_sc_hd__mux2_1 clk_mux (
        .A0(Test_CLK),       // Input 0: Normal clock
        .A1(CLK_div2),  // Input 1: Divided clock
        .S(select),     // Select signal
        .X(MUX_out)     // Output to second DFF
    );

    // Second D Flip-Flop Instance (Clocked by MUX output)
    sky130_fd_sc_hd__dfxtp_1 dff2 (
        .CLK(MUX_out),  // MUX-selected clock input
        .D(BUF_out),    // Buffered Data input
        .Q(Q_out)       // Final output
    );

endmodule

