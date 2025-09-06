`timescale 1ns / 1ps

// =======================================================
// FIFO Top-Level Module (Asynchronous FIFO)
// -------------------------------------------------------
// This module ties together the FIFO memory, read pointer
// control, write pointer control, and the synchronizers
// required for safe operation across two clock domains.
//
// Features:
// - Separate read and write clocks (asynchronous FIFO)
// - Full and Empty flag generation
// - Pointer synchronization between clock domains
// =======================================================

module fifo #(
    parameter DSIZE = 8,  // Width of each FIFO data word
    parameter ASIZE = 4   // Number of address bits (FIFO depth = 2^ASIZE)
)(
    output [DSIZE-1:0] rdata,   // Data output from FIFO
    output             wfull,   // FIFO full flag
    output             rempty,  // FIFO empty flag
    input  [DSIZE-1:0] wdata,   // Data input to FIFO
    input              winc,    // Write enable (increment write pointer)
    input              wclk,    // Write clock
    input              wrst_n,  // Active-low write-domain reset
    input              rinc,    // Read enable (increment read pointer)
    input              rclk,    // Read clock
    input              rrst_n   // Active-low read-domain reset
);

    // ---------------------------------------------------
    // Internal signals
    // ---------------------------------------------------
    wire [ASIZE-1:0] waddr, raddr;           // Write and read addresses
    wire [ASIZE:0]   wptr, rptr;             // Binary write and read pointers (extended with extra MSB)
    wire [ASIZE:0]   wq2_rptr, rq2_wptr;     // Synchronized pointers across clock domains

    // ---------------------------------------------------
    // Synchronize read pointer into write clock domain
    // Ensures write logic sees a stable read pointer
    // **FIX:** Parameter override corrected from ASIZE to ADDRSIZE
    // ---------------------------------------------------
    sync_r2w #(
        .ADDRSIZE(ASIZE)
    ) sync_r2w (
        .wq2_rptr(wq2_rptr),
        .rptr    (rptr),
        .wclk    (wclk),
        .wrst_n  (wrst_n)
    );

    // ---------------------------------------------------
    // Synchronize write pointer into read clock domain
    // Ensures read logic sees a stable write pointer
    // **FIX:** Parameter override corrected from ASIZE to ADDRSIZE
    // ---------------------------------------------------
    sync_w2r #(
        .ADDRSIZE(ASIZE)
    ) sync_w2r (
        .rq2_wptr(rq2_wptr),
        .wptr    (wptr),
        .rclk    (rclk),
        .rrst_n  (rrst_n)
    );

    // ---------------------------------------------------
    // FIFO Memory Block
    // Stores the actual data words. Addressed by waddr/raddr.
    // ---------------------------------------------------
    fifomem #(
        .DATASIZE(DSIZE),
        .ADDRSIZE(ASIZE)
    ) fifomem (
        .rdata (rdata),
        .wdata (wdata),
        .waddr (waddr),
        .raddr (raddr),
        .wclken(winc),
        .wfull (wfull),
        .wclk  (wclk)
    );

    // ---------------------------------------------------
    // Read pointer and Empty flag logic
    // - Generates rptr and raddr
    // - Detects when FIFO is empty
    // **FIX:** Parameter override corrected from ASIZE to ADDRSIZE
    // ---------------------------------------------------
    rptr_empty #(
        .ADDRSIZE(ASIZE)
    ) rptr_empty (
        .rempty   (rempty),
        .raddr    (raddr),
        .rptr     (rptr),
        .rq2_wptr (rq2_wptr),
        .rinc     (rinc),
        .rclk     (rclk),
        .rrst_n   (rrst_n)
    );

    // ---------------------------------------------------
    // Write pointer and Full flag logic
    // - Generates wptr and waddr
    // - Detects when FIFO is full
    // **FIX:** Parameter override corrected from ASIZE to ADDRSIZE
    // ---------------------------------------------------
    wptr_full #(
        .ADDRSIZE(ASIZE)
    ) wptr_full (
        .wfull    (wfull),
        .waddr    (waddr),
        .wptr     (wptr),
        .wq2_rptr (wq2_rptr),
        .winc     (winc),
        .wclk     (wclk),
        .wrst_n   (wrst_n)
    );

endmodule


