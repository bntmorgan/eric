module trn_sync (
  input sys_clk,
  input trn_clk,

  input [2:0] sys__trn_fc_sel,
  output reg [2:0] trn__trn_fc_sel,

  input [31:0] trn__stat_trn,
  output reg [31:0] sys__stat_trn
);

reg [2:0] sys__trn_fc_sel_r;
always @(posedge sys_clk) begin 
	sys__trn_fc_sel_r <= sys__trn_fc_sel;
	trn__trn_fc_sel <= sys__trn_fc_sel_r;
end

reg [31:0] trn__stat_trn_r;
always @(posedge sys_clk) begin 
	trn__stat_trn_r <= trn__stat_trn;
	sys__stat_trn <= trn__stat_trn_r;
end

endmodule
