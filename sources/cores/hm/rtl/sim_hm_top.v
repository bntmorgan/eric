`timescale 1ns/10ps

module main();

`include "sim.v"
`include "sim_csr.v"
`include "sim_wb.v"
`include "sim_trn.v"

// Inputs
reg [63:0] hm_addr;

// Outputs
wire [63:0] hm_data;

initial begin
  hm_addr <= 64'b0;
end

/**
 * Tested component
 */
hm_top hm_top (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .wb_adr_i(wb_adr_i),
  .wb_dat_o(wb_dat_o),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_ack_o(wb_ack_o),
  .wb_we_i(wb_we_i),
  .hm_addr(hm_addr),
  .hm_data(hm_data),
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
  .trn_rnp_ok_n(trn_rnp_ok_n)
);

integer i;
initial begin
  for (i = 0; i < 2; i = i + 1)
  begin
    $dumpvars(0,hm_top.m_doa[i]);
  end
  for (i = 0; i < 8'h10; i = i + 1)
  begin
    $dumpvars(0,hm_top.gen_ram[0].m.mem[i]);
    $dumpvars(0,hm_top.gen_ram[1].m.mem[i]);
  end
  waitnclock(8);

  // Write page address to read
  csrwrite(`HM_CSR_ADDRESS_LOW, 32'hcacacaca);
  csrwrite(`HM_CSR_ADDRESS_HIGH, 32'h00000000);
  // Read it
  csrread(`HM_CSR_ADDRESS_LOW);
  csrread(`HM_CSR_ADDRESS_HIGH);

  // Link up the core
  trn_lnk_up_n <= 1'b0;

  // Launch the a Host memory read
  csrwrite(`HM_CSR_CTRL, 32'b11);

  // Set the destination ready !
  trn_tdst_rdy_n <= 1'b0;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b1;

  // SHITTY data
  waitntrnclk(8);
  random_completion; 

  // The memory read completion
  waitntrnclk(8);
  memory_read_completion;

  // Read on the wishbone bus
  waitntrnclk(8);
  wbread(32'h4);

  waitnclock(40);
  $finish();
end

endmodule
