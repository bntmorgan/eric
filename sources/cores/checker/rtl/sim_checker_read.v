module main();

`include "sim.v"

// Inputs
reg [1:0] mode_mode;
reg mode_start;
reg [63:0] mode_addr;
reg mode_ack;
reg hm_end;
reg hm_timeout;
reg hm_error;

// Outputs
wire mode_end;
wire [63:0] mode_data;
wire mode_irq;
wire mode_error;
wire [63:0] hm_page_addr;
wire hm_start;

initial begin
  mode_mode <= 0;
  mode_start <= 0;
  mode_addr <= 0;
  mode_ack <= 0;
  hm_end <= 0;
  hm_timeout <= 0;
  hm_error <= 0;
end

checker_read read (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end),
  .mode_data(mode_data),
  .mode_irq(mode_irq),
  .mode_ack(mode_ack),
  .mode_error(mode_error),
  .hm_page_addr(hm_page_addr),
  .hm_start(hm_start),
  .hm_end(hm_end),
  .hm_timeout(hm_timeout),
  .hm_error(hm_error)
);

initial begin
  waitnclock(8);

  // Starting
  mode_start <= 1'b1;
  mode_addr <= 64'h1000;
  waitclock;

  // Waiting
  waitnclock(20);

  // Ending
  hm_end <= 1'b1;
  waitclock;
  hm_end <= 1'b0;

  waitnclock(20);

  // Starting
  mode_start <= 1'b1;
  mode_addr <= 64'h1000;
  waitclock;

  // Waiting
  waitnclock(20);

  // Ending
  mode_start <= 1'b0;

  waitnclock(20);

  // Starting
  mode_start <= 1'b1;
  mode_addr <= 64'h1000;
  waitclock;

  // Waiting
  waitnclock(20);

  // Ending
  hm_error <= 1'b1;
  waitclock;
  hm_error <= 1'b0;

  waitnclock(20);

  // Starting
  mode_start <= 1'b1;
  mode_addr <= 64'h1000;
  waitclock;

  // Waiting
  waitnclock(20);

  // Ending
  hm_timeout <= 1'b1;
  waitclock;
  hm_timeout <= 1'b0;

  waitnclock(20);
  $finish();
end

always @(*) begin
  if (mode_end | mode_error == 1'b1) begin
    mode_start = 1'b0;
  end
end

endmodule
