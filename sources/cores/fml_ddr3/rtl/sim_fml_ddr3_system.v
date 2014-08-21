module main #(
  parameter DQ_WIDTH = 64,
  parameter ROW_WIDTH = 14,
  parameter BANK_WIDTH = 3,
  parameter CS_WIDTH = 1,
  parameter nCS_PER_RANK = 1,
  parameter CKE_WIDTH = 1,
  parameter CK_WIDTH = 1,
  parameter DM_WIDTH = 8,
  parameter DQS_WIDTH = 8,
  parameter ECC_TEST = "OFF",
  parameter DATA_WIDTH = 64,
  parameter ADDR_WIDTH = 28
) ();

`include "sim.v"
`include "sim_wb.v"
`define DRAM_DEPTH 27

//
// Test FML BRG 2
//

wire [`DRAM_DEPTH-1:0]	fml_brg_adr_test;
wire fml_brg_stb_test;
wire fml_brg_we_test;
wire fml_brg_ack_test;
wire [7:0] fml_brg_sel_test;
wire [63:0]fml_brg_dw_test;
wire [63:0]fml_brg_dr_test;

wire [`DRAM_DEPTH-1:0] fml_adr_test;
wire fml_stb_test;
wire fml_we_test;
wire fml_eack_test;
wire [7:0] fml_sel_test;
wire [63:0] fml_dw_test;
wire [63:0] fml_dr_test;


wire dcb_stb_test;
wire [`DRAM_DEPTH-1:0] dcb_adr_test;
wire [63:0] dcb_dat_test;
wire dcb_hit_test;

