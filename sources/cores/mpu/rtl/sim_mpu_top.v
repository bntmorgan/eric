`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;
wire [47:0] i_data;
wire user_en;
wire [63:0] hm_data;
wire hm_en;

// Outputs
wire [15:0] i_addr;
wire user_irq;
wire [63:0] user_data;
wire [63:0] hm_addr;
wire hm_start;

`SIM_SYS_CLK

/**
 * Tested components
 */
mpu_top mpu (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .i_data(i_data),
  .user_en(user_en),
  .hm_data(hm_data),
  .hm_en(hm_en),
  .i_addr(i_addr),
  .user_irq(user_irq),
  .user_data(user_data),
  .hm_addr(hm_addr),
  .hm_start(hm_start)
);

mpu_memory mem (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .r_addr(i_addr),
  .r_data(i_data)
);

mpu_int int (
  .irq(user_irq),
  .data(user_data),
  .en(user_en)
);

mpu_host_memory mhm (
  .addr(hm_addr),
  .start(hm_start),
  .data(hm_data),
  .en(hm_en)
);

always @(*) begin
  $display("-");
  $display("i_addr %x", i_addr);
  $display("i_data %x", i_data);
  $display("user_en %x", user_en);
  $display("hm_data %x", hm_data);
  $display("hm_en %x", hm_en);
  $display("user_irq %x", user_irq);
  $display("user_data %x", user_data);
  $display("hm_addr %x", hm_addr);
  $display("hm_start %x", hm_start);
end

/**
 * Simulation
 */
initial
begin

  # 16 $finish;
end

endmodule
