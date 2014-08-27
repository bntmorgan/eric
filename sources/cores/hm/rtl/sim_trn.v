
// Inputs
reg trn_clk;
reg trn_reset_n;
reg trn_lnk_up_n;
reg [5:0] trn_tbuf_av;
reg trn_tcfg_req_n;
reg trn_terr_drop_n;
reg trn_tdst_rdy_n;
reg [63:0] trn_rd;
reg trn_rrem_n;
reg trn_rsof_n;
reg trn_reof_n;
reg trn_rsrc_rdy_n;
reg trn_rsrc_dsc_n;
reg trn_rerrfwd_n;
reg [6:0] trn_rbar_hit_n;
reg [11:0] trn_fc_cpld;
reg [7:0] trn_fc_cplh;
reg [11:0] trn_fc_npd;
reg [7:0] trn_fc_nph;
reg [11:0] trn_fc_pd;
reg [7:0] trn_fc_ph;

// Outputs
wire [63:0] trn_td;
wire trn_trem_n;
wire trn_tsof_n;
wire trn_teof_n;
wire trn_tsrc_rdy_n;
wire trn_tsrc_dsc_n;
wire trn_terrfwd_n;
wire trn_tcfg_gnt_n;
wire trn_tstr_n;
wire trn_rdst_rdy_n;
wire trn_rnp_ok_n;
wire [2:0] trn_fc_sel;

always #4 trn_clk = !trn_clk;

initial begin
  trn_clk <= 0;
  trn_reset_n <= 1;
  trn_lnk_up_n <= 0;
  trn_tbuf_av <= 1;
  trn_tcfg_req_n <= 1;
  trn_terr_drop_n <= 1;
  trn_tdst_rdy_n <= 1;
  trn_rd <= 64'b0;
  trn_rrem_n <= 1;
  trn_rsof_n <= 1;
  trn_reof_n <= 1;
  trn_rsrc_rdy_n <= 1;
  trn_rsrc_dsc_n <= 1;
  trn_rerrfwd_n <= 1;
  trn_rbar_hit_n <= 7'b1111111;
  trn_fc_cpld <= 0;
  trn_fc_cplh <= 0;
  trn_fc_npd <= 0;
  trn_fc_nph <= 0;
  trn_fc_pd <= 0;
  trn_fc_ph <= 0;
end

task waittrnclk;
begin
  @(posedge trn_clk);
  #2;
end
endtask

task waitntrnclk;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waittrnclk;
	end
endtask

task random_completion;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rd <= 64'h00cacacacacacaca;
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_rd <= 64'hcbcbcbcbcbcbcbcb;
  waittrnclk;

  trn_rd <= 64'hcccccccccccccccc;
  waittrnclk;

  trn_rd <= 64'hcdcdcdcdcdcdcdcd;
  waittrnclk;

  trn_rd <= 64'hcececececececece;
  waittrnclk;

  trn_rd <= 64'hcfcfcfcfcfcfcfcf;
  waittrnclk;

  trn_rsrc_rdy_n <= 1'b0;
  trn_reof_n <= 1'b0;
  trn_rd <= 64'hacacacacacacacac;
  waittrnclk;

  trn_rsrc_rdy_n <= 1'b1;
  trn_reof_n <= 1'b1;
end
endtask

task memory_read_completion;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rd <= {
    3'b010, // fmt
    5'b01010, // type
    24'b0, // Ignored by rx
    32'b0 // Ignored by rx
  };
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_rd <= {
    32'b0, // Ignored by rx
    32'h11111111 // First dw
  };
  waittrnclk;

  trn_rd <= 64'hcccccccccccccccc;
  waittrnclk;

  trn_rd <= 64'hcdcdcdcdcdcdcdcd;
  waittrnclk;

  trn_rd <= 64'hcececececececece;
  waittrnclk;

  trn_rd <= 64'hcfcfcfcfcfcfcfcf;
  waittrnclk;

  trn_rsrc_rdy_n <= 1'b0;
  trn_reof_n <= 1'b0;
  trn_rd <= 64'hacacacacacacacac;
  waittrnclk;

  trn_rsrc_rdy_n <= 1'b1;
  trn_reof_n <= 1'b1;
end
endtask

task memory_read_request;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rbar_hit_n <= 7'b1111110;
  trn_rd <= {
    3'b000, // fmt
    5'b00000, // type
    14'b0, // Ignored by mr
    10'b0000000001, // Length
    16'h0000, // requester ID
    8'b0, // Ignored by mr
    8'b0010_0000 // Ignored by mr
  };
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_reof_n <= 1'b0;
  trn_rd <= {
    32'hf330007c, // Address
    32'h00000000 // First dw
  };
  waittrnclk;
  trn_rsrc_rdy_n <= 1'b1;
  trn_rbar_hit_n <= 7'b1111111;
  trn_reof_n <= 1'b1;
end
endtask
