module range
   #(parameter
     RAM_WORDS = 16,            // Number of counts to store in RAM
     RAM_ADDR_BITS = 4)         // Number of RAM address bits
   (input  logic        clk,    // Clock
    input  logic        go,     // Read start and start testing
    input  logic [31:0] start,  // Number to start from or count to read
    output logic        done,   // True once memory is filled
    output logic [15:0] count); // Iteration count once finished

   // -----------------------------
   // Key fix: initialize state regs
   // -----------------------------
   logic        cgo     = 1'b0;     // "go" for the Collatz iterator (pulse)
   logic        cdone;             // "done" from the Collatz iterator
   logic [31:0] n       = 32'd0;    // number to start the Collatz iterator

// verilator lint_off PINCONNECTEMPTY
   collatz c1(
      .clk (clk),
      .go  (cgo),
      .n   (n),
      .done(cdone),
      .dout()
   );
// verilator lint_on PINCONNECTEMPTY

   logic [RAM_ADDR_BITS - 1:0] num     = '0;     // The RAM address to write
   logic                      running = 1'b0;   // True during the iterations
   logic [15:0]               din     = 16'd0;  // Data to write
   logic [15:0]               mem[RAM_WORDS - 1:0]; // The RAM itself
   logic                      kick    = 1'b0;   // flag to know when collatz started
   logic                      first   = 1'b0;   // determine if first run

   // Read port: after done, testbench sets start to an address and reads count next cycle
   // Recommendation: during running/undone, output 0 (stable, avoids reading uninit mem)
   always_ff @(posedge clk) begin
      if (done) count <= mem[start[RAM_ADDR_BITS-1:0]];
      else      count <= 16'd0;
   end

  always_ff @(posedge clk) begin
    if (cgo) cgo <= 1'b0;

    // KEY FIX: allow restart even if done is stuck high at power-up
    if (go && !running) begin
      running <= 1'b1;
      done    <= 1'b0;     // force clear
      num     <= '0;
      n       <= start;
      din     <= 16'd0;
      cgo     <= 1'b1;
      kick    <= 1'b1;
      first   <= 1'b1;
    end
      else if (running) begin
         // Wait until the new collatz run has actually started
         if (kick) begin
            if (!cdone) begin
               kick <= 1'b0;
               // add 1 except for the first time
               if (!first) din <= din + 16'd1;
               first <= 1'b0;
            end
         end
         else begin
            if (!cdone) begin
               din <= din + 16'd1;
            end
            else begin
               mem[num] <= din + 16'd1;
               if (num == RAM_ADDR_BITS'(RAM_WORDS-1)) begin
                  done    <= 1'b1;
                  running <= 1'b0;
                  kick    <= 1'b0;
               end
               else begin
                  num  <= num + 1'b1;
                  n    <= n + 32'd1;
                  din  <= 16'd0;

                  cgo  <= 1'b1;
                  kick <= 1'b1;
               end
            end
         end
      end
   end

endmodule

