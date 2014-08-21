`include "hm.vh"

module hm_top (
  input sys_clk,
  input sys_rst,
  input en,

  input hm_start,
  output reg hm_end,
  input [63:0] hm_page_addr,
  output hm_timeout,
  output reg hm_error,

  input [11:0] hm_page_offset,
  output [63:0] hm_data,

  // Trn interface
  
  // Common
  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,

  // Tx
  input [5:0] trn_tbuf_av,
  input trn_tcfg_req_n,
  input trn_terr_drop_n,
  input trn_tdst_rdy_n,
  output [63:0] trn_td,
  output trn_trem_n,
  output trn_tsof_n,
  output trn_teof_n,
  output trn_tsrc_rdy_n,
  output trn_tsrc_dsc_n,
  output trn_terrfwd_n,
  output trn_tcfg_gnt_n,
  output trn_tstr_n,

  // Rx
  input [63:0] trn_rd,
  input trn_rrem_n,
  input trn_rsof_n,
  input trn_reof_n,
  input trn_rsrc_rdy_n,
  input trn_rsrc_dsc_n,
  input trn_rerrfwd_n,
  input [6:0] trn_rbar_hit_n,
  output trn_rdst_rdy_n,
  output trn_rnp_ok_n,

  // Wishbone bus page read acces
	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i,

  // cfg ip core interface
  input [7:0] cfg_bus_number,
  input [4:0] cfg_device_number,
  input [2:0] cfg_function_number,
  input [15:0] cfg_command,
  input [15:0] cfg_dstatus,
  input [15:0] cfg_dcommand,
  input [15:0] cfg_lstatus,
  input [15:0] cfg_lcommand,
  input [15:0] cfg_dcommand2,

  // User statistics counters ans status
  output [15:0] stat_trn_cpt_tx,
  output [15:0] stat_trn_cpt_rx,
  output [31:0] stat_trn
);

wire trn__trn_lnk_up_n;
wire sys__trn_lnk_up_n;
wire sys__rx_timeout;
wire sys__tx_timeout;
wire trn__rx_timeout;
wire trn__tx_timeout;
assign hm_timeout = sys__rx_timeout | sys__tx_timeout;
assign trn__trn_lnk_up_n = trn_lnk_up_n;

reg [1:0] state_a; 
reg [1:0] state_b; 
reg [3:0] n; 
reg [11:0] page_offset; 
reg tx_start; 
reg rx_start; 
reg page_read_start;
reg trn__page_read_end;
wire sys__page_read_end;
reg [63:0] page_addr;

wire [31:0] m_doa [1:0];
wire [9:0] m_addra [1:0];
wire [31:0] m_dib [1:0];
wire [9:0] m_addrb [1:0];
wire [3:0] m_web [1:0];
assign m_web[0] = (mem_l_we == 1'b1) ? 4'b1111 : 4'b0000;
assign m_web[1] = (mem_h_we == 1'b1) ? 4'b1111 : 4'b0000;
assign m_addrb[0] = mem_l_addr;
assign m_addrb[1] = mem_h_addr;

assign hm_data [63:0] = {m_doa[0][31:0], m_doa[1][31:0]};

wire [9:0] mem_l_addr;
wire [9:0] mem_h_addr;
wire mem_l_we;
wire mem_h_we;
wire [1:0] state_rx; 
wire [1:0] state_tx; 
wire [7:0] stat_trn_cpt_drop;

wire wb_en = wb_cyc_i & wb_stb_i;

wire [31:0] trn__stat_trn;
wire [31:0] sys__stat_trn;
assign stat_trn = sys__stat_trn;

wire [15:0] trn__stat_trn_cpt_tx;
wire [15:0] trn__stat_trn_cpt_rx;
wire [15:0] sys__stat_trn_cpt_tx;
wire [15:0] sys__stat_trn_cpt_rx;
assign stat_trn_cpt_tx = sys__stat_trn_cpt_tx;
assign stat_trn_cpt_rx = sys__stat_trn_cpt_rx;

reg is_loaded;

task init_a;
begin
  state_a <= `HM_STATE_IDLE;
  page_read_start <= 1'b0;
  page_addr <= 63'b0;
  hm_end <= 1'b0;
  hm_error <= 1'b0;
  is_loaded <= 1'b0;
end
endtask

