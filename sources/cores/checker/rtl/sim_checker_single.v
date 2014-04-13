`include "checker.vh"
`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;

reg [1:0] mode_mode;
reg mode_start;
reg [63:0] mode_addr;
reg mpu_error;
reg mpu_user_irq;
reg [63:0] mpu_user_data;
reg mode_ack;

// Ouputs
wire mode_end;
wire [63:0] mode_data;
wire mode_irq;
wire mode_error;
wire mpu_en;
wire mpu_rst;

`SIM_SYS_CLK

/**
 * Tested components
 */
checker_single single (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end),
  .mode_data(mode_data),
  .mode_error(mode_error),
  .mode_ack(mode_ack),
  .mode_irq(mode_irq),

  .mpu_en(mpu_en),
  .mpu_rst(mpu_rst),
  .mpu_error(mpu_error),
  .mpu_user_data(mpu_user_data),
  .mpu_user_irq(mpu_user_irq)
);

always @(*)
begin
  $display("-");
  $display("mode_mode %d", mode_mode);
  $display("mode_start %d", mode_start);
  $display("mode_addr 0x%x", mode_addr);
  $display("mode_end %d", mode_end);
  $display("mode_data 0x%x", mode_data);
  $display("mode_irq 0x%x", mode_irq);
  $display("mode_error 0x%x", mode_error);
  $display("mpu_en %x", mpu_en);
  $display("mpu_rst %x", mpu_rst);
  $display("mpu_error %x", mpu_error);
  $display("mpu_user_data %x", mpu_user_data);
  $display("mpu_user_irq %x", mpu_user_irq);
end

initial begin
  mode_mode <= 2'b00;
  mode_start <= 1'b0;
  mode_addr <= 64'h0000000000000000;
  mpu_error <= 1'b0;
  mpu_user_irq <= 1'b0;
  mpu_user_data <= 64'b0;
  mode_ack <= 1'b0;

  $display("--- mode_addr <= 0x10");
end

/**
 * Simulation
 */
initial
begin
  `SIM_DUMPFILE

  // START
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b1;

  // END
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b0;

  // START
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b1;

  // END
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b0;

  // START
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b1;

  // mpu_user_irq
  # 8 $display("--- mpu_user_irq = 1");
  mpu_user_irq <= 1'b1;
  mpu_user_data <= 64'hb00b;

  // mpu_user_irq
  # 8 $display("--- Ack irq");
  mode_ack <= 1'b1;
  # 2
  mode_ack <= 1'b0;
  mpu_user_irq <= 1'b0;
  mpu_user_data <= 64'h0;

  // Error
  # 8 $display("--- Error");
  mpu_error <= 1'b1;
  # 2
  mpu_error <= 1'b0;

  // START
  # 4 $display("--- mode_start = 1");
  mode_start <= 1'b1;

  // mpu_user_irq
  # 8 $display("--- mpu_user_irq = 1");
  mpu_user_irq <= 1'b1;
  mpu_user_data <= 64'h0000;

  # 40 $finish;
end

always @(posedge mode_end, posedge mode_error) mode_start <= 1'b0; 

endmodule
