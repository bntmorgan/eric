`include "checker.vh"

module checker_top #(
	parameter csr_addr = 4'h0
) (
  // System
	input sys_clk,
	input sys_rst,

  input mpu_clk,
	
  // CSR
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

  // IRQ
	output irq,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input wb_we_i
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
wire mode_error;
wire mode_error_dummy;
wire mode_error_single;
wire mode_error_auto;
wire mode_error_read;

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
  .mode_error(mode_error),

  .irq(irq)
);

/**
 * Checkers
 */

assign mode_end = 
  (mode_mode == `CHECKER_MODE_SINGLE) ? mode_end_single :
  (mode_mode == `CHECKER_MODE_AUTO) ? mode_end_auto :
  (mode_mode == `CHECKER_MODE_READ) ? mode_end_read :
  mode_end_dummy; 
// TODO remove
assign mode_end_auto = 1'b0;
assign mode_end_read = 1'b0;
// assign mode_end_single = 1'b0;

assign mode_data = 
  (mode_mode == `CHECKER_MODE_SINGLE) ? mode_data_single :
  (mode_mode == `CHECKER_MODE_AUTO) ? mode_data_auto :
  (mode_mode == `CHECKER_MODE_READ) ? mode_data_read :
  mode_data_dummy; 
// TODO remove
assign mode_data_auto = 64'b0;
assign mode_data_read = 64'b0;
// assign mode_data_single = 64'b0;

assign mode_irq = 
  (mode_mode == `CHECKER_MODE_SINGLE) ? mode_irq_single :
  (mode_mode == `CHECKER_MODE_AUTO) ? mode_irq_auto :
  (mode_mode == `CHECKER_MODE_READ) ? mode_irq_read :
  mode_irq_dummy; 
// TODO remove
assign mode_irq_auto = 1'b0;
assign mode_irq_read = 1'b0;
// assign mode_irq_single = 1'b0;

assign mode_error = 
  (mode_mode == `CHECKER_MODE_SINGLE) ? mode_error_single :
  (mode_mode == `CHECKER_MODE_AUTO) ? mode_error_auto :
  (mode_mode == `CHECKER_MODE_READ) ? mode_error_read :
  mode_error_dummy; 
// TODO remove
assign mode_error_auto = 1'b0;
assign mode_error_read = 1'b0;
// assign mode_error_single = 1'b0;

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
  .mode_ack(mode_ack),
  .mode_error(mode_error_dummy)
);

reg mpu_clk_2;
reg mpu_rst_2;
initial mpu_clk_2  <= 1'b1;
initial mpu_rst_2  <= 1'b0;

checker_single #(
  .mode(`CHECKER_MODE_SINGLE)
) single (
  .sys_clk(mpu_clk_2),
  .sys_rst(sys_rst),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end_single),
  .mode_data(mode_data_single),
  .mode_irq(mode_irq_single),
  .mode_ack(mode_ack),
  .mode_error(mode_error_single),

  .mpu_en(single_en),
  .mpu_rst(single_rst),
  .mpu_error(error),
  .mpu_user_data(user_data),
  .mpu_user_irq(user_irq)
);

/**
 * MPU
 *
 * MPU is sys_ck / 2 because of the synced RAMB36E1
 */

always @(posedge mpu_clk) begin
  mpu_clk_2 <= ~mpu_clk_2;
end

always @(posedge mpu_clk_2) begin
  mpu_rst_2 <= mpu_rst;
end

mpu_top mpu (
  .sys_clk(mpu_clk_2),
  .sys_rst(mpu_rst_2),
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
  .mpu_clk(mpu_clk),
  .mpu_addr(i_addr),
  .mpu_do(i_data),
  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_we_i(wb_we_i),
  .wb_dat_o(wb_dat_o),
  .wb_ack_o(wb_ack_o)
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
