module fml_ddr3_top #(
  // FML parameters
	parameter adr_width = 30,
  // MIG IP CORE parameters
  parameter DQ_WIDTH = 64,
  parameter ROW_WIDTH = 13,
  parameter BANK_WIDTH = 3,
  parameter CS_WIDTH = 1,
  parameter nCS_PER_RANK = 1,
  parameter CKE_WIDTH = 1,
  parameter CK_WIDTH = 1,
  parameter DM_WIDTH = 8,
  parameter DQS_WIDTH = 8,
  parameter ECC_TEST = "OFF",
  parameter DATA_WIDTH = 64,
  parameter PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
  parameter ADDR_WIDTH = 27
) (
  input sys_clk, // @80 MHz
  input sys_rst,

  input [adr_width-1:0] fml_adr,
  input fml_stb,
  input fml_we,
  output fml_ack,
  input [7:0] fml_sel,
  input [63:0] fml_di,
  output [63:0] fml_do,

  // MIG IP CORE parameters
  input ddr3_sys_clk_p, //differential system clocks
  input ddr3_sys_clk_n,
  input ddr3_clk_ref_p, //differential iodelayctrl clk
  input ddr3_clk_ref_n,
  input ddr3_sys_rst, // System reset

  inout [DQ_WIDTH-1:0] ddr3_dq,
  output [ROW_WIDTH-1:0] ddr3_addr,
  output [BANK_WIDTH-1:0] ddr3_ba,
  output ddr3_ras_n,
  output ddr3_cas_n,
  output ddr3_we_n,
  output ddr3_reset_n,
  output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
  output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
  output [CKE_WIDTH-1:0] ddr3_cke,
  output [DM_WIDTH-1:0] ddr3_dm,
  inout [DQS_WIDTH-1:0] ddr3_dqs_p,
  inout [DQS_WIDTH-1:0] ddr3_dqs_n,
  output [CK_WIDTH-1:0] ddr3_ck_p,
  output [CK_WIDTH-1:0] ddr3_ck_n,
  inout sda,
  output scl,
  output phy_init_done
);

wire app_wdf_wren;
wire [(4*PAYLOAD_WIDTH)-1:0] app_wdf_data;
wire [(4*PAYLOAD_WIDTH)/8-1:0] app_wdf_mask;
wire app_wdf_end;
wire [ADDR_WIDTH-1:0] app_addr;
wire [2:0] app_cmd;
wire app_en;
wire app_rdy;
wire app_wdf_rdy;
wire [(4*PAYLOAD_WIDTH)-1:0] app_rd_data;
wire app_rd_data_end;
wire app_rd_data_valid;

wire ui_clk_sync_rst;
wire ui_clk;

// FML Control interface
fml_ddr3_ctlif #(
  .adr_width(adr_width),
  .DQ_WIDTH(DQ_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH),
  .ECC_TEST(ECC_TEST),
  .DATA_WIDTH(DATA_WIDTH),
  .PAYLOAD_WIDTH(PAYLOAD_WIDTH)
) ctrlif (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .ui_clk(ui_clk),
  .ui_clk_sync_rst(ui_clk_sync_rst),
  .fml_adr(fml_adr),
  .fml_stb(fml_stb),
  .fml_we(fml_we),
  .fml_ack(fml_ack),
  .fml_sel(fml_sel),
  .fml_di(fml_di),
  .fml_do(fml_do),
  .app_rdy(app_rdy),
  .app_rd_data(app_rd_data),
  .app_rd_data_end(app_rd_data_end),
  .app_rd_data_valid(app_rd_data_valid),
  .app_wdf_rdy(app_wdf_rdy),
  .app_addr(app_addr),
  .app_cmd(app_cmd),
  .app_en(app_en),
  .app_wdf_data(app_wdf_data),
  .app_wdf_end(app_wdf_end),
  .app_wdf_mask(app_wdf_mask),
  .app_wdf_wren(app_wdf_wren)
);

endmodule
