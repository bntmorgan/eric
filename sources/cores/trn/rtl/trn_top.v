module trn_top #(
  parameter PCIE_NUMBER_OF_LANES = 1,
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

  // PCIE hardware
  output [PCIE_NUMBER_OF_LANES - 1:0] pci_exp_txp,
  output [PCIE_NUMBER_OF_LANES - 1:0] pci_exp_txn,
  input [PCIE_NUMBER_OF_LANES - 1:0] pci_exp_rxp,
  input [PCIE_NUMBER_OF_LANES - 1:0] pci_exp_rxn,

  input pci_sys_clk_p,
  input pci_sys_clk_n,
  input pci_sys_reset_n,
  
  // Common Trn interface

  output trn_clk,
  output trn_reset_n,
  output trn_lnk_up_n,

  // Tx
  output [5:0] trn_tbuf_av,
  output trn_tcfg_req_n,
  output trn_terr_drop_n,
  output trn_tdst_rdy_n,

  // Rx
  output [63:0] trn_rd,
  output trn_rrem_n,
  output trn_rsof_n,
  output trn_reof_n,
  output trn_rsrc_rdy_n,
  output trn_rsrc_dsc_n,
  output trn_rerrfwd_n,
  output [6:0] trn_rbar_hit_n,

  // Shared Trn interface

  // Tx
  input [63:0] trn_td,
  input trn_trem_n,
  input trn_tsof_n,
  input trn_teof_n,
  input trn_tsrc_rdy_n,
  input trn_tsrc_dsc_n,
  input trn_terrfwd_n,
  input trn_tcfg_gnt_n,
  input trn_tstr_n,

  // Rx
  input trn_rdst_rdy_n,
  input trn_rnp_ok_n,

  // Config interface
  output [7:0] cfg_bus_number,
  output [4:0] cfg_device_number,
  output [2:0] cfg_function_number
);

/**
 * PCIE IP CORE instanciation
 */

wire [7:0] _cfg_bus_number;
wire [4:0] _cfg_device_number;
wire [2:0] _cfg_function_number;
wire [15:0] cfg_command;
wire [15:0] cfg_dstatus;
wire [15:0] cfg_dcommand;
wire [15:0] cfg_lstatus;
wire [15:0] cfg_lcommand;
wire [15:0] cfg_dcommand2;

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
wire [15:0] cfg_status;
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
 * Requester ID Sharing
 */
assign cfg_bus_number = _cfg_bus_number;
assign cfg_device_number = _cfg_device_number;
assign cfg_function_number = _cfg_function_number;

/**
 * Core input tie-offs
 */

`define PCI_EXP_EP_OUI 24'h000A35
`define PCI_EXP_EP_DSN_1 {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2 32'h00000001

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
// XXX assign cfg_dsn = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};

v6_pcie_v1_7 #(
  .LINK_CAP_MAX_LINK_WIDTH(PCIE_NUMBER_OF_LANES),
  .LTSSM_MAX_LINK_WIDTH(PCIE_NUMBER_OF_LANES)
) core (
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
  .cfg_bus_number(_cfg_bus_number),
  .cfg_device_number(_cfg_device_number),
  .cfg_function_number(_cfg_function_number),
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

/**
 * CSR control interface
 */
trn_ctlif #(
	.csr_addr(csr_addr)
) ctlif (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .trn_clk(trn_clk),
  .trn_lnk_up_n(trn_lnk_up_n),
  .cfg_bus_number(_cfg_bus_number),
  .cfg_device_number(_cfg_device_number),
  .cfg_function_number(_cfg_function_number),
  .cfg_command(cfg_command),
  .cfg_dstatus(cfg_dstatus),
  .cfg_dcommand(cfg_dcommand),
  .cfg_lstatus(cfg_lstatus),
  .cfg_lcommand(cfg_lcommand),
  .cfg_dcommand2(cfg_dcommand2),
  .trn_fc_cpld(trn_fc_cpld),
  .trn_fc_cplh(trn_fc_cplh),
  .trn_fc_npd(trn_fc_npd),
  .trn_fc_nph(trn_fc_nph),
  .trn_fc_pd(trn_fc_pd),
  .trn_fc_ph(trn_fc_ph),
  .trn_fc_sel(trn_fc_sel)
);

endmodule
