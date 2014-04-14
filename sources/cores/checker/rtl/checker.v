`include "checker.vh"

module checker #(
	parameter csr_addr = 4'h0
) (
  // System
	input sys_clk,
	input sys_rst,
	
  // CSR
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

  // IRQ
	output irq
);

// Wires
wire [1:0] mode_mode;
wire mode_start;
wire mode_ack;
wire cstop;
wire [63:0] mode_addr;
wire mode_end;
wire mode_end_dummy;
wire mode_end_single;
wire mode_end_auto;
wire mode_end_read;
wire [63:0] mode_data;
wire [63:0] mode_data_dummy;
wire [63:0] mode_data_single;
wire [63:0] mode_data_auto;
wire [63:0] mode_data_read;
wire mode_irq;
wire mode_irq_dummy;
wire mode_irq_single;
wire mode_irq_auto;
wire mode_irq_read;

wire single_en;

wire [47:0] i_data;
wire [63:0] hm_data;
wire mpu_en;
wire [15:0] i_addr;
wire user_irq;
wire [63:0] user_data;
wire [63:0] hm_addr;
wire hm_start;
wire error;

wire hm_en;
wire mpu_rst;

// Control interface
checker_ctlif #(
  .csr_addr(csr_addr)
) ctlif (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end),
  .mode_data(mode_data),
  .mode_irq(mode_irq),
  .mode_ack(mode_ack),

  .irq(irq)
);

/**
 * Checkers
 */

assign mode_end = mode_end_dummy | mode_end_single | mode_end_auto
  | mode_end_read;
// TODO remove
assign mode_end_auto = 1'b0;
assign mode_end_read = 1'b0;

assign mode_data = mode_data_dummy | mode_data_single | mode_data_auto
  | mode_data_read;
// TODO remove
assign mode_data_auto = 64'b0;
assign mode_data_read = 64'b0;

assign mode_irq = mode_irq_dummy | mode_irq_single | mode_irq_auto
  | mode_irq_read;
// TODO remove
assign mode_irq_auto = 1'b0;
assign mode_irq_read = 1'b0;

checker_dummy #(
  .mode(`CHECKER_MODE_DUMMY)
) dummy (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end_dummy),
  .mode_data(mode_data_dummy),
  .mode_irq(mode_irq_dummy),
  .mode_ack(mode_ack)
);

checker_single #(
  .mode(`CHECKER_MODE_SINGLE)
) single (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end_single),
  .mode_data(mode_data_single),
  .mode_irq(mode_irq_single),
  .mode_ack(mode_ack),

  .mpu_en(single_en),
  .mpu_rst(single_rst),
  .mpu_error(error),
  .mpu_user_data(user_data),
  .mpu_user_irq(user_irq)
);

/**
 * MPU
 */

mpu_top mpu (
  .sys_clk(sys_clk),
  .sys_rst(mpu_rst),
  .en(mpu_en),
  .i_data(i_data),
  .hm_data(hm_data),
  .i_addr(i_addr),
  .user_irq(user_irq),
  .user_data(user_data),
  .hm_addr(hm_addr),
  .hm_start(hm_start),
  .error(error)
);

checker_memory mem (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .mpu_addr(i_addr),
  .mpu_do(i_data)
);

mpu_host_memory mhm (
  .addr(hm_addr),
  .start(hm_start),
  .data(hm_data),
  .en(hm_en)
);

assign mpu_en = hm_en & single_en;
assign mpu_rst = sys_rst | single_rst;

endmodule
