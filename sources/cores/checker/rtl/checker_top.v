`include "checker.vh"

module checker_top #(
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
	output irq,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output wb_ack_o,
	input wb_we_i,

  // PCIE hardware
  output [3:0] pci_exp_txp,
  output [3:0] pci_exp_txn,
  input [3:0] pci_exp_rxp,
  input [3:0] pci_exp_rxn,

  input pci_sys_clk_p,
  input pci_sys_clk_n,
  input pci_sys_reset_n
);

reg sys_clk_2;

always @(posedge sys_clk) begin
  sys_clk_2 <= ~sys_clk_2;
end

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
wire [31:0] wb_dat_o_mem;
wire [31:0] wb_dat_o_hm;
wire wb_ack_o_mem;
wire wb_ack_o_hm;
wire wb_we_i_mem;
wire wb_we_i_hm;

wire single_en;

wire [47:0] i_data;
wire [63:0] hm_data;
wire mpu_en;
wire [15:0] i_addr;
wire user_irq;
wire [63:0] user_data;
wire [63:0] hm_addr;
wire hm_start;
wire mpu_error;

wire hm_en;
wire hm_end;
wire hm_timeout;
wire hm_error;
wire mpu_rst;

wire [15:0] stat_trn_cpt_tx;
wire [15:0] stat_trn_cpt_rx;
wire [31:0] stat_trn;

reg mpu_rst_2;
reg hm_start_once;
reg started;
wire [47:0] i_data_rst_2;
wire mpu_error_2;

initial begin
  mpu_rst_2 = 1'b0;
  hm_start_once = 1'b0;
  started = 1'b0;
  sys_clk_2 <= 1'b0;
end

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

  .irq(irq),

  .stat_trn_cpt_tx(stat_trn_cpt_tx),
  .stat_trn_cpt_rx(stat_trn_cpt_rx),
  .stat_trn(stat_trn)
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

wire mode_ack_2;
checker_psync ps_mode_ack_2 (
  .clk1(sys_clk),
  .i(mode_ack),
  .clk2(sys_clk_2),
  .o(mode_ack_2)
);

wire sys_rst_2;
checker_psync ps_sys_rst_2 (
  .clk1(sys_clk),
  .i(sys_rst),
  .clk2(sys_clk_2),
  .o(sys_rst_2)
);

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

wire hm_end_2;
checker_psync ps_hm_end_2 (
  .clk1(sys_clk),
  .i(hm_end),
  .clk2(sys_clk_2),
  .o(hm_end_2)
);

wire hm_timeout_2;
checker_psync ps_hm_timeout_2 (
  .clk1(sys_clk),
  .i(hm_timeout),
  .clk2(sys_clk_2),
  .o(hm_timeout_2)
);

wire hm_error_2;
checker_psync ps_hm_error_2 (
  .clk1(sys_clk),
  .i(hm_error),
  .clk2(sys_clk_2),
  .o(hm_error_2)
);

checker_single #(
  .mode(`CHECKER_MODE_SINGLE)
) single (
  .sys_clk(sys_clk_2),
  .sys_rst(sys_rst_2),

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end_single),
  .mode_data(mode_data_single),
  .mode_irq(mode_irq_single),
  .mode_ack(mode_ack_2),
  .mode_error(mode_error_single),

  .mpu_en(single_en),
  .mpu_rst(single_rst),
  .mpu_error(mpu_error_2 | hm_timeout_2 | hm_error_2),
  .mpu_user_data(user_data),
  .mpu_user_irq(user_irq)
);

/**
 * MPU
 *
 * MPU is sys_ck / 2 because of the synced RAMB36E1
 */

always @(posedge sys_clk_2) begin
  if (mpu_rst) begin
    mpu_rst_2 <= 1'b1;
  end else begin
    mpu_rst_2 <= 1'b0;
  end
end

