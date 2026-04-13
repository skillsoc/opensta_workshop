// Verilog module demonstrating a D flip-flop (sky130_fd_sc_hd__dfxtp_1) driving a buffer and another flip-flop

module dff_with_buffer (
    input wire clk,     // Clock signal
    input data_port,       // Data input to the first D flip-flop
    output output_port       // Final output after the second D flip-flop
);

    // Intermediate signals
    wire q_int;         // Output of the first D flip-flop
    wire buf_out;       // Output of the buffer
    wire data_port;
    wire output_port;    
    // Instance of the first D flip-flop
    sky130_fd_sc_hd__dfxtp_1 u_dff1 (
        .CLK(clk),   // Connect clock
        .D(data_port),       // Connect data input
        .Q(q_int)    // Intermediate output
    );

    // Instance of a buffer
    sky130_fd_sc_hd__buf_1 u_buf (
        .A(q_int),   // Input to the buffer
        .X(buf_out)  // Output of the buffer
    );

    // Instance of the second D flip-flop
    sky130_fd_sc_hd__dfxtp_1 u_dff2 (
        .CLK(clk),   // Connect clock
        .D(buf_out), // Connect buffer output
        .Q(output_port)        // Final output
    );

endmodule

