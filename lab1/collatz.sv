module collatz( input logic         clk,   // Clock
		input logic 	    go,    // Load value from n; start iterating
		input logic  [31:0] n,     // Start value; only read when go = 1
		output logic [31:0] dout,  // Iteration value: true after go = 1
		output logic 	    done); // True when dout reaches 1

   logic [31:0] next_dout;

   always_comb begin
      if (dout[0]) next_dout = (dout << 1) + dout + 32'd1; // 3*n + 1
      else         next_dout = dout >> 1;
   end

   always_ff @(posedge clk) begin
      if (go) begin
         dout <= n;
         done <= (n == 32'd1);
      end else if (!done) begin
         dout <= next_dout;
         done <= (next_dout == 32'd1);
      end
   end

endmodule
