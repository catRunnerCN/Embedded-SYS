// CSEE 4840 Lab 1: Run and Display Collatz Conjecture Iteration Counts
//
// Spring 2026
//
// By: Peiheng Li
// Uni: pl2978

module lab1( input logic        CLOCK_50,  // 50 MHz Clock input
	     
	     input logic [3:0] 	KEY, // Pushbuttons; KEY[0] is rightmost

	     input logic [9:0] 	SW, // Switches; SW[0] is rightmost

	     // 7-segment LED displays; HEX0 is rightmost
	     output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

	     output logic [9:0] LEDR // LEDs above the switches; LED[0] on right
	     );

   logic 			clk, go, done;   
   logic [31:0] 		start;
   logic [15:0] 		count;

   logic [11:0] 		n;
   
   assign clk = CLOCK_50;
 
   range #(256, 8) // RAM_WORDS = 256, RAM_ADDR_BITS = 8)
         r ( .* ); // Connect everything with matching names

      // KEY[3] = run
      // KEY[2] = reset
      // KEY[0] = increment offset
      // KEY[1] = decrement offset
      logic run_btn, rst_off_btn, inc_btn, dec_btn;
      assign run_btn     = ~KEY[3];
      assign rst_off_btn = ~KEY[2];
      assign dec_btn     = ~KEY[1];
      assign inc_btn     = ~KEY[0];


      logic run_btn_d, rst_off_btn_d, inc_btn_d, dec_btn_d;
      always_ff @(posedge clk) begin
            run_btn_d     <= run_btn;
            rst_off_btn_d <= rst_off_btn;
            inc_btn_d     <= inc_btn;
            dec_btn_d     <= dec_btn;
      end
      wire run_pulse     = run_btn     & ~run_btn_d;
      wire rst_off_pulse = rst_off_btn & ~rst_off_btn_d;
      wire inc_pulse     = inc_btn     & ~inc_btn_d;
      wire dec_pulse     = dec_btn     & ~dec_btn_d;

      logic [7:0] offset;
      // 5 Hz tick: 50_000_000 / 5 = 10_000_000 cycles
      logic [23:0] rep_ctr;
      wire rep_tick = (rep_ctr == 24'd9_999_999);

      always_ff @(posedge clk) begin
      if (rst_off_pulse) begin
            rep_ctr <= 24'd0;
      end else if (rep_tick) begin
            rep_ctr <= 24'd0;
      end else begin
            rep_ctr <= rep_ctr + 24'd1;
      end
      end

      // saturating helpers
      function automatic [7:0] sat_inc8(input [7:0] x);
            if (x == 8'hFF) sat_inc8 = 8'hFF;
            else            sat_inc8 = x + 8'd1;
      endfunction
      function automatic [7:0] sat_dec8(input [7:0] x);
            if (x == 8'h00) sat_dec8 = 8'h00;
            else            sat_dec8 = x - 8'd1;
      endfunction

      always_ff @(posedge clk) begin
            if (rst_off_pulse) begin
            offset <= 8'd0;
            end else begin
            // immediate step on press
            if (inc_pulse && !dec_btn) offset <= sat_inc8(offset);
            if (dec_pulse && !inc_btn) offset <= sat_dec8(offset);

            // repeat while held
            if (rep_tick) begin
                  if (inc_btn && !dec_btn) offset <= sat_inc8(offset);
                  else if (dec_btn && !inc_btn) offset <= sat_dec8(offset);
            end
            end
      end

      // ----------------------------------------------------------------
      // Connect UI to range:
      // start = base n from switches
      // n     = which entry to read (0..255) via offset
      // go    = pulse when KEY[3] pressed
      // ----------------------------------------------------------------
      wire [31:0] base_n = {22'b0, SW};           // switches set the starting n
      wire [31:0] disp_n32 = base_n + {24'b0, offset};

      assign start = base_n;                      // range runs [start .. start+255]
      assign n     = disp_n32[11:0];              // for display: lower 12 bits of actual n

      logic [7:0] addr;
      assign addr = offset;

      // go should be a single-cycle pulse
      assign go = run_pulse;

      // 7-seg display:
      // Leftmost three HEX5..HEX3 show n (lower 12 bits) in hex
      // Rightmost three HEX2..HEX0 show iteration count in hex
      hex7seg h5( n[11:8],  HEX5 );
      hex7seg h4( n[7:4],   HEX4 );
      hex7seg h3( n[3:0],   HEX3 );

      hex7seg h2( count[11:8], HEX2 );
      hex7seg h1( count[7:4],  HEX1 );
      hex7seg h0( count[3:0],  HEX0 );

   
   
  
endmodule
