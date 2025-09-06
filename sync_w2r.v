`timescale 1ns / 1ps

// =======================================================
// Synchronizer: Write Pointer into Read Clock Domain
// -------------------------------------------------------
// This module synchronizes the write pointer (wptr)
// into the read clock domain to avoid metastability.
// 
// Technique:
// - Two flip-flop synchronizer
// - wptr sampled into rq1_wptr, then into rq2_wptr
// =======================================================

module sync_w2r #(
    parameter ADDRSIZE = 4   // Number of address bits
)(
    output reg [ADDRSIZE:0] rq2_wptr, // Synchronized write pointer
    input      [ADDRSIZE:0] wptr,     // Write pointer from write domain
    input                   rclk,     // Read clock
    input                   rrst_n    // Active-low reset (read domain)
);

    // First stage of synchronizer
    reg [ADDRSIZE:0] rq1_wptr;

    // ---------------------------------------------------
    // Synchronization process
    // ---------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            // On reset, clear both synchronizer stages
            {rq2_wptr, rq1_wptr} <= 0;
        else
            // Shift the write pointer across clock domain
            {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr};
    end

endmodule

