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
wire [7:0] cctrl;

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

checker_dummy #(
  .mode(`CHECKER_MODE_DUMMY)
) dummy (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .cmode(cmode),
  .cstart(cstart),
  .caddr(caddr),
  .cend(cend),
  .cctrl(cctrl)
);

endmodule