task init_b;
begin
  state_b <= `HM_STATE_IDLE;
  page_offset <= 12'b0;
  trn__page_read_end = 1'b0;
  n <= 4'b0;
  tx_start <= 1'b0;
  rx_start <= 1'b0;
end
endtask

initial begin
  init_a();
  init_b();
end

// Stats
assign trn__stat_trn = {
    7'b0000000,
    // Dropped sent packets
    stat_trn_cpt_drop,
    // sate TX
    state_tx,
    // state RX
    state_rx,
    // A state,
    state_a,
    // B state,
    state_b,
    // TX
    trn_tbuf_av, // 6-bits
    trn_tdst_rdy_n,
    // RX
    trn_rsrc_rdy_n,
    // Common
    trn__trn_lnk_up_n
  };

// State machine A sys_clk clocked @80 MHz
always @(posedge sys_clk) begin
  if (sys_rst) begin
    init_a();
  end else if (en == 1'b1) begin
    if (state_a == `HM_STATE_IDLE) begin
      hm_end <= 1'b0;
      if (hm_start == 1'b1) begin
        if (sys__trn_lnk_up_n == 1'b1) begin
          hm_error <= 1'b1;
        end else if (hm_page_addr == page_addr && is_loaded == 1'b1) begin
          hm_end <= 1'b1;
          state_a <= `HM_STATE_IDLE;
        end else begin
          page_addr <= hm_page_addr;
          state_a <= `HM_STATE_READ_PAGE;
          page_read_start <= 1'b1;
        end
      end 
    end else if (state_a == `HM_STATE_READ_PAGE) begin
      page_read_start <= 1'b0;
      if (hm_timeout == 1'b1) begin
        state_a <= `HM_STATE_IDLE;
      end else if (sys__page_read_end == 1'b1) begin
        hm_end <= 1'b1;
        state_a <= `HM_STATE_IDLE;
        is_loaded <= 1'b1;
      end
    end
  end else begin
    hm_error <= 1'b0;
  end
end

// State machine B, trn_clk clocked @100 MHz
always @(posedge trn_clk) begin
  if (sys_rst | ~trn_reset_n) begin
    init_b();
  end else if (en == 1'b1) begin
    tx_start <= 1'b0;
    rx_start <= 1'b0;
    if (state_b == `HM_STATE_IDLE) begin
      trn__page_read_end = 1'b0;
      if (page_read_start == 1'b1) begin
        n <= 4'b0; 
        page_offset <= 12'b0;
        state_b <= `HM_STATE_SEND;
        tx_start <= 1'b1;
      end
    end else if (state_b == `HM_STATE_SEND) begin
      if (trn__tx_timeout == 1'b1) begin
        state_b <= `HM_STATE_IDLE;
      end else if (tx_end == 1'b1) begin
        state_b <= `HM_STATE_RECV;
        rx_start <= 1'b1;
      end
      // XXX test 
      state_b <= `HM_STATE_IDLE;
      trn__page_read_end = 1'b1;
    end else if (state_b == `HM_STATE_RECV) begin
      if (trn__rx_timeout == 1'b1) begin
        state_b <= `HM_STATE_IDLE;
      end else if (rx_end == 1'b1) begin
        n <= n + 1'b1;
        if (n == 4'h3) begin
          state_b <= `HM_STATE_IDLE;
          trn__page_read_end = 1'b1;
        end else begin
          page_offset <= page_offset + 12'h400;
          state_b <= `HM_STATE_SEND;
          tx_start <= 1'b1;
        end
      end
    end else begin
      // Error go back to IDLE state_b
      init_b();
    end
  end
end

assign m_addra[0] = (wb_en == 1'b1) ? wb_adr_i[11:3] : hm_page_offset[11:3];
assign m_addra[1] = (wb_en == 1'b1) ? wb_adr_i[11:3] : hm_page_offset[11:3];

// TX Engine
hm_tx tx (
  .sys_rst(sys_rst),
  .tx_start(tx_start),
  .tx_end(tx_end),
  .hm_addr({page_addr[63:12],page_offset[11:0]}),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn__trn_lnk_up_n),
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
  .stat_trn_cpt_tx(trn__stat_trn_cpt_tx),
  .stat_state(state_tx),
  .stat_trn_cpt_drop(stat_trn_cpt_drop),
  .timeout(trn__tx_timeout)
);

hm_rx rx (
  .sys_rst(sys_rst),
  .rx_start(rx_start),
  .rx_end(rx_end),
  .mem_l_addr(mem_l_addr),
  .mem_l_data(m_dib[0]),
  .mem_l_we(mem_l_we),
  .mem_h_addr(mem_h_addr),
  .mem_h_data(m_dib[1]),
  .mem_h_we(mem_h_we),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn__trn_lnk_up_n),
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
  .stat_trn_cpt_rx(trn__stat_trn_cpt_rx),
  .stat_state(state_rx),
  .timeout(trn__rx_timeout)
);

`ifndef SIMULATION
genvar ram_index;
generate for (ram_index=0; ram_index < 2; ram_index=ram_index+1) 
begin: gen_ram
	RAMB36 #(
		.WRITE_WIDTH_A(36),
		.READ_WIDTH_A(36),
		.WRITE_WIDTH_B(36),
		.READ_WIDTH_B(36),
		.DOA_REG(0),
		.DOB_REG(0),
		.SIM_MODE("SAFE"),
		.INIT_A(9'h000),
		.INIT_B(9'h000),
		.WRITE_MODE_A("WRITE_FIRST"),
		.WRITE_MODE_B("WRITE_FIRST")
	) ram (
		.DIA(32'b0),
		.DIPA(4'h0),
		.DOA(m_doa[ram_index]),
		.ADDRA({1'b0, m_addra[ram_index], 5'b0}), 
		.WEA(4'b0),
		.ENA(1'b1),
		.CLKA(sys_clk),
		
		.DIB(m_dib[ram_index]),
		.DIPB(4'h0),
		.DOB(),
		.ADDRB({1'b0, m_addrb[ram_index][9:0], 5'b0}), 
		.WEB(m_web[ram_index]),
		.ENB(1'b1),
		.CLKB(trn_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
end
endgenerate
`else
genvar ram_index;
generate for (ram_index=0; ram_index < 2; ram_index=ram_index+1) 
begin: gen_ram
  hm_memory_32 m (
		.DIA(32'b0),
		.DOA(m_doa[ram_index]),
		.ADDRA({1'b0, m_addra[ram_index], 5'b0}), 
		.WEA(4'b0),
		.CLKA(sys_clk),
		
		.DIB(m_dib[ram_index]),
		.DOB(),
		.ADDRB({1'b0, m_addrb[ram_index][9:0], 5'b0}), 
		.WEB(m_web[ram_index]),
		.CLKB(trn_clk)
  );
end
endgenerate
`endif//SIMULATION

always @(*) begin
  if (sys_rst == 1'b1) begin
	  wb_dat_o = 32'b0;
  end else begin
    // TODO No endianess convertion in debug mode, TLP are big endian in trn
    // interface
    if (wb_adr_i[2] == 1'b0) begin
      wb_dat_o = {
        m_doa[0][31:24],
        m_doa[0][23:16],
        m_doa[0][15:8],
        m_doa[0][7:0]
      };
    end else begin
      wb_dat_o = {
        m_doa[1][31:24],
        m_doa[1][23:16],
        m_doa[1][15:8],
        m_doa[1][7:0]
      };
    end
  end
end

initial wb_ack_o <= 1'b0;
always @(posedge sys_clk) begin
	if(sys_rst)
		wb_ack_o <= 1'b0;
	else begin
		wb_ack_o <= 1'b0;
		if(wb_en & ~wb_ack_o)
			wb_ack_o <= 1'b1;
	end
end

hm_sync sync (
  .trn_clk(trn_clk),
  .sys_clk(sys_clk),

  .trn__rx_timeout(trn__rx_timeout),
  .sys__rx_timeout(sys__rx_timeout),

  .trn__tx_timeout(trn__tx_timeout),
  .sys__tx_timeout(sys__tx_timeout),

  .trn__page_read_end(trn__page_read_end),
  .sys__page_read_end(sys__page_read_end),

  .trn__stat_trn_cpt_tx(trn__stat_trn_cpt_tx),
  .sys__stat_trn_cpt_tx(sys__stat_trn_cpt_tx),

  .trn__stat_trn_cpt_rx(trn__stat_trn_cpt_rx),
  .sys__stat_trn_cpt_rx(sys__stat_trn_cpt_rx),
  
  .trn__trn_lnk_up_n(trn__trn_lnk_up_n),
  .sys__trn_lnk_up_n(sys__trn_lnk_up_n),

  .trn__stat_trn(trn__stat_trn),
  .sys__stat_trn(sys__stat_trn)
);

endmodule
