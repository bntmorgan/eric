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
wire [1:0] cmode;
wire cstart;
wire cstop;
wire [63:0] caddr;
wire cend;
wire cend_dummy;
wire cend_single;
wire cend_auto;
wire cend_read;
wire [7:0] cctrl;
wire [7:0] cctrl_dummy;
wire [7:0] cctrl_single;
wire [7:0] cctrl_auto;
wire [7:0] cctrl_read;

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

  .cmode(cmode),
  .cstart(cstart),
  .caddr(caddr),
  .cend(cend),
  .cctrl(cctrl),

  .irq(irq)
);

/**
 * Checkers
 */
wire single_en;

assign cend = cend_dummy | cend_single | cend_auto | cend_read;
// TODO remove
assign cend_auto = 1'b0;
assign cend_read = 1'b0;

assign cctrl = cctrl_dummy | cctrl_single | cctrl_auto | cctrl_read;
// TODO remove
assign cctrl_auto = 8'b0;
assign cctrl_read = 8'b0;

checker_dummy #(
  .mode(`CHECKER_MODE_DUMMY)
) dummy (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .cmode(cmode),
  .cstart(cstart),
  .caddr(caddr),
  .cend(cend_dummy),
  .cctrl(cctrl_dummy)
);

checker_single #(
  .mode(`CHECKER_MODE_SINGLE)
) single (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .cmode(cmode),
  .cstart(cstart),
  .caddr(caddr),
  .cend(cend_single),
  .cctrl(cctrl_single),

  .mpu_en(single_en)
);

/**
 * MPU
 */
wire [47:0] i_data;
wire [63:0] hm_data;
wire en;
wire [15:0] i_addr;
wire user_irq;
wire [63:0] user_data;
wire [63:0] hm_addr;
wire hm_start;

wire hm_en;
wire user_en;

mpu_top mpu (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .en(en),
  .i_data(i_data),
  .hm_data(hm_data),
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
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
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

assign en = user_en & hm_en & single_en;

endmodule
