module main();

`include "sim.v"
`include "sim_trn.v"

// Inputs
reg hm_start;
reg [63:0] hm_page_addr;

// Outputs
wire hm_end;
wire hm_timeout;

initial begin
  hm_start <= 0;
  hm_page_addr <= 0;
end

/**
 * Tested component
 */
hm_top hm_top (
  .en(1'b1),
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .hm_start(hm_start),
  .hm_page_addr(hm_page_addr),
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
  .hm_end(hm_end),
  .hm_timeout(hm_timeout),
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

task mpu_hm_start;
input [63:0] addr;
input [11:0] offset;
begin
  hm_page_addr <= addr;
  hm_start <= 1'b1;
  waitclock();
  hm_start <= 1'b0;
end
endtask

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
  // Link up the core
  trn_lnk_up_n <= 1'b0;
  mpu_hm_start(64'h0000000000001000, 12'h0);
  trn_tdst_rdy_n <= 1'b0;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b1;
  waitnclock(40);
  random_completion; 
  waitnclock(40);
  memory_read_completion;
  waitnclock(40);
  trn_tdst_rdy_n <= 1'b0;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b1;
  memory_read_completion;
  waitnclock(40);
  trn_tdst_rdy_n <= 1'b0;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b1;
  memory_read_completion;
  waitnclock(40);
  trn_tdst_rdy_n <= 1'b0;
  waitntrnclk(8);
  trn_tdst_rdy_n <= 1'b1;
  memory_read_completion;
  waitnclock(40);

  // Read the same
  mpu_hm_start(64'h0000000000001000, 12'h8);
  waitnclock(40);
  mpu_hm_start(64'h0000000000001000, 12'h10);
  waitnclock(40);
  $finish();
end

endmodule