assign i_data_rst_2 = (mpu_rst_2 == 1'b1) ? 48'b0 : i_data; 
assign mpu_error_2 = (mpu_rst_2 == 1'b1) ? 1'b0 : mpu_error; 

always @(posedge sys_clk_2) begin
  if (hm_start && ~started) begin
    hm_start_once <= 1'b1;
    started <= 1'b1;
  end else if (hm_start_once) begin
    hm_start_once <= 1'b0;
  end
  if (mpu_en) begin
    started <= 1'b0;
  end
end

mpu_top mpu (
  .sys_clk(sys_clk_2),
  .sys_rst(mpu_rst),
  .en(mpu_en),
  .i_data(i_data_rst_2),
  .hm_data(hm_data),
  .i_addr(i_addr),
  .user_irq(user_irq),
  .user_data(user_data),
  .hm_addr(hm_addr),
  .hm_start(hm_start),
  .error(mpu_error)
);

assign mpu_en = hm_en & single_en;
assign mpu_rst = sys_rst_2 | single_rst;

checker_memory mem (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .mpu_clk(sys_clk),
  .mpu_addr(i_addr),
  .mpu_do(i_data),
  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_we_i(wb_we_i_mem),
  .wb_dat_o(wb_dat_o_mem),
  .wb_ack_o(wb_ack_o_mem)
);

// Memory selection
assign wb_dat_o = (wb_adr_i[15] == 1'b0) ? wb_dat_o_mem : wb_dat_o_hm;

assign wb_ack_o = (wb_adr_i[15] == 1'b0) ? wb_ack_o_mem : wb_ack_o_hm;

assign wb_we_i_mem = (wb_adr_i[15] == 1'b0) ? wb_we_i : 1'b0;

assign wb_we_i_hm = 1'b0;

assign hm_en = ~hm_start | hm_end_2;

/**
 * PCIE IP CORE instanciation
 */

wire trn_clk;
wire trn_reset_n;
wire trn_lnk_up_n;

wire [5:0] trn_tbuf_av;
wire trn_tcfg_req_n;
wire trn_terr_drop_n;
wire trn_tdst_rdy_n;
wire [63:0] trn_td;
wire trn_trem_n;
wire trn_tsof_n;
wire trn_teof_n;
wire trn_tsrc_rdy_n;
wire trn_tsrc_dsc_n;
wire trn_terrfwd_n;
wire trn_tcfg_gnt_n;
wire trn_tstr_n;

wire [63:0] trn_rd;
wire trn_rrem_n;
wire trn_rsof_n;
wire trn_reof_n;
wire trn_rsrc_rdy_n;
wire trn_rsrc_dsc_n;
wire trn_rerrfwd_n;
wire [6:0] trn_rbar_hit_n;
wire trn_rdst_rdy_n;
wire trn_rnp_ok_n;

wire [11:0] trn_fc_cpld;
wire [7:0] trn_fc_cplh;
wire [11:0] trn_fc_npd;
wire [7:0] trn_fc_nph;
wire [11:0] trn_fc_pd;
wire [7:0] trn_fc_ph;
wire [2:0] trn_fc_sel;

wire [31:0] cfg_do;
wire cfg_rd_wr_done_n;
wire [31:0] cfg_di;
wire [3:0] cfg_byte_en_n;
wire [9:0] cfg_dwaddr;
wire cfg_wr_en_n;
wire cfg_rd_en_n;

wire cfg_err_cor_n;
wire cfg_err_ur_n;
wire cfg_err_ecrc_n;
wire cfg_err_cpl_timeout_n;
wire cfg_err_cpl_abort_n;
wire cfg_err_cpl_unexpect_n;
wire cfg_err_posted_n;
wire cfg_err_locked_n;
wire [47:0] cfg_err_tlp_cpl_header;
wire cfg_err_cpl_rdy_n;
wire cfg_interrupt_n;
wire cfg_interrupt_rdy_n;
wire cfg_interrupt_assert_n;
wire [7:0] cfg_interrupt_di;
wire [7:0] cfg_interrupt_do;
wire [2:0] cfg_interrupt_mmenable;
wire cfg_interrupt_msienable;
wire cfg_interrupt_msixenable;
wire cfg_interrupt_msixfm;
wire cfg_turnoff_ok_n;
wire cfg_to_turnoff_n;
wire cfg_trn_pending_n;
wire cfg_pm_wake_n;
wire [7:0] cfg_bus_number;
wire [4:0] cfg_device_number;
wire [2:0] cfg_function_number;
wire [15:0] cfg_status;
wire [15:0] cfg_command;
wire [15:0] cfg_dstatus;
wire [15:0] cfg_dcommand;
wire [15:0] cfg_lstatus;
wire [15:0] cfg_lcommand;
wire [15:0] cfg_dcommand2;
wire [2:0] cfg_pcie_link_state_n;
wire [63:0] cfg_dsn;

wire [2:0] pl_initial_link_width;
wire [1:0] pl_lane_reversal_mode;
wire pl_link_gen2_capable;
wire pl_link_partner_gen2_supported;
wire pl_link_upcfg_capable;
wire [5:0] pl_ltssm_state;
wire pl_received_hot_rst;
wire pl_sel_link_rate;
wire [1:0] pl_sel_link_width;
wire pl_directed_link_auton;
wire [1:0] pl_directed_link_change;
wire pl_directed_link_speed;
wire [1:0] pl_directed_link_width;
wire pl_upstream_prefer_deemph;

wire sys_clk_c;
wire sys_reset_n_c;

hm_top mhm (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst_2 | single_rst),
  .en(single_en),
  .hm_page_addr(mode_addr),
  .hm_page_offset(hm_addr[11:0]),
  .hm_start(hm_start_once),
  .hm_end(hm_end),
  .hm_data(hm_data),
  .hm_timeout(hm_timeout),
  .hm_error(hm_error),

  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_we_i(wb_we_i_hm),
  .wb_dat_o(wb_dat_o_hm),
  .wb_ack_o(wb_ack_o_hm),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),
  .trn_tbuf_av(trn_tbuf_av),
  .trn_tcfg_req_n(trn_tcfg_req_n),
  .trn_terr_drop_n(trn_terr_drop_n),
  .trn_tdst_rdy_n(trn_tdst_rdy_n),
  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),
  .trn_fc_cpld(trn_fc_cpld),
  .trn_fc_cplh(trn_fc_cplh),
  .trn_fc_npd(trn_fc_npd),
  .trn_fc_nph(trn_fc_nph),
  .trn_fc_pd(trn_fc_pd),
  .trn_fc_ph(trn_fc_ph),
  .trn_td(trn_td),
  .trn_trem_n(trn_trem_n),
  .trn_tsof_n(trn_tsof_n),
  .trn_teof_n(trn_teof_n),
  .trn_tsrc_rdy_n(trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(trn_tsrc_dsc_n),
  .trn_terrfwd_n(trn_terrfwd_n),
  .trn_tcfg_gnt_n(trn_tcfg_gnt_n),
  .trn_tstr_n(trn_tstr_n),
  .trn_rdst_rdy_n(trn_rdst_rdy_n),
  .trn_rnp_ok_n(trn_rnp_ok_n),
  .trn_fc_sel(trn_fc_sel),

  .stat_trn_cpt_tx(stat_trn_cpt_tx),
  .stat_trn_cpt_rx(stat_trn_cpt_rx),
  .stat_trn(stat_trn)
);

`ifdef SIMULATION
assign trn_clk = sys_clk;
assign trn_lnk_up_n = 1'b0;
assign trn_tdst_rdy_n = 1'b0;
assign trn_rsrc_rdy_n = 1'b0;
`else

IBUFDS_GTXE1 refclk_ibuf (
  .O(sys_clk_c),
  .ODIV2(),
  .I(pci_sys_clk_p),
  .IB(pci_sys_clk_n),
  .CEB(1'b0)
);

IBUF sys_reset_n_ibuf (
  .O(sys_reset_n_c),
  .I(pci_sys_reset_n)
);

FDCP #(
  .INIT(1'b1)
) trn_lnk_up_n_int_i (
  .Q (trn_lnk_up_n),
  .D (trn_lnk_up_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)
);

FDCP #(
  .INIT(1'b1)
) trn_reset_n_i (
  .Q (trn_reset_n),
  .D (trn_reset_n_int1),
  .C (trn_clk),
  .CLR (1'b0),
  .PRE (1'b0)
);

/**
 * Core input tie-offs
 */

`define PCI_EXP_EP_OUI 24'h000A35
`define PCI_EXP_EP_DSN_1 {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2 32'h00000001

assign trn_fc_sel = 3'b0; 

assign trn_tecrc_gen_n = 1'b1;

assign cfg_err_cor_n = 1'b1;
assign cfg_err_ur_n = 1'b1;
assign cfg_err_ecrc_n = 1'b1;
assign cfg_err_cpl_timeout_n = 1'b1;
assign cfg_err_cpl_abort_n = 1'b1;
assign cfg_err_cpl_unexpect_n = 1'b1;
assign cfg_err_posted_n = 1'b0;
assign cfg_err_locked_n = 1'b1;
assign cfg_pm_wake_n = 1'b1;
assign cfg_trn_pending_n = 1'b1;

assign cfg_interrupt_assert_n = 1'b1;
assign cfg_interrupt_n = 1'b1;
assign cfg_dwaddr = 0;
assign cfg_rd_en_n = 1;

assign pl_directed_link_change = 0;
assign pl_directed_link_width = 0;
assign pl_directed_link_speed = 0;
assign pl_directed_link_auton = 0;
assign pl_upstream_prefer_deemph = 1'b1;

assign cfg_interrupt_di = 8'b0;

assign cfg_err_tlp_cpl_header = 47'h0;
assign cfg_di = 0;
assign cfg_byte_en_n = 4'hf;
assign cfg_wr_en_n = 1;
assign cfg_dsn = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};

v6_pcie_v1_7 core (
  .pci_exp_txp(pci_exp_txp),
  .pci_exp_txn(pci_exp_txn),

  .pci_exp_rxp(pci_exp_rxp),
  .pci_exp_rxn(pci_exp_rxn),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n_int1),
  .trn_lnk_up_n(trn_lnk_up_n_int1),

  .trn_tbuf_av(trn_tbuf_av),
  .trn_tcfg_req_n(trn_tcfg_req_n),
  .trn_terr_drop_n(trn_terr_drop_n),
  .trn_tdst_rdy_n(trn_tdst_rdy_n),
  .trn_td(trn_td),
  .trn_trem_n(trn_trem_n),
  .trn_tsof_n(trn_tsof_n),
  .trn_teof_n(trn_teof_n),
  .trn_tsrc_rdy_n(trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(trn_tsrc_dsc_n),
  .trn_terrfwd_n(trn_terrfwd_n),
  .trn_tcfg_gnt_n(trn_tcfg_gnt_n),
  .trn_tstr_n(trn_tstr_n),

  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),
  .trn_rdst_rdy_n(trn_rdst_rdy_n),
  .trn_rnp_ok_n(trn_rnp_ok_n),

  .trn_fc_cpld(trn_fc_cpld),
  .trn_fc_cplh(trn_fc_cplh),
  .trn_fc_npd(trn_fc_npd),
  .trn_fc_nph(trn_fc_nph),
  .trn_fc_pd(trn_fc_pd),
  .trn_fc_ph(trn_fc_ph),
  .trn_fc_sel(trn_fc_sel),

  .cfg_do(cfg_do),
  .cfg_rd_wr_done_n(cfg_rd_wr_done_n),
  .cfg_di(cfg_di),
  .cfg_byte_en_n(cfg_byte_en_n),
  .cfg_dwaddr(cfg_dwaddr),
  .cfg_wr_en_n(cfg_wr_en_n),
  .cfg_rd_en_n(cfg_rd_en_n),

  .cfg_err_cor_n(cfg_err_cor_n),
  .cfg_err_ur_n(cfg_err_ur_n),
  .cfg_err_ecrc_n(cfg_err_ecrc_n),
  .cfg_err_cpl_timeout_n(cfg_err_cpl_timeout_n),
  .cfg_err_cpl_abort_n(cfg_err_cpl_abort_n),
  .cfg_err_cpl_unexpect_n(cfg_err_cpl_unexpect_n),
  .cfg_err_posted_n(cfg_err_posted_n),
  .cfg_err_locked_n(cfg_err_locked_n),
  .cfg_err_tlp_cpl_header(cfg_err_tlp_cpl_header),
  .cfg_err_cpl_rdy_n(cfg_err_cpl_rdy_n),
  .cfg_interrupt_n(cfg_interrupt_n),
  .cfg_interrupt_rdy_n(cfg_interrupt_rdy_n),
  .cfg_interrupt_assert_n(cfg_interrupt_assert_n),
  .cfg_interrupt_di(cfg_interrupt_di),
  .cfg_interrupt_do(cfg_interrupt_do),
  .cfg_interrupt_mmenable(cfg_interrupt_mmenable),
  .cfg_interrupt_msienable(cfg_interrupt_msienable),
  .cfg_interrupt_msixenable(cfg_interrupt_msixenable),
  .cfg_interrupt_msixfm(cfg_interrupt_msixfm),
  .cfg_turnoff_ok_n(cfg_turnoff_ok_n),
  .cfg_to_turnoff_n(cfg_to_turnoff_n),
  .cfg_trn_pending_n(cfg_trn_pending_n),
  .cfg_pm_wake_n(cfg_pm_wake_n),
  .cfg_bus_number(cfg_bus_number),
  .cfg_device_number(cfg_device_number),
  .cfg_function_number(cfg_function_number),
  .cfg_status(cfg_status),
  .cfg_command(cfg_command),
  .cfg_dstatus(cfg_dstatus),
  .cfg_dcommand(cfg_dcommand),
  .cfg_lstatus(cfg_lstatus),
  .cfg_lcommand(cfg_lcommand),
  .cfg_dcommand2(cfg_dcommand2),
  .cfg_pcie_link_state_n(cfg_pcie_link_state_n),
  .cfg_dsn(cfg_dsn),
  .cfg_pmcsr_pme_en(),
  .cfg_pmcsr_pme_status(),
  .cfg_pmcsr_powerstate(),

  .pl_initial_link_width(pl_initial_link_width),
  .pl_lane_reversal_mode(pl_lane_reversal_mode),
  .pl_link_gen2_capable(pl_link_gen2_capable),
  .pl_link_partner_gen2_supported(pl_link_partner_gen2_supported),
  .pl_link_upcfg_capable(pl_link_upcfg_capable),
  .pl_ltssm_state(pl_ltssm_state),
  .pl_received_hot_rst(pl_received_hot_rst),
  .pl_sel_link_rate(pl_sel_link_rate),
  .pl_sel_link_width(pl_sel_link_width),
  .pl_directed_link_auton(pl_directed_link_auton),
  .pl_directed_link_change(pl_directed_link_change),
  .pl_directed_link_speed(pl_directed_link_speed),
  .pl_directed_link_width(pl_directed_link_width),
  .pl_upstream_prefer_deemph(pl_upstream_prefer_deemph),

  .sys_clk(sys_clk_c),
  .sys_reset_n(sys_reset_n_c)
);
`endif//SIMULATION

endmodule
