`timescale 1ns / 1ps

// =======================================================
// Synchronizer: Read Pointer into Write Clock Domain
// -------------------------------------------------------
// This module synchronizes the read pointer (rptr)
// into the write clock domain to avoid metastability.
// 
// Technique:
// - Two flip-flop synchronizer
// - rptr sampled into wq1_rptr, then into wq2_rptr
// =======================================================

module sync_r2w #(
    parameter ADDRSIZE = 4   // Number of address bits
)(
    output reg [ADDRSIZE:0] wq2_rptr, // Synchronized read pointer
    input      [ADDRSIZE:0] rptr,     // Read pointer from read domain
    input                   wclk,     // Write clock
    input                   wrst_n    // Active-low reset (write domain)
);

    // First stage of synchronizer
    reg [ADDRSIZE:0] wq1_rptr;

    // ---------------------------------------------------
    // Synchronization process
    // ---------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            // On reset, clear both synchronizer stages
            {wq2_rptr, wq1_rptr} <= 0;
        else
            // Shift the read pointer across clock domain
            {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr};
    end

endmodule

