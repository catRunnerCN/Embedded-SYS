module lab1(
  input  logic        CLOCK_50,
  input  logic [3:0]  KEY,
  input  logic [9:0]  SW,
  output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
  output logic [9:0]  LEDR
);

  logic        clk;
  assign clk = CLOCK_50;

  // -------- Buttons (active-low) --------
  logic run_btn, rst_btn, dec_btn, inc_btn;
  assign run_btn = ~KEY[3];   // KEY3 (leftmost)
  assign rst_btn = ~KEY[2];   // KEY2
  assign dec_btn = ~KEY[1];   // KEY1
  assign inc_btn = ~KEY[0];   // KEY0

  // Edge detect
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

  // -------- Hold-to-repeat (~5Hz) --------
  logic [21:0] repeat_ctr = 22'd0;
  always_ff @(posedge clk) repeat_ctr <= repeat_ctr + 22'd1;
  wire repeat_tick = (repeat_ctr == 22'd0);

  wire inc_step = inc_pulse | (inc_btn & repeat_tick);
  wire dec_step = dec_pulse | (dec_btn & repeat_tick);

  logic [7:0] offset = 8'd0;
  always_ff @(posedge clk) begin
    if (rst_pulse) offset <= 8'd0;
    else if (inc_step && !dec_btn) offset <= offset + 8'd1;
    else if (dec_step && !inc_btn) offset <= offset - 8'd1;
  end

  // -------- Range interface --------
  logic        go, done;
  logic [31:0] start;
  logic [15:0] count16;
  logic [11:0] count;
  logic [11:0] n;

  assign go = run_pulse;

  // latch: ignore raw done until we've actually started a run
  logic started = 1'b0;
  logic finished = 1'b0;

  always_ff @(posedge clk) begin
    if (run_pulse) begin
      started  <= 1'b1;
      finished <= 1'b0;
    end else if (started && done) begin
      finished <= 1'b1;
    end
  end

  range #(256, 8) r (
    .clk   (clk),
    .go    (go),
    .start (start),
    .done  (done),
    .count (count16)
  );

  assign count = count16[11:0];
  logic unused_count16_hi;
  assign unused_count16_hi = ^count16[15:12]; // consume high bits for lint

  wire [31:0] base_n = {22'b0, SW};
  assign n = base_n[11:0] + {4'b0, offset};

  // start mux:
  // - before finished: provide starting N from switches
  // - after finished: provide RAM address = offset
  assign start = finished ? {24'b0, offset} : base_n;

  // -------- 7-seg --------
  hex7seg h5(n[11:8], HEX5);
  hex7seg h4(n[7:4],  HEX4);
  hex7seg h3(n[3:0],  HEX3);

  hex7seg h2(count[11:8], HEX2);
  hex7seg h1(count[7:4],  HEX1);
  hex7seg h0(count[3:0],  HEX0);

  // -------- LEDs --------
  assign LEDR[7:0] = SW[7:0];
  assign LEDR[8]   = go;        // pulse (hard to see)
  assign LEDR[9]   = finished;  // only lights after a real run completes

endmodule

