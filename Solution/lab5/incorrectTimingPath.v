// Two-stage D Flip-Flop Chain with sky130_fd_sc_hd__mux2_1 and sky130_fd_sc_hd__dfxtp_1

module two_stage_dff_with_mux (
    input wire CLK,       // Clock signal
    input wire D_in,      // Data input
    input wire select,    // Select signal for both multiplexers
    input wire dummy_Din, 
    input wire dummy_Din2, 
    output wire Q_out     // Data output
);

    wire Q1, MUX1_out, MUX2_out;  // Intermediate signals

    // First D Flip-Flop Instance
    sky130_fd_sc_hd__dfxtp_1 dff1 (
        .CLK(CLK),  // Clock input
        .D(D_in),   // Data input
        .Q(Q1)      // Data output
    );

    // First 2-to-1 MUX Instance (between dff1 and dff2)
    sky130_fd_sc_hd__mux2_1 mux1 (
        .A0(Q1),     // Input 0 from first DFF
        .A1(dummy_Din), // Feedback or alternate path
        .S(select),  // Select signal
        .X(MUX1_out) // Output to second DFF
    );

    // Second 2-to-1 MUX Instance
    sky130_fd_sc_hd__mux2_1 mux2 (
        .A0(dummy_Din2),
        .A1(custom_out),  
        .S(select),     
        .X(MUX2_out)    
    );

    sky130_fd_sc_hd__buf_12 u_custom (
        .A(MUX1_out),     // Input from first flip-flop
        .X(custom_out)      // Output to second flip-flop
    );

    // Second D Flip-Flop Instance
    sky130_fd_sc_hd__dfxtp_1 dff2 (
        .CLK(CLK),  // Clock input
        .D(MUX2_out),     // MUX output as Data input
        .Q(Q_out)   // Final output
    );

endmodule

