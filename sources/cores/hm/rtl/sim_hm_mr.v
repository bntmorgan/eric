module main();

`include "sim.v"
`include "sim_trn.v"

// Inputs
reg [7:0] cfg_bus_number;
reg [4:0] cfg_device_number;
reg [2:0] cfg_function_number;

// Ouputs
wire [15:0] stat_trn_cpt_tx;

initial begin
  cfg_bus_number <= 8'h18;
  cfg_device_number <= 0;
  cfg_function_number <= 0;
end

/**
 * Tested component
 */
hm_mr mr (
  .sys_rst(sys_rst),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),

  .trn_td(trn_td),
  .trn_tsof_n(trn_tsof_n),
  .trn_trem_n(trn_trem_n),
  .trn_teof_n(trn_teof_n),
  .trn_tsrc_rdy_n(trn_tsrc_rdy_n),
  .trn_tdst_rdy_n(trn_tdst_rdy_n),
  .trn_tbuf_av(trn_tbuf_av),
  .trn_tcfg_req_n(trn_tcfg_req_n),
  .trn_terr_drop_n(trn_terr_drop_n),
  .trn_tsrc_dsc_n(trn_tsrc_dsc_n),
  .trn_terrfwd_n(trn_terrfwd_n),
  .trn_tcfg_gnt_n(trn_tcfg_gnt_n),
  .trn_tstr_n(trn_tstr_n),

  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rdst_rdy_n(trn_rdst_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rnp_ok_n(trn_rnp_ok_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),

  .cfg_bus_number(cfg_bus_number),
  .cfg_device_number(cfg_device_number),
  .cfg_function_number(cfg_function_number),

  .stat_trn_cpt_tx(stat_trn_cpt_tx)
);

initial begin
  waitntrnclk(8);
  // Link up the core
  trn_lnk_up_n <= 1'b0;

  memory_read_request;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b0;

  waitntrnclk(8);

  memory_read_request;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b0;
  $finish();
end

endmodule
