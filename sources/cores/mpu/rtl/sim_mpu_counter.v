`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;

reg en;
reg [15:0] incr;
reg load;
reg [15:0] data;

// Outputs
wire [15:0] ip;

`SIM_SYS_CLK

/**
 * Tested components
 */
mpu_counter counter (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  
  .en(en),
  .incr(incr),
  .load(load),
  .data(data),

  .out(ip)
);

always @(*)
begin
  $display("-");
  $display("en %d", en);
  $display("incr 0x%x", incr);
  $display("load %d", load);
  $display("data 0x%x", data);
  $display("ip 0x%x", ip);
end

initial begin
  en <= 1'b0;
  incr <= 16'h0;
  load <= 1'b0;
  data <= 16'b0;
end

/**
 * Simulation
 */
initial
begin

  # 8 $display("--- en <- 1 && incr <- 4");
  en <= 1'b1;
  incr <= 16'h4;

  # 8 $display("--- en <- 0");
  en <= 1'b0;

  # 8 $display("--- en <- 1");
  en <= 1'b1;

  # 8 $display("--- load <- 1 && data <- 4");
  load <= 1'b1;
  data <= 16'h4;

  # 8 $display("--- load <- 0");
  load <= 1'b0;

  # 8 $display("--- rst <- 1");
  sys_rst <= 1'b1;

  # 8 $finish;
end

endmodule