fmlbrg #(
	.fml_depth(`DRAM_DEPTH),
	.cache_depth(6)
) fmlbrg_test (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.wb_adr_i(wb_adr_i),
	.wb_cti_i(wb_cti_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	.wb_sel_i(wb_sel_i),
	.wb_stb_i(wb_stb_i),
	.wb_cyc_i(wb_cyc_i),
	.wb_ack_o(wb_ack_o),
	.wb_we_i(wb_we_i),

	.fml_adr(fml_brg_adr_test),
	.fml_stb(fml_brg_stb_test),
	.fml_we(fml_brg_we_test),
	.fml_ack(fml_brg_ack_test),
	.fml_sel(fml_brg_sel_test),
	.fml_di(fml_brg_dr_test),
	.fml_do(fml_brg_dw_test),

	.dcb_stb(dcb_stb_test),
	.dcb_adr(dcb_adr_test),
	.dcb_dat(dcb_dat_test),
	.dcb_hit(dcb_hit_test)
);
assign dcb_stb_test = 1'b0;
assign dcb_adr_test = {`DRAM_DEPTH{1'bx}};

fmlarb #(
	.fml_depth(`DRAM_DEPTH)
) fmlarb_test (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	/* VGA framebuffer (high priority) */
	.m0_adr({`DRAM_DEPTH{1'bx}} /* fml_vga_adr */),
	.m0_stb(1'b0 /* fml_vga_stb */),
	.m0_we(1'b0),
	.m0_ack(/* fml_vga_ack */),
	.m0_sel(8'bx),
	.m0_di(64'bx),
	.m0_do(/* fml_vga_dr */),

	/* WISHBONE bridge */
	.m1_adr(fml_brg_adr_test),
	.m1_stb(fml_brg_stb_test),
	.m1_we(fml_brg_we_test),
	.m1_ack(fml_brg_ack_test),
	.m1_sel(fml_brg_sel_test),
	.m1_di(fml_brg_dw_test),
	.m1_do(fml_brg_dr_test),

	/* TMU, pixel read DMA (texture) */
	/* Also used as memory test port */
	.m2_adr({`DRAM_DEPTH{1'bx}} /* fml_tmuw_adr */),
	.m2_stb(1'b0 /* fml_tmuw_stb */),
	.m2_we(1'b1),
	.m2_ack(/* fml_tmuw_ack */),
	.m2_sel(8'bx /* fml_tmuw_sel */),
	.m2_di(64'bx /* fml_tmuw_dw */),
	.m2_do(),

	/* TMU, pixel write DMA */
	.m3_adr({`DRAM_DEPTH{1'bx}} /* fml_tmuw_adr */),
	.m3_stb(1'b0 /* fml_tmuw_stb */),
	.m3_we(1'b1),
	.m3_ack(/* fml_tmuw_ack */),
	.m3_sel(8'bx /* fml_tmuw_sel */),
	.m3_di(64'bx /* fml_tmuw_dw */),
	.m3_do(),

	/* TMU, pixel read DMA (destination) */
	.m4_adr({`DRAM_DEPTH{1'bx}} /* fml_tmudr_adr */),
	.m4_stb(1'b0 /* fml_tmudr_stb */),
	.m4_we(1'b0),
	.m4_ack(/* fml_tmudr_ack */),
	.m4_sel(8'bx),
	.m4_di(64'bx),
	.m4_do(/* fml_tmudr_dr */),

	/* Video in */
	.m5_adr({`DRAM_DEPTH{1'bx}} /* fml_videoin_adr */),
	.m5_stb(1'b0 /* fml_videoin_stb */),
	.m5_we(1'b1),
	.m5_ack(/* fml_videoin_ack */),
	.m5_sel(8'hff),
	.m5_di(64'bx /* fml_videoin_dw */),
	.m5_do(),

	.s_adr(fml_adr_test),
	.s_stb(fml_stb_test),
	.s_we(fml_we_test),
	.s_eack(fml_eack_test),
	.s_sel(fml_sel_test),
	.s_di(fml_dr_test),
	.s_do(fml_dw_test)
);

fml_ddr3_top #(
	.adr_width(`DRAM_DEPTH),
  .DQ_WIDTH(DQ_WIDTH),
  .ROW_WIDTH(ROW_WIDTH),
  .BANK_WIDTH(BANK_WIDTH),
  .CS_WIDTH(CS_WIDTH),
  .nCS_PER_RANK(nCS_PER_RANK),
  .CKE_WIDTH(CKE_WIDTH),
  .CK_WIDTH(CK_WIDTH),
  .DM_WIDTH(DM_WIDTH),
  .DQS_WIDTH(DQS_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH)
) ddr3 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

	.fml_adr(fml_adr_test),
	.fml_stb(fml_stb_test),
	.fml_we(fml_we_test),
	.fml_ack(fml_eack_test),
	.fml_sel(fml_sel_test),
	.fml_di(fml_dw_test),
	.fml_do(fml_dr_test)
);

integer i, idx;
initial begin
  // Dump registers
  for (idx = 0; idx < 4; idx = idx + 1) begin
    $dumpvars(0,ddr3.ctlif.read_buf[idx]);
    $dumpvars(0,ddr3.ctlif.write_buf[idx]);
  end

  sys_rst <= 1'b1;
  waitclock;
  sys_rst <= 1'b0;

  waitnclock(10);

//  wbwrite(32'h10000040, 32'hcacacaca);
//  waitnclock(10);
//
//  wbread(32'h10000040);
//  waitnclock(10);
//  wbread(32'h10000044);
//  waitnclock(10);
//  wbread(32'h10000048);
//  waitnclock(10);
//  wbread(32'h1000004c);
//  waitnclock(10);
//  wbread(32'h10000050);
//  waitnclock(10);
//  wbread(32'h10000054);
//  waitnclock(10);
//  wbread(32'h10000058);
//  waitnclock(10);
//  wbread(32'h1000005c);
//  waitnclock(10);

  for (i = 0 ; i < 32'h00001000; i = i + 'h8) begin
    // wbread(i);
    wbwrite(i, 32'hcafebabe);
  end

  wbread(32'h10000000); // Cache flush
  waitnclock(10);

  $finish;
end

endmodule
