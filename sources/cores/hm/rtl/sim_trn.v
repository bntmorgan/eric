
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
  integer i;
  integer j;
  integer bytes;
begin

  // We do it in 4 completions YO-LO
  for (i = 0; i < 4; i = i + 1) begin

    bytes = {12{13'h1000 - (11'h400 * i)}};

    // Receive src ready
    trn_rsof_n <= 1'b0;
    trn_rsrc_rdy_n <= 1'b0;
    trn_reof_n <= 1'b1;
    trn_rrem_n <= 1'b1;
    trn_rd <= {
      3'b010, // fmt
      5'b01010, // type
      14'b0, // Ignored by rx
      10'h100, // This completion is containing 100 DW On the 400 total
      20'b0, // Ignored by rx
      bytes[11:0] // Remaning bytes including byte in this TLP
    };
    waittrnclk;

    for (j = 1; j < 'h100; j = j + 2) begin // stops at 99
      trn_rsof_n <= 1'b1;
      trn_rsrc_rdy_n <= 1'b0;
      trn_reof_n <= 1'b1;
      trn_rrem_n <= 1'b1;
      trn_rd <= {
        32'h55446677,
        32'h11223344
      };
      waittrnclk;
    end

    // The last DW
    trn_rsof_n <= 1'b1;
    trn_rsrc_rdy_n <= 1'b0;
    trn_reof_n <= 1'b0;
    trn_rrem_n <= 1'b1;
    trn_rd <= {
      32'hcafebabe,
      32'h00000000
    };
    waittrnclk;

    // Ends everything properly
    trn_rsof_n <= 1'b1;
    trn_rsrc_rdy_n <= 1'b1;
    trn_reof_n <= 1'b1;
    trn_rrem_n <= 1'b1;
    trn_rd <= 64'b0;
    waittrnclk;

  end
end
endtask

task memory_read_request;
  input [31:0] address;
  input [9:0] dw;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rbar_hit_n <= 7'b1111110;
  trn_rd <= {
    3'b000, // fmt
    5'b00000, // type
    14'b0, // Ignored by mr
    dw, // Length
    16'h0000, // requester ID
    8'b0, // Ignored by mr
    4'b1111, // Last DW
    4'b1111 // First DW
  };
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_reof_n <= 1'b0;
  trn_rd <= {
    address, // Address
    32'h00000000 // First dw
  };
 	while(trn_teof_n) begin
    waittrnclk;
  end
  trn_rsrc_rdy_n <= 1'b1;
  trn_rbar_hit_n <= 7'b1111111;
  trn_reof_n <= 1'b1;
end
endtask

task memory_read_request_1b;
  input [31:0] address;
  input [6:0] bar_hit;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rbar_hit_n <= bar_hit;
  trn_rd <= {
    3'b000, // fmt
    5'b00000, // type
    14'b0, // Ignored by mr
    10'b0000000001, // Length
    16'h0000, // requester ID
    8'b0, // Ignored by mr
    4'b0000, // Last DW
    ~address[1] & ~address[0], // First DW
    ~address[1] & address[0],
    address[1] & ~address[0],
    address[1] & address[0]
  };
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_reof_n <= 1'b0;
  trn_rd <= {
    address, // Address
    32'h00000000 // First dw
  };
 	while(trn_teof_n) begin
    waittrnclk;
  end
  trn_rsrc_rdy_n <= 1'b1;
  trn_rbar_hit_n <= 7'b1111111;
  trn_reof_n <= 1'b1;
end
endtask

task memory_write_request_1b;
  input [31:0] address;
  input [31:0] data;
  input [6:0] bar_hit;
begin
  // Receive src ready
  trn_rsrc_rdy_n <= 1'b0;
  trn_rsof_n <= 1'b0;
  trn_rbar_hit_n <= bar_hit;
  trn_rd <= {
    3'b010, // fmt
    5'b00000, // type
    14'b0, // Ignored by mr
    10'b0000000001, // Length
    16'h0000, // requester ID
    8'b0, // Ignored by mr
    4'b0000, // Last DW
    ~address[1] & ~address[0], // First DW
    ~address[1] & address[0],
    address[1] & ~address[0],
    address[1] & address[0]
  };
  waittrnclk;

  trn_rsof_n <= 1'b1;
  trn_reof_n <= 1'b0;
  trn_rd <= {
    address, // Address
    data // First dw
  };
  waittrnclk;

  trn_rsrc_rdy_n <= 1'b1;
  trn_rbar_hit_n <= 7'b1111111;
  trn_reof_n <= 1'b1;
end
endtask
