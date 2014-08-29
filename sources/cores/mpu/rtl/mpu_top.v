module mpu_top #(
  parameter csr_addr = 4'h0
) (
  // System
  input sys_clk,
  input sys_rst,

  // CSR bus
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output [31:0] csr_do,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input wb_we_i,
  
  // Host memory bus
  output [63:0] hm_addr,
  input [63:0] hm_data,

  // IRQ
  output irq
);

reg mpu_clk;
wire mpu_en;
wire mpu_rst;
wire error;
wire [63:0] user_data;
wire user_irq;

wire [15:0] i_addr;
wire [47:0] i_data;

always @(posedge sys_clk) begin
  mpu_clk <= ~mpu_clk;
end

initial begin
  mpu_clk <= 1'b0;
end

mpu_ctlif #(
  .csr_addr(csr_addr)
) ctlif (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .mpu_clk(mpu_clk),
  .mpu_en(mpu_en),
  .mpu_rst(mpu_rst),
  .user_irq(user_irq),
  .user_data(user_data),
  .error(error),
  .irq(irq)
);

mpu mpu (
  .sys_clk(mpu_clk),
  .sys_rst(mpu_rst),
  .en(mpu_en),
  .i_data(i_data),
  .i_addr(i_addr),
  .user_irq(user_irq),
  .user_data(user_data),
  .hm_addr(hm_addr),
  .hm_data(hm_data),
  .error(error)
);

mpu_memory mem (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .mpu_clk(sys_clk),
  .mpu_addr(i_addr),
  .mpu_do(i_data),
  .wb_adr_i(wb_adr_i),
  .wb_dat_o(wb_dat_o),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_ack_o(wb_ack_o),
  .wb_we_i(wb_we_i)
);

endmodule
