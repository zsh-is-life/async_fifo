`timescale 1ns / 1ps
// =======================================================
// FIFO Memory Module (Generic RTL)
// -------------------------------------------------------
// Implements the storage array for the FIFO using a
// synthesizable register array.
// - Read operation: asynchronous (combinational read)
// - Write operation: synchronous (on posedge of wclk)
// =======================================================

module fifomem #(
    parameter DATASIZE = 8,   // Memory data word width
    parameter ADDRSIZE = 4    // Number of memory address bits
)(
    output [DATASIZE-1:0] rdata,  // Data read from memory
    input  [DATASIZE-1:0] wdata,  // Data to write into memory
    input  [ADDRSIZE-1:0] waddr,  // Write address
    input  [ADDRSIZE-1:0] raddr,  // Read address
    input                 wclken, // Write enable
    input                 wfull,  // Full flag (blocks writes when FIFO is full)
    input                 wclk    // Write clock
);

    // ---------------------------------------------------
    // Memory depth = 2^ADDRSIZE
    // Example: if ADDRSIZE = 4 → DEPTH = 16 words
    // ---------------------------------------------------
    localparam DEPTH = 1 << ADDRSIZE;

    // Register array representing the FIFO memory
    reg [DATASIZE-1:0] mem [0:DEPTH-1];

    // ---------------------------------------------------
    // Asynchronous read:
    // Output data is continuously driven by the
    // contents of the memory at the read address.
    // ---------------------------------------------------
    assign rdata = mem[raddr];

    // ---------------------------------------------------
    // Synchronous write:
    // On each rising edge of wclk, store wdata at waddr
    // if write enable is asserted and FIFO is not full.
    // ---------------------------------------------------
    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

endmodule

