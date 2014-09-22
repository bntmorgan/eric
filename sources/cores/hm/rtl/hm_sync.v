module hm_sync (
  input sys_clk,
  input trn_clk,

  input trn__rx_timeout,
  output sys__rx_timeout,

  input trn__tx_timeout,
  output sys__tx_timeout,

  input trn__hm_end,
  output sys__hm_end,

  input trn__trn_lnk_up_n,
  output sys__trn_lnk_up_n,

  input [1:0] trn__state_rx,
  output reg [1:0] sys__state_rx, 

  input [1:0] trn__state_tx,
  output reg [1:0] sys__state_tx,

  input [31:0] trn__stat_trn_cpt_tx,
  output reg [31:0] sys__stat_trn_cpt_rx,

  input [31:0] trn__stat_trn_cpt_rx,
  output reg [31:0] sys__stat_trn_cpt_tx,

  input [31:0] trn__stat_trn_cpt_drop,
  output reg [31:0] sys__stat_trn_cpt_drop,

  input [1:0] trn__state,
  output reg [1:0] sys__state
);

reg [31:0] trn__state_tx_r;
always @(posedge sys_clk) begin 
	trn__state_tx_r <= trn__state_tx;
	sys__state_tx <= trn__state_tx_r;
end

reg [31:0] trn__state_rx_r;
always @(posedge sys_clk) begin 
	trn__state_rx_r <= trn__state_rx;
	sys__state_rx <= trn__state_rx_r;
end

reg [31:0] trn__stat_trn_cpt_tx_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_cpt_tx_r <= trn__stat_trn_cpt_tx;
	sys__stat_trn_cpt_tx <= trn__stat_trn_cpt_tx_r;
end

reg [31:0] trn__stat_trn_cpt_rx_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_cpt_rx_r <= trn__stat_trn_cpt_rx;
	sys__stat_trn_cpt_rx <= trn__stat_trn_cpt_rx_r;
end

reg [31:0] trn__stat_trn_cpt_drop_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_cpt_drop_r <= trn__stat_trn_cpt_drop;
	sys__stat_trn_cpt_drop <= trn__stat_trn_cpt_drop_r;
end

reg [1:0] trn__state_r;
always @(posedge sys_clk) begin 
	trn__state_r <= trn__state;
	sys__state <= trn__state_r;
end

psync ps_rx_timeout (
	.clk1(trn_clk),
	.i(trn__rx_timeout),
	.clk2(sys_clk),
	.o(sys__rx_timeout)
);

psync ps_tx_timeout (
	.clk1(trn_clk),
	.i(trn__tx_timeout),
	.clk2(sys_clk),
	.o(sys__tx_timeout)
);

psync ps_hm_end (
	.clk1(trn_clk),
	.i(trn__hm_end),
	.clk2(sys_clk),
	.o(sys__hm_end)
);

psync ps_trn_lnk_up_n (
	.clk1(trn_clk),
	.i(trn__trn_lnk_up_n),
	.clk2(sys_clk),
	.o(sys__trn_lnk_up_n)
);

endmodule
