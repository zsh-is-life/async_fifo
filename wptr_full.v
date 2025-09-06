`timescale 1ns / 1ps

// =======================================================
// Write Pointer & Full Flag Logic
// -------------------------------------------------------
// This module manages the write pointer for the FIFO and
// generates the "full" status flag.
// 
// Features:
// - Binary counter for memory addressing
// - Gray-coded pointer for safe synchronization
// - Full flag asserted when next write pointer equals
//   the synchronized read pointer (with MSBs inverted)
// =======================================================

module wptr_full #(
    parameter ADDRSIZE = 4   // Number of address bits
)(
    output reg              wfull,   // FIFO full flag
    output     [ADDRSIZE-1:0] waddr, // Binary write address (to access memory)
    output reg [ADDRSIZE:0] wptr,    // Gray-coded write pointer
    input      [ADDRSIZE:0] wq2_rptr,// Synchronized read pointer
    input                   winc,    // Write enable (increment write pointer)
    input                   wclk,    // Write clock
    input                   wrst_n   // Active-low reset (write domain)
);

    // ---------------------------------------------------
    // Internal signals
    // ---------------------------------------------------
    reg  [ADDRSIZE:0] wbin;        // Binary write pointer
    wire [ADDRSIZE:0] wgraynext;   // Next Gray-coded write pointer
    wire [ADDRSIZE:0] wbinnext;    // Next binary write pointer
    wire              wfull_val;   // Next-state value of wfull flag

    // ---------------------------------------------------
    // Write pointer (binary and Gray-coded) update
    // - wbin increments when winc is asserted and FIFO not full
    // - wptr is the Gray-coded version of wbin
    // ---------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            {wbin, wptr} <= 0;
        else
            {wbin, wptr} <= {wbinnext, wgraynext};
    end

    // ---------------------------------------------------
    // Binary write address (used to access memory)
    // ---------------------------------------------------
    assign waddr = wbin[ADDRSIZE-1:0];

    // ---------------------------------------------------
    // Next binary pointer (increment if winc and not full)
    // ---------------------------------------------------
    assign wbinnext = wbin + (winc & ~wfull);

    // ---------------------------------------------------
    // Convert binary pointer to Gray code (style #2)
    // Formula: Gray = (binary >> 1) ^ binary
    // ---------------------------------------------------
    assign wgraynext = (wbinnext >> 1) ^ wbinnext;

    // ---------------------------------------------------
    // FIFO full condition
    // - When next write pointer equals synchronized read
    //   pointer, except the two MSBs are inverted.
    //
    // Equivalent to a 3-part test:
    //   1. MSB different
    //   2. Next-MSB different
    //   3. Remaining bits equal
    // ---------------------------------------------------
    assign wfull_val = (wgraynext == 
                       {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
                         wq2_rptr[ADDRSIZE-2:0]});

    // ---------------------------------------------------
    // Full flag register
    // - Reset: FIFO not full
    // - Otherwise: update with wfull_val
    // ---------------------------------------------------
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wfull <= 1'b0;
        else
            wfull <= wfull_val;
    end

endmodule

