module hm_sync (
  input sys_clk,
  input trn_clk,

  input trn__page_read_end,
  output sys__page_read_end,

  input trn__rx_timeout,
  output sys__rx_timeout,

  input trn__tx_timeout,
  output sys__tx_timeout,

  input trn__trn_lnk_up_n,
  output sys__trn_lnk_up_n,

  input [15:0] trn__stat_trn_cpt_tx,
  output reg [15:0] sys__stat_trn_cpt_rx,

  input [15:0] trn__stat_trn_cpt_rx,
  output reg [15:0] sys__stat_trn_cpt_tx,

  input [31:0] trn__stat_trn,
  output reg [31:0] sys__stat_trn
);

reg [31:0] trn__stat_trn_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_r <= trn__stat_trn;
	sys__stat_trn <= trn__stat_trn_r;
end

reg [15:0] trn__stat_trn_cpt_tx_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_cpt_tx_r <= trn__stat_trn_cpt_tx;
	sys__stat_trn_cpt_tx <= trn__stat_trn_cpt_tx_r;
end

reg [15:0] trn__stat_trn_cpt_rx_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_cpt_rx_r <= trn__stat_trn_cpt_rx;
	sys__stat_trn_cpt_rx <= trn__stat_trn_cpt_rx_r;
end

hm_psync ps_page_read_end (
	.clk1(trn_clk),
	.i(trn__page_read_end),
	.clk2(sys_clk),
	.o(sys__page_read_end)
);

hm_psync ps_rx_timeout (
	.clk1(trn_clk),
	.i(trn__rx_timeout),
	.clk2(sys_clk),
	.o(sys__rx_timeout)
);

hm_psync ps_tx_timeout (
	.clk1(trn_clk),
	.i(trn__tx_timeout),
	.clk2(sys_clk),
	.o(sys__tx_timeout)
);

hm_psync ps_trn_lnk_up (
	.clk1(trn_clk),
	.i(trn__trn_lnk_up_n),
	.clk2(sys_clk),
	.o(sys__trn_lnk_up_n)
);

endmodule
