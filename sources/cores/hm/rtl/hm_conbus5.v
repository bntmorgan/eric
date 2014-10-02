/*
 * Trn transmit interface arbitrer
 * Copyright (C) 2014 Benoît Morgan - bmorgan@laas.fr
 */

module hm_conbus5 (
	input trn_clk,
	input trn_rst,
	
	// Master 0 Interface
  output [5:0] m0_trn_tbuf_av,
  output m0_trn_terr_drop_n,
  output m0_trn_tdst_rdy_n,
  input m0_trn_cyc_n,
  input [63:0] m0_trn_td,
  input m0_trn_trem_n,
  input m0_trn_tsof_n,
  input m0_trn_teof_n,
  input m0_trn_tsrc_rdy_n,
  input m0_trn_tsrc_dsc_n,
  input m0_trn_terrfwd_n,
  input m0_trn_tstr_n,
	
	// Master 1 Interface
  output [5:0] m1_trn_tbuf_av,
  output m1_trn_terr_drop_n,
  output m1_trn_tdst_rdy_n,
  input m1_trn_cyc_n,
  input [63:0] m1_trn_td,
  input m1_trn_trem_n,
  input m1_trn_tsof_n,
  input m1_trn_teof_n,
  input m1_trn_tsrc_rdy_n,
  input m1_trn_tsrc_dsc_n,
  input m1_trn_terrfwd_n,
  input m1_trn_tstr_n,
	
	// Master 2 Interface
  output [5:0] m2_trn_tbuf_av,
  output m2_trn_terr_drop_n,
  output m2_trn_tdst_rdy_n,
  input m2_trn_cyc_n,
  input [63:0] m2_trn_td,
  input m2_trn_trem_n,
  input m2_trn_tsof_n,
  input m2_trn_teof_n,
  input m2_trn_tsrc_rdy_n,
  input m2_trn_tsrc_dsc_n,
  input m2_trn_terrfwd_n,
  input m2_trn_tstr_n,
	
	// Master 3 Interface
  output [5:0] m3_trn_tbuf_av,
  output m3_trn_terr_drop_n,
  output m3_trn_tdst_rdy_n,
  input m3_trn_cyc_n,
  input [63:0] m3_trn_td,
  input m3_trn_trem_n,
  input m3_trn_tsof_n,
  input m3_trn_teof_n,
  input m3_trn_tsrc_rdy_n,
  input m3_trn_tsrc_dsc_n,
  input m3_trn_terrfwd_n,
  input m3_trn_tstr_n,
	
	// Master 4 Interface
  output [5:0] m4_trn_tbuf_av,
  output m4_trn_terr_drop_n,
  output m4_trn_tdst_rdy_n,
  input m4_trn_cyc_n,
  input [63:0] m4_trn_td,
  input m4_trn_trem_n,
  input m4_trn_tsof_n,
  input m4_trn_teof_n,
  input m4_trn_tsrc_rdy_n,
  input m4_trn_tsrc_dsc_n,
  input m4_trn_terrfwd_n,
  input m4_trn_tstr_n,

  // Slave Interface
  input [5:0] s_trn_tbuf_av,
  input s_trn_terr_drop_n,
  input s_trn_tdst_rdy_n,
  output [63:0] s_trn_td,
  output s_trn_trem_n,
  output s_trn_tsof_n,
  output s_trn_teof_n,
  output s_trn_tsrc_rdy_n,
  output s_trn_tsrc_dsc_n,
  output s_trn_terrfwd_n,
  output s_trn_tstr_n
);

parameter mbusw_ls = 64 + 1 + 1 + 1 + 1 + 1 + 1 + 1;

wire [5:0] slave_sel;
wire [2:0] gnt;
reg [mbusw_ls -1:0] i_bus_m;	// internal shared bus, master data and control to slave

// master 0
assign m0_trn_tbuf_av = s_trn_tbuf_av;
assign m0_trn_terr_drop_n = s_trn_terr_drop_n;
assign m0_trn_tdst_rdy_n = s_trn_tdst_rdy_n | ~(gnt == 3'd0);

// master 1
assign m1_trn_tbuf_av = s_trn_tbuf_av;
assign m1_trn_terr_drop_n = s_trn_terr_drop_n;
assign m1_trn_tdst_rdy_n = s_trn_tdst_rdy_n | ~(gnt == 3'd1);

// master 2
assign m2_trn_tbuf_av = s_trn_tbuf_av;
assign m2_trn_terr_drop_n = s_trn_terr_drop_n;
assign m2_trn_tdst_rdy_n = s_trn_tdst_rdy_n | ~(gnt == 3'd2);

// master 3
assign m3_trn_tbuf_av = s_trn_tbuf_av;
assign m3_trn_terr_drop_n = s_trn_terr_drop_n;
assign m3_trn_tdst_rdy_n = s_trn_tdst_rdy_n | ~(gnt == 3'd3);

// master 4
assign m4_trn_tbuf_av = s_trn_tbuf_av;
assign m4_trn_terr_drop_n = s_trn_terr_drop_n;
assign m4_trn_tdst_rdy_n = s_trn_tdst_rdy_n | ~(gnt == 3'd4);

// slave 0
assign {s_trn_td, s_trn_trem_n, s_trn_tsof_n, s_trn_teof_n, s_trn_tsrc_rdy_n,
  s_trn_tsrc_dsc_n, s_trn_terrfwd_n, s_trn_tstr_n} = i_bus_m;

always @(*) begin
	case(gnt)
    3'd0:    i_bus_m = {m0_trn_td, m0_trn_trem_n, m0_trn_tsof_n, m0_trn_teof_n,
      m0_trn_tsrc_rdy_n, m0_trn_tsrc_dsc_n, m0_trn_terrfwd_n, m0_trn_tstr_n};
    3'd1:    i_bus_m = {m1_trn_td, m1_trn_trem_n, m1_trn_tsof_n, m1_trn_teof_n,
      m1_trn_tsrc_rdy_n, m1_trn_tsrc_dsc_n, m1_trn_terrfwd_n, m1_trn_tstr_n};
    3'd2:    i_bus_m = {m2_trn_td, m2_trn_trem_n, m2_trn_tsof_n, m2_trn_teof_n,
      m2_trn_tsrc_rdy_n, m2_trn_tsrc_dsc_n, m2_trn_terrfwd_n, m2_trn_tstr_n};
    3'd3:    i_bus_m = {m3_trn_td, m3_trn_trem_n, m3_trn_tsof_n, m3_trn_teof_n,
      m3_trn_tsrc_rdy_n, m3_trn_tsrc_dsc_n, m3_trn_terrfwd_n, m3_trn_tstr_n};
    default: i_bus_m = {m4_trn_td, m4_trn_trem_n, m4_trn_tsof_n, m4_trn_teof_n,
      m4_trn_tsrc_rdy_n, m4_trn_tsrc_dsc_n, m4_trn_terrfwd_n, m4_trn_tstr_n};
	endcase
end

wire [4:0] req = {~m4_trn_cyc_n, ~m3_trn_cyc_n, ~m2_trn_cyc_n, ~m1_trn_cyc_n,
  ~m0_trn_cyc_n};

hm_arb5 arb(
	.trn_clk(trn_clk),
	.trn_rst(trn_rst),
	.req(req),
	.gnt(gnt)
);

endmodule
