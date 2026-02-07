module range
   #(parameter
     RAM_WORDS = 16,            // Number of counts to store in RAM
     RAM_ADDR_BITS = 4)         // Number of RAM address bits
   (input logic         clk,    // Clock
    input logic 	go,     // Read start and start testing
    input logic [31:0] 	start,  // Number to start from or count to read
    output logic 	done,   // True once memory is filled
    output logic [15:0] count); // Iteration count once finished

   logic 		cgo;    // "go" for the Collatz iterator
   logic                cdone;  // "done" from the Collatz iterator
   logic [31:0] 	n;      // number to start the Collatz iterator

// verilator lint_off PINCONNECTEMPTY
   
   // Instantiate the Collatz iterator
   collatz c1(.clk(clk),
	      .go(cgo),
	      .n(n),
	      .done(cdone),
	      .dout());

   logic [RAM_ADDR_BITS - 1:0] 	 num;         // The RAM address to write
   logic 			 running; // True during the iterations
   logic [15:0] 		 din;                   // Data to write
   logic [15:0] 		 mem[RAM_WORDS - 1:0];  // The RAM itself
   logic                     kick;  // flag to know when collatz started
   logic                     first;   // determine if first run
   
   // Read port: after done, testbench sets start to an address and reads count next cycle
   always_ff @(posedge clk) begin
      if (!done) count <= mem[num];
      else count <= mem[start[RAM_ADDR_BITS-1:0]];
   end

   always_ff @(posedge clk) begin
      if (cgo) cgo <= 1'b0;
   
      if (go && !running && !done) begin
         running <= 1'b1;
         done    <= 1'b0;
         num  <= 4'b0;
         n    <= start;
         din  <= 16'd0;
         cgo   <= 1'b1;
         kick  <= 1'b1;
         first <= 1'b1;
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
	     
