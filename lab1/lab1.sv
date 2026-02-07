// CSEE 4840 Lab 1: Run and Display Collatz Conjecture Iteration Counts
//
// Spring 2023
//
// By: <your name here>
// Uni: <your uni here>

module lab1( input logic        CLOCK_50,  // 50 MHz Clock input

             input logic [3:0]  KEY,       // Pushbuttons; KEY[0] is rightmost

             input logic [9:0]  SW,        // Switches; SW[0] is rightmost

             // 7-segment LED displays; HEX0 is rightmost
             output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,

             output logic [9:0] LEDR       // LEDs above the switches; LED[0] on right
             );

   logic        clk, go, done;
   logic [31:0] start;
   logic [15:0] count;
   logic [11:0] n;

   assign clk = CLOCK_50;

   range #(256, 8) // RAM_WORDS = 256, RAM_ADDR_BITS = 8
   r ( .* ); // Connect everything with matching names

   // KEY[3] = run, KEY[2] = reset offset, KEY[1] = decrement offset, KEY[0] = increment offset
   logic run_btn, rst_btn, dec_btn, inc_btn;
   assign run_btn = ~KEY[3];
   assign rst_btn = ~KEY[2];
   assign dec_btn = ~KEY[1];
   assign inc_btn = ~KEY[0];

   // Rising-edge pulse generation for active-high button signals
   logic run_btn_d, rst_btn_d, dec_btn_d, inc_btn_d;
   always_ff @(posedge clk) begin
      run_btn_d <= run_btn;
      rst_btn_d <= rst_btn;
      dec_btn_d <= dec_btn;
      inc_btn_d <= inc_btn;
   end

   wire run_pulse = run_btn & ~run_btn_d;
   wire rst_pulse = rst_btn & ~rst_btn_d;
   wire dec_pulse = dec_btn & ~dec_btn_d;
   wire inc_pulse = inc_btn & ~inc_btn_d;

   // Offset for selecting one of 256 computed results
   logic [7:0] offset;
   always_ff @(posedge clk) begin
      if (rst_pulse) begin
         offset <= 8'd0;
      end else if (inc_pulse && !dec_btn) begin
         if (offset != 8'hFF) offset <= offset + 8'd1;
      end else if (dec_pulse && !inc_btn) begin
         if (offset != 8'h00) offset <= offset - 8'd1;
      end
   end

   wire [31:0] base_n   = {22'b0, SW};
   wire [31:0] disp_n32 = base_n + {24'b0, offset};

   // During run (or before first completion), range needs base start value.
   // After completion, range reads RAM using start[7:0] as address.
   assign start = (go || !done) ? base_n : {24'b0, offset};
   assign go    = run_pulse;
   assign n     = disp_n32[11:0];

   // Left three digits: selected n value (base + offset)
   hex7seg h5( n[11:8], HEX5 );
   hex7seg h4( n[7:4],  HEX4 );
   hex7seg h3( n[3:0],  HEX3 );

   // Right three digits: Collatz iteration count
   hex7seg h2( count[11:8], HEX2 );
   hex7seg h1( count[7:4],  HEX1 );
   hex7seg h0( count[3:0],  HEX0 );

   // LED status: lower 8 bits show offset, LEDR[8]=go pulse, LEDR[9]=done
   assign LEDR[7:0] = offset;
   assign LEDR[8]   = go;
   assign LEDR[9]   = done;

endmodule
