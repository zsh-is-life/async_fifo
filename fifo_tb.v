`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
//
// Module: fifo_tb
//
// Description:
// Testbench for the asynchronous FIFO module.
// - Uses two different clock frequencies for write and read domains.
// - Employs a scoreboard with a model queue to verify data integrity.
// - Contains specific tests for basic fill/drain, full condition, and
//   empty condition.
//
//////////////////////////////////////////////////////////////////////////////////
module fifo_tb;

  // Params
  parameter DSIZE = 8;
  parameter ASIZE = 3;
  localparam DEPTH = 1 << ASIZE; // DEPTH will be 8

  // DUT I/O
  reg  [DSIZE-1:0] wdata;
  wire [DSIZE-1:0] rdata;
  wire             wfull, rempty;
  reg              winc, rinc, wclk, rclk, wrst_n, rrst_n;

  // Instantiate the Device Under Test (DUT)
  fifo #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE)
  ) u_fifo (
    .rdata (rdata),
    .wdata (wdata),
    .wfull (wfull),
    .rempty(rempty),
    .winc  (winc),
    .rinc  (rinc),
    .wclk  (wclk),
    .rclk  (rclk),
    .wrst_n(wrst_n),
    .rrst_n(rrst_n)
  );

  // Scoreboard / Model
  reg [DSIZE-1:0] model_q [0:4095]; // A simple queue to model expected data
  integer         q_wr;               // Write pointer for the model queue
  integer         q_rd;               // Read pointer for the model queue
  integer         errors;             // Error counter
  integer         seed = 1;

  // Clock Generation
  always #5  wclk = ~wclk; // 100 MHz write clock
  always #10 rclk = ~rclk; // 50 MHz read clock

  // Read data sampling
  // This logic correctly samples the read data when a read is valid
  reg             rvalid_q;
  reg [DSIZE-1:0] rdata_q;

  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rvalid_q <= 1'b0;
      rdata_q  <= {DSIZE{1'b0}};
    end else begin
      rvalid_q <= (rinc && !rempty);
      rdata_q  <= rdata; // Sample the data output of the FIFO
    end
  end

  // Scoreboard: Capture write data
  // When the DUT accepts a write, store the same data in our model queue.
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      q_wr <= 0;
    end else if (winc && !wfull) begin
      model_q[q_wr] <= wdata;
      q_wr <= q_wr + 1;
    end
  end

  // Scoreboard: Compare read data
  // When a valid read occurs, compare the received data with our model.
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      q_rd <= 0;
    end else if (rvalid_q) begin
      if (rdata_q !== model_q[q_rd]) begin
        $display("[%0t] ERROR: Read data mismatch! DUT=%0h, Expected=%0h", $time, rdata_q, model_q[q_rd]);
        errors = errors + 1;
      end
      q_rd <= q_rd + 1;
    end
  end

  // Waveform dump setup
  initial begin
    $dumpfile("fifo_tb.vcd");
    $dumpvars(0, fifo_tb);
  end

  // Reset Task
  task reset_fifo;
    integer i;
    begin
      $display("[%0t] Applying reset...", $time);
      wrst_n = 1'b0; rrst_n = 1'b0;
      for (i = 0; i < 4096; i = i + 1) begin
        model_q[i] = 0;
      end
      repeat (3) @(posedge wclk);
      repeat (3) @(posedge rclk);
      wrst_n = 1'b1; rrst_n = 1'b1;
      @(posedge wclk);
      @(posedge rclk);
      $display("[%0t] Reset released.", $time);
    end
  endtask

  // Push Task: Write data to FIFO
  task push(input [DSIZE-1:0] d);
    begin
      @(negedge wclk);
      winc  = 1'b1;
      wdata = d;
      @(negedge wclk);
      winc  = 1'b0;
    end
  endtask

  // Pop Task: Read data from FIFO
  task pop;
    begin
      @(negedge rclk);
      rinc = 1'b1;
      @(negedge rclk);
      rinc = 1'b0;
    end
  endtask


  // Main test sequence
  initial begin
    // Initialization
    wclk=0; rclk=0;
    winc=0; rinc=0;
    wdata=0; errors=0; q_wr=0; q_rd=0;

    reset_fifo();

    // TEST 1: Write N items then read N items
    $display("[%0t] TEST 1: Simple write/read test started.", $time);
    repeat (DEPTH - 2) begin
      if (!wfull) push({$random} % (2**DSIZE)); // **FIXED**: Use constrained random
    end
    #100; // Wait a bit
    repeat (DEPTH - 2) begin
      if (!rempty) pop();
    end
    #200;

    // TEST 2: Fill FIFO completely and test full flag
    $display("[%0t] TEST 2: Fill-to-full test started.", $time);
    while (!wfull) begin
      push({$random} % (2**DSIZE));
    end
    $display("[%0t] FIFO is full. Attempting 3 extra writes (should be ignored).", $time);
    repeat (3) begin
      push($urandom()); // Push some more data
    end
    #200;

    // TEST 3: Drain FIFO completely and test empty flag
    $display("[%0t] TEST 3: Drain-to-empty test started.", $time);
    while (!rempty) begin
      pop();
    end
    $display("[%0t] FIFO is empty. Attempting 3 extra reads (should be ignored).", $time);
    repeat (3) begin
      pop();
    end
    #200;
    
    // Final check
    if (q_wr !== q_rd) begin
        $display("ERROR: Scoreboard mismatch! Items written = %0d, Items read = %0d", q_wr, q_rd);
        errors = errors + 1;
    end

    if (errors == 0) begin
      $display("---------------------------------");
      $display("---         TEST PASS         ---");
      $display("---------------------------------");
    end else begin
      $display("---------------------------------");
      $display("---         TEST FAIL         ---");
      $display("--- Total Errors: %0d", errors);
      $display("---------------------------------");
    end
    
    $finish;
  end

endmodule



