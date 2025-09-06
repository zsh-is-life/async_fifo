`timescale 1ns / 1ps

// =======================================================
// Read Pointer & Empty Flag Logic
// -------------------------------------------------------
// This module manages the read pointer for the FIFO and
// generates the "empty" status flag.
// 
// Features:
// - Binary counter for memory addressing
// - Gray-coded pointer for safe synchronization
// - Empty flag asserted when next read pointer matches
//   the synchronized write pointer
// =======================================================

module rptr_empty #(
    parameter ADDRSIZE = 4   // Number of address bits
)(
    output reg              rempty,   // FIFO empty flag
    output     [ADDRSIZE-1:0] raddr,  // Binary read address (to access memory)
    output reg [ADDRSIZE:0] rptr,     // Gray-coded read pointer
    input      [ADDRSIZE:0] rq2_wptr, // Synchronized write pointer
    input                   rinc,     // Read enable (increment read pointer)
    input                   rclk,     // Read clock
    input                   rrst_n    // Active-low reset (read domain)
);

    // ---------------------------------------------------
    // Internal signals
    // ---------------------------------------------------
    reg  [ADDRSIZE:0] rbin;        // Binary read pointer
    wire [ADDRSIZE:0] rgraynext;   // Next Gray-coded read pointer
    wire [ADDRSIZE:0] rbinnext;    // Next binary read pointer
    wire              rempty_val;  // Next-state value of rempty flag

    // ---------------------------------------------------
    // Read pointer (binary and Gray-coded) update
    // - rbin increments when rinc is asserted and FIFO not empty
    // - rptr is the Gray-coded version of rbin
    // ---------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            {rbin, rptr} <= 0;
        else
            {rbin, rptr} <= {rbinnext, rgraynext};
    end

    // ---------------------------------------------------
    // Binary read address (used to access memory)
    // ---------------------------------------------------
    assign raddr = rbin[ADDRSIZE-1:0];

    // ---------------------------------------------------
    // Next binary pointer (increment if rinc and not empty)
    // ---------------------------------------------------
    assign rbinnext = rbin + (rinc & ~rempty);

    // ---------------------------------------------------
    // Convert binary pointer to Gray code (style #2)
    // Formula: Gray = (binary >> 1) ^ binary
    // ---------------------------------------------------
    assign rgraynext = (rbinnext >> 1) ^ rbinnext;

    // ---------------------------------------------------
    // FIFO empty condition
    // - True when next Gray-coded read pointer equals
    //   the synchronized write pointer
    // ---------------------------------------------------
    assign rempty_val = (rgraynext == rq2_wptr);

    // ---------------------------------------------------
    // Empty flag register
    // - Reset: FIFO is empty
    // - Otherwise: update with rempty_val
    // ---------------------------------------------------
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty <= 1'b1;
        else
            rempty <= rempty_val;
    end

endmodule

