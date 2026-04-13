// Simple Structural Verilog Netlist using SkyWater 130nm HD Library
// Two D Flip-Flops with Enable and a Buffer in between
// Ps Note: as the logic to enable the second flop is bit complicated we are using the
// reset pin of flop to mimic the same so as to keep this lab simple. 

module flop_buffer_netlist (
    input wire clk,      // Clock signal
    input wire en,       // Enable signal
    input wire d_in,     // Data input
    output wire q_out    // Data output
);

    wire buf_out;      // Output of the buffer
    wire rst_n;        // Active-low reset generated internally
    wire div2_q;       // Output of divide-by-2 logic
    wire div2_q_inv;   // Inverted signal for divide-by-2 logic

    // Inverter for divide-by-2 logic
    sky130_fd_sc_hd__inv_1 inverter (
        .A(div2_q),      // Input signal
        .Y(div2_q_inv)   // Inverted output
    );

    // Divide-by-2 logic using T Flip-Flop behavior
    sky130_fd_sc_hd__dfrbp_1 div2_ff (
        .CLK(clk),       // Clock input
        .RESET_B(1'b1),  // No reset for divider
        .D(div2_q_inv),  // Toggle using inverter
        .Q(div2_q)       // Divide-by-2 output
    );

    assign rst_n = div2_q;  // rst_n generated from divide-by-2 output

    // First D Flip-Flop with Enable
    sky130_fd_sc_hd__dfrbp_1 dff1 (
        .CLK(clk),       // Clock
        .RESET_B(en), // Active-low Reset
        .D(d_in),        // Data input
        .Q(buf_out)      // Output to buffer
    );

    // Buffer between flip-flops
    sky130_fd_sc_hd__buf_12 u_custom (
        .A(buf_out),     // Input from first flip-flop
        .X(buf_2out)      // Output to second flip-flop
    );

    // Second D Flip-Flop with Enable
    sky130_fd_sc_hd__dfrbp_1 dff2 (
        .CLK(clk),       // Clock
        .RESET_B(rst_n), // Active-low Reset
        .D(buf_2out),     // Input from buffer
        .Q(q_out)        // Output
    );

endmodule

