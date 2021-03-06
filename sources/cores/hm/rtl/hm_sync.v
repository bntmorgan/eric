module hm_sync (
  input sys_clk,
  input trn_clk,

  input trn__rx_timeout,
  output sys__rx_timeout,

  input trn__tx_timeout,
  output sys__tx_timeout,

  input trn__wr_timeout,
  output sys__wr_timeout,

  input trn__hm_end,
  output sys__hm_end,

  input trn__write_bar,
  output sys__write_bar,

  input trn__read_exp,
  output sys__read_exp,

  input trn__trn_lnk_up_n,
  output sys__trn_lnk_up_n,

  input [2:0] trn__state_rx,
  output reg [2:0] sys__state_rx,

  input [31:0] trn__rx_tlp_dw,
  output reg [31:0] sys__rx_tlp_dw,

  input [1:0] trn__state_tx,
  output reg [1:0] sys__state_tx,

  input [31:0] trn__stat_trn_cpt_tx,
  output reg [31:0] sys__stat_trn_cpt_rx,

  input [31:0] trn__stat_trn_cpt_rx,
  output reg [31:0] sys__stat_trn_cpt_tx,

  input [31:0] trn__stat_trn_cpt_tx_drop,
  output reg [31:0] sys__stat_trn_cpt_tx_drop,

  input [31:0] trn__stat_trn_cpt_tx_start,
  output reg [31:0] sys__stat_trn_cpt_tx_start,

  input [31:0] trn__tx_error,
  output reg [31:0] sys__tx_error,

  input [4:0] trn__write_bar_number,
  output reg [4:0] sys__write_bar_number,

  output reg [31:0] trn__bar_bitmap,
  input [31:0] sys__bar_bitmap,

  input [1:0] trn__state,
  output reg [1:0] sys__state,

  input sys__hm_start_read,
  output trn__hm_start_read
);

reg [1:0] trn__state_tx_r;
always @(posedge sys_clk) begin
	trn__state_tx_r <= trn__state_tx;
	sys__state_tx <= trn__state_tx_r;
end

reg [2:0] trn__state_rx_r;
always @(posedge sys_clk) begin
	trn__state_rx_r <= trn__state_rx;
	sys__state_rx <= trn__state_rx_r;
end

reg [31:0] trn__rx_tlp_dw_r;
always @(posedge sys_clk) begin
	trn__rx_tlp_dw_r <= trn__rx_tlp_dw;
	sys__rx_tlp_dw <= trn__rx_tlp_dw_r;
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

reg [31:0] trn__stat_trn_cpt_tx_drop_r;
always @(posedge sys_clk) begin
	trn__stat_trn_cpt_tx_drop_r <= trn__stat_trn_cpt_tx_drop;
	sys__stat_trn_cpt_tx_drop <= trn__stat_trn_cpt_tx_drop_r;
end

reg [31:0] trn__stat_trn_cpt_tx_start_r;
always @(posedge sys_clk) begin
	trn__stat_trn_cpt_tx_start_r <= trn__stat_trn_cpt_tx_start;
	sys__stat_trn_cpt_tx_start <= trn__stat_trn_cpt_tx_start_r;
end

reg [31:0] trn__tx_error_r;
always @(posedge sys_clk) begin
	trn__tx_error_r <= trn__tx_error;
	sys__tx_error <= trn__tx_error_r;
end

reg [1:0] trn__state_r;
always @(posedge sys_clk) begin
	trn__state_r <= trn__state;
	sys__state <= trn__state_r;
end

reg [4:0] trn__write_bar_number_r;
always @(posedge sys_clk) begin
	trn__write_bar_number_r <= trn__write_bar_number;
	sys__write_bar_number <= trn__write_bar_number_r;
end

reg [31:0] sys__bar_bitmap_r;
always @(posedge trn_clk) begin
	sys__bar_bitmap_r <= sys__bar_bitmap;
	trn__bar_bitmap <= sys__bar_bitmap_r;
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

psync ps_wr_timeout (
	.clk1(trn_clk),
	.i(trn__wr_timeout),
	.clk2(sys_clk),
	.o(sys__wr_timeout)
);

psync ps_hm_end (
	.clk1(trn_clk),
	.i(trn__hm_end),
	.clk2(sys_clk),
	.o(sys__hm_end)
);

psync ps_write_bar (
	.clk1(trn_clk),
	.i(trn__write_bar),
	.clk2(sys_clk),
	.o(sys__write_bar)
);

psync ps_read_exp (
	.clk1(trn_clk),
	.i(trn__read_exp),
	.clk2(sys_clk),
	.o(sys__read_exp)
);

psync ps_trn_lnk_up_n (
	.clk1(trn_clk),
	.i(trn__trn_lnk_up_n),
	.clk2(sys_clk),
	.o(sys__trn_lnk_up_n)
);

psync ps_hm_start_read (
	.clk1(sys_clk),
	.i(sys__hm_start_read),
	.clk2(trn_clk),
	.o(trn__hm_start_read)
);

endmodule
