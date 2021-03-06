`include "hm.vh"

module hm_top #(
	parameter csr_addr = 4'h0
) (
  input sys_clk,
  input sys_rst,

  // CSR bus
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

  // Wishbone bus
	input [31:0] wb_adr_i,
	output reg [31:0] wb_dat_o,
	input [31:0] wb_dat_i,
	input [3:0] wb_sel_i,
	input wb_stb_i,
	input wb_cyc_i,
	output reg wb_ack_o,
	input wb_we_i,

  // Host memory bus
  input [63:0] hm_addr,
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

  // Requester ID sharing
  input [7:0] cfg_bus_number,
  input [4:0] cfg_device_number,
  input [2:0] cfg_function_number,

  // IRQ
  output irq
);

// Sys

wire csr_selected = csr_a[13:10] == csr_addr;
reg hm_start_read;
reg hm_start_write;
reg hm_lock_write;
reg event_end;
reg event_error;
reg event_tx_timeout;
reg event_rx_timeout;
reg event_wr_timeout;
reg event_read_exp;
reg event_write_bar;
reg [63:0] address;
reg [31:0] data;
reg debug;
reg [15:0] oid;
reg override_id;
reg nosnoop;

wire [15:0] id = (override_id) ? oid : {cfg_bus_number, cfg_device_number,
  cfg_function_number};

// IRQs
reg irq_en;
// assign irq = 0;
assign irq = irq_en & (event_end | event_wr_timeout | event_tx_timeout
| event_rx_timeout | event_read_exp | event_write_bar);

wire wb_en = wb_cyc_i & wb_stb_i;

// Bar bitmaps
reg [31:0] bar_bitmap;

// Trn

reg [1:0] state;
reg tx_start;
reg wr_start;
reg hm_end;
reg [31:0] timeout_cpt;

wire tx_end;
wire rx_memory_read;
wire wr_end;

task init_csr;
begin
  hm_start_read <= 1'b0;
  hm_start_write <= 1'b0;
  hm_lock_write <= 1'b0;
  event_end <= 1'b0;
  event_rx_timeout <= 1'b0;
  event_tx_timeout <= 1'b0;
  event_wr_timeout <= 1'b0;
  event_end <= 1'b0;
  event_read_exp <= 1'b0;
  event_write_bar <= 1'b0;
  csr_do <= 32'd0;
  irq_en <= 1'b0;
  address <= 64'b0;
  data <= 32'b0;
  bar_bitmap <= 32'b0;
  debug <= 1'b0;
  oid <= 16'b0;
  override_id <= 1'b0;
  nosnoop <= 1'b1; // No snoop by default
end
endtask

wire [3:0] wb_sel_i_le = {
  wb_sel_i[0],
  wb_sel_i[1],
  wb_sel_i[2],
  wb_sel_i[3]
};

// Memory READ

wire [9:0] read_mem_l_addr;
wire [9:0] read_mem_h_addr;
wire read_mem_l_we;
wire read_mem_h_we;
wire [31:0] read_m_doa [1:0];
wire [31:0] read_m_dia [1:0];
wire [9:0] read_m_addra [1:0];
wire [3:0] read_m_wea [1:0];
wire [31:0] read_m_dib [1:0];
wire [9:0] read_m_addrb [1:0];
wire [3:0] read_m_web [1:0];

wire [31:0] read_m_hm_dob[1:0];

// Memory Expansion ROM

wire [9:0] exp_mem_l_addr;
wire [9:0] exp_mem_h_addr;
wire [31:0] exp_m_doa [1:0];
wire [31:0] exp_m_dia [1:0];
wire [9:0] exp_m_addra [1:0];
wire [3:0] exp_m_wea [1:0];
wire [31:0] exp_m_dob [1:0];
wire [9:0] exp_m_addrb [1:0];
assign exp_m_addrb[0] = exp_mem_l_addr;
assign exp_m_addrb[1] = exp_mem_h_addr;

// Memory BAR

wire [9:0] bar_mem_l_addr;
wire [9:0] bar_mem_h_addr;
wire [3:0] bar_mem_l_we;
wire [3:0] bar_mem_h_we;
wire [31:0] bar_m_doa [1:0];
wire [31:0] bar_m_dia [1:0];
wire [9:0] bar_m_addra [1:0];
wire [3:0] bar_m_wea [1:0];
wire [31:0] bar_m_dob [1:0];
wire [31:0] bar_m_dib [1:0];
wire [9:0] bar_m_addrb [1:0];
wire [3:0] bar_m_web [1:0];
assign bar_m_addrb[0] = bar_mem_l_addr;
assign bar_m_addrb[1] = bar_mem_h_addr;
assign bar_m_web[0] = bar_mem_l_we;
assign bar_m_web[1] = bar_mem_h_we;

// Synced wires

wire [31:0] trn__stat_trn_cpt_tx;
wire [31:0] sys__stat_trn_cpt_tx;
wire [31:0] trn__stat_trn_cpt_rx;
wire [31:0] sys__stat_trn_cpt_rx;
wire [2:0] trn__state_rx;
wire [2:0] sys__state_rx;
wire [31:0] trn__rx_tlp_dw;
wire [31:0] sys__rx_tlp_dw;
wire [1:0] trn__state_tx;
wire [1:0] sys__state_tx;
wire [31:0] trn__stat_trn_cpt_tx_drop;
wire [31:0] sys__stat_trn_cpt_tx_drop;
wire [31:0] trn__stat_trn_cpt_tx_start;
wire [31:0] sys__stat_trn_cpt_tx_start;
wire [31:0] trn__tx_error;
wire [31:0] sys__tx_error;
wire trn__hm_end = hm_end;
wire sys__hm_end;
wire read_exp;
wire trn__read_exp = read_exp;
wire sys__read_exp;
wire write_bar;
wire trn__write_bar = write_bar;
wire sys__write_bar;
wire [31:0] trn__bar_bitmap;
wire [31:0] sys__bar_bitmap = bar_bitmap;
wire [4:0] trn__write_bar_number;
wire [4:0] sys__write_bar_number;
reg tx_timeout;
wire trn__tx_timeout = tx_timeout;
wire sys__tx_timeout;
reg rx_timeout;
wire trn__rx_timeout = rx_timeout;
wire sys__rx_timeout;
reg wr_timeout;
wire trn__wr_timeout = wr_timeout;
wire sys__wr_timeout;
wire trn__trn_lnk_up_n = trn_lnk_up_n;
wire sys__trn_lnk_up_n;
wire [1:0] trn__state = state;
wire [1:0] sys__state;
wire sys__hm_start_read = hm_start_read;
wire trn__hm_start_read;

// TX TRN bus sharing

// Ties off
assign trn_tcfg_gnt_n = 1'b0;
assign trn_rnp_ok_n = 1'b0;
assign trn_rdst_rdy_n = 1'b0; // !!!! We are everytime ready !!!!

// Masters

wire [5:0] m0_trn_tbuf_av;
wire m0_trn_tcfg_req_n;
wire m0_trn_terr_drop_n;
wire m0_trn_tdst_rdy_n;
wire m0_trn_cyc_n;
wire [63:0] m0_trn_td;
wire m0_trn_trem_n;
wire m0_trn_tsof_n;
wire m0_trn_teof_n;
wire m0_trn_tsrc_rdy_n;
wire m0_trn_tsrc_dsc_n;
wire m0_trn_terrfwd_n;
wire m0_trn_tcfg_gnt_n;
wire m0_trn_tstr_n;

wire [5:0] m1_trn_tbuf_av;
wire m1_trn_tcfg_req_n;
wire m1_trn_terr_drop_n;
wire m1_trn_tdst_rdy_n;
wire m1_trn_cyc_n;
wire [63:0] m1_trn_td;
wire m1_trn_trem_n;
wire m1_trn_tsof_n;
wire m1_trn_teof_n;
wire m1_trn_tsrc_rdy_n;
wire m1_trn_tsrc_dsc_n;
wire m1_trn_terrfwd_n;
wire m1_trn_tcfg_gnt_n;
wire m1_trn_tstr_n;

wire [5:0] m2_trn_tbuf_av;
wire m2_trn_tcfg_req_n;
wire m2_trn_terr_drop_n;
wire m2_trn_tdst_rdy_n;
wire m2_trn_cyc_n;
wire [63:0] m2_trn_td;
wire m2_trn_trem_n;
wire m2_trn_tsof_n;
wire m2_trn_teof_n;
wire m2_trn_tsrc_rdy_n;
wire m2_trn_tsrc_dsc_n;
wire m2_trn_terrfwd_n;
wire m2_trn_tcfg_gnt_n;
wire m2_trn_tstr_n;

wire [5:0] m3_trn_tbuf_av;
wire m3_trn_tcfg_req_n;
wire m3_trn_terr_drop_n;
wire m3_trn_tdst_rdy_n;
wire m3_trn_cyc_n;
wire [63:0] m3_trn_td;
wire m3_trn_trem_n;
wire m3_trn_tsof_n;
wire m3_trn_teof_n;
wire m3_trn_tsrc_rdy_n;
wire m3_trn_tsrc_dsc_n;
wire m3_trn_terrfwd_n;
wire m3_trn_tcfg_gnt_n;
wire m3_trn_tstr_n;

task init_trn;
begin
  state <= `HM_STATE_IDLE;
  tx_start <= 1'b0;
  wr_start <= 1'b0;
  hm_end <= 1'b0;
  timeout_cpt <= 32'b0;
  rx_timeout <= 1'b0;
  tx_timeout <= 1'b0;
  wr_timeout <= 1'b0;
end
endtask

initial begin
  init_csr;
  init_trn;
end

// CSR state machine

always @(posedge sys_clk) begin
  if (sys_rst) begin
    init_csr;
  end else begin
    // CSR
		csr_do <= 32'd0;
    hm_start_read <= 1'b0;
    hm_start_write <= 1'b0;
		if (csr_selected) begin
			case (csr_a[9:0])
        `HM_CSR_STAT: csr_do <= {26'b0, event_wr_timeout, event_write_bar,
          event_read_exp, event_rx_timeout, event_tx_timeout, event_end};
        `HM_CSR_CTRL: csr_do <= {25'b0, hm_lock_write, override_id, nosnoop,
          debug, hm_start_write, hm_start_read, irq_en};
        `HM_CSR_ADDRESS_LOW: csr_do <= address[31:0];
        `HM_CSR_ADDRESS_HIGH: csr_do <= address[63:32];
        `HM_CSR_CPT_RX: csr_do <= sys__stat_trn_cpt_rx;
        `HM_CSR_CPT_TX: csr_do <= sys__stat_trn_cpt_tx;
        `HM_CSR_STATE_RX: csr_do <= {29'b0, sys__state_rx};
        `HM_CSR_STATE_TX: csr_do <= {31'b0, sys__state_tx};
        `HM_CSR_STATE: csr_do <= {30'b0, sys__state};
        `HM_CSR_BAR_BITMAP: csr_do <= bar_bitmap;
        `HM_CSR_WRITE_BAR_NUMBER: csr_do <= {27'b0, sys__write_bar_number};
        `HM_CSR_DATA: csr_do <= data[31:0];
        `HM_CSR_ID: csr_do <= {16'b0, oid};
        `HM_CSR_RX_TLP_DW: csr_do <= {sys__rx_tlp_dw};
        `HM_CSR_CPT_TX_DROP: csr_do <= {sys__stat_trn_cpt_tx_drop};
        `HM_CSR_TX_ERROR: csr_do <= {sys__tx_error};
        `HM_CSR_CPT_TX_START: csr_do <= {sys__stat_trn_cpt_tx_start};
      endcase
			if (csr_we) begin
				case (csr_a[9:0])
          `HM_CSR_STAT: begin
            if (state == `HM_STATE_IDLE)
            begin
              /* write one to clear */
              if(csr_di[0])
                event_end <= 1'b0;
              if(csr_di[1])
                event_tx_timeout <= 1'b0;
              if(csr_di[2])
                event_rx_timeout <= 1'b0;
              if(csr_di[3])
                event_read_exp <= 1'b0;
              if(csr_di[4])
                event_write_bar <= 1'b0;
              if(csr_di[5])
                event_wr_timeout <= 1'b0;
            end
          end
          `HM_CSR_CTRL: begin
            if (state == `HM_STATE_IDLE) begin
              irq_en <= csr_di[0];
            end
            hm_start_read <= csr_di[1];
            hm_start_write <= csr_di[2];
            debug <= csr_di[3];
            nosnoop <= csr_di[4];
            override_id <= csr_di[5];
            hm_lock_write <= csr_di[6];
          end
          `HM_CSR_ADDRESS_LOW: address[31:0] <= csr_di;
          `HM_CSR_ADDRESS_HIGH: address[63:32] <= csr_di;
          `HM_CSR_BAR_BITMAP: bar_bitmap <= csr_di;
          `HM_CSR_DATA: data <= csr_di;
          `HM_CSR_ID: oid <= csr_di[15:0];
        endcase
      end
    end
    // Get events
    if (sys__hm_end) begin
      event_end <= 1'b1;
    end
    if (sys__rx_timeout) begin
      event_rx_timeout <= 1'b1;
    end
    if (sys__tx_timeout) begin
      event_tx_timeout <= 1'b1;
    end
    if (sys__wr_timeout) begin
      event_wr_timeout <= 1'b1;
    end
    if (sys__read_exp) begin
      event_read_exp <= 1'b1;
    end
    if (sys__write_bar) begin
      event_write_bar <= 1'b1;
    end
  end
end

// TRN state machine
always @(posedge trn_clk) begin
  if (sys_rst | ~trn_reset_n) begin
    init_trn();
  end else begin
    tx_start <= 1'b0;
    if (hm_lock_write == 1'b0) begin
      wr_start <= 1'b0;
    end
    hm_end <= 1'b0;
    rx_timeout <= 1'b0;
    tx_timeout <= 1'b0;
    wr_timeout <= 1'b0;
    if (state == `HM_STATE_IDLE) begin
      if (trn__hm_start_read == 1'b1) begin
        state <= `HM_STATE_SEND;
        tx_start <= 1'b1;
      end else if (hm_start_write == 1'b1) begin // We cannot both R/W
        state <= `HM_STATE_WRITE;
        wr_start <= 1'b1;
      end
    end else if (state == `HM_STATE_SEND) begin
      if (trn__tx_timeout == 1'b1) begin
        state <= `HM_STATE_IDLE;
      end else if (tx_end == 1'b1) begin
        state <= `HM_STATE_RECV;
      end
    end else if (state == `HM_STATE_RECV) begin
      if (trn__rx_timeout == 1'b1) begin
        state <= `HM_STATE_IDLE;
      end else if (rx_memory_read == 1'b1) begin
        state <= `HM_STATE_IDLE;
        hm_end <= 1'b1;
      end
    end else if (state == `HM_STATE_WRITE) begin
      if (trn__wr_timeout == 1'b1 || wr_end == 1'b1) begin
        state <= `HM_STATE_IDLE;
        hm_end <= 1'b1;
      end
    end else begin
      init_trn();
    end
    // Timeout
    if (state == `HM_STATE_IDLE) begin
      timeout_cpt <= 32'h00000000;
    end else begin
      timeout_cpt <= timeout_cpt + 1'b1;
      if (timeout_cpt == 32'h20000000) begin
        state <= `HM_STATE_IDLE;
        if (state == `HM_STATE_SEND) begin
          tx_timeout <= 1'b1;
        end
        if (state == `HM_STATE_RECV) begin
          rx_timeout <= 1'b1;
        end
        if (state == `HM_STATE_WRITE) begin
          wr_timeout <= 1'b1;
        end
        timeout_cpt <= 32'h00000000;
      end
    end
  end
end

// Rx Engine
hm_rx rx (
  .sys_rst(sys_rst),
  .rx_memory_read(rx_memory_read),
  .mem_l_addr(read_mem_l_addr),
  .mem_l_data_o(read_m_dib[0]),
  .mem_l_we(read_mem_l_we),
  .mem_h_addr(read_mem_h_addr),
  .mem_h_data_o(read_m_dib[1]),
  .mem_h_we(read_mem_h_we),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),
  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),
  .stat_trn_cpt_rx(trn__stat_trn_cpt_rx),
  .stat_state(trn__state_rx),
  .tlp_dw_g(trn__rx_tlp_dw),
  .sys_dgb_mode(debug) // Catch all the TLPs in rx
);

// Tx Engine
hm_tx tx (
  .sys_rst(sys_rst),
  .tx_start(tx_start),
  .tx_end(tx_end),
  .hm_addr({address[63:12],12'b0}),
  .nosnoop(nosnoop),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),

  .trn_tbuf_av(m0_trn_tbuf_av),
  .trn_terr_drop_n(m0_trn_terr_drop_n),
  .trn_tdst_rdy_n(m0_trn_tdst_rdy_n),
  .trn_cyc_n(m0_trn_cyc_n),
  .trn_td(m0_trn_td),
  .trn_trem_n(m0_trn_trem_n),
  .trn_tsof_n(m0_trn_tsof_n),
  .trn_teof_n(m0_trn_teof_n),
  .trn_tsrc_rdy_n(m0_trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(m0_trn_tsrc_dsc_n),
  .trn_terrfwd_n(m0_trn_terrfwd_n),
  .trn_tstr_n(m0_trn_tstr_n),

  .cfg_bus_number(id[15:8]),
  .cfg_device_number(id[7:3]),
  .cfg_function_number(id[2:0]),

  .stat_trn_cpt_tx(trn__stat_trn_cpt_tx),
  .stat_state(trn__state_tx),
  .stat_trn_cpt_tx_drop(trn__stat_trn_cpt_tx_drop),
  .stat_trn_cpt_tx_start(trn__stat_trn_cpt_tx_start),
  .error(trn__tx_error)
);

hm_exp exp (
  .sys_rst(sys_rst),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),

  .read_exp(read_exp),

  .mem_l_addr(exp_mem_l_addr),
  .mem_l_data_i(exp_m_dob[0]),

  .mem_h_addr(exp_mem_h_addr),
  .mem_h_data_i(exp_m_dob[1]),

  .trn_tbuf_av(m1_trn_tbuf_av),
  .trn_terr_drop_n(m1_trn_terr_drop_n),
  .trn_tdst_rdy_n(m1_trn_tdst_rdy_n),
  .trn_cyc_n(m1_trn_cyc_n),
  .trn_td(m1_trn_td),
  .trn_trem_n(m1_trn_trem_n),
  .trn_tsof_n(m1_trn_tsof_n),
  .trn_teof_n(m1_trn_teof_n),
  .trn_tsrc_rdy_n(m1_trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(m1_trn_tsrc_dsc_n),
  .trn_terrfwd_n(m1_trn_terrfwd_n),
  .trn_tstr_n(m1_trn_tstr_n),

  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),

  .cfg_bus_number(id[15:8]),
  .cfg_device_number(id[7:3]),
  .cfg_function_number(id[2:0])
);

hm_bar bar (
  .sys_rst(sys_rst),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),

  .write_bar(write_bar),
  .write_bar_number(trn__write_bar_number),
  .bar_bitmap(trn__bar_bitmap),

  .mem_l_addr(bar_mem_l_addr),
  .mem_l_data_i(bar_m_dob[0]),
  .mem_l_we(bar_mem_l_we),
  .mem_l_data_o(bar_m_dib[0]),

  .mem_h_addr(bar_mem_h_addr),
  .mem_h_data_i(bar_m_dob[1]),
  .mem_h_we(bar_mem_h_we),
  .mem_h_data_o(bar_m_dib[1]),

  .trn_tbuf_av(m2_trn_tbuf_av),
  .trn_terr_drop_n(m2_trn_terr_drop_n),
  .trn_tdst_rdy_n(m2_trn_tdst_rdy_n),
  .trn_cyc_n(m2_trn_cyc_n),
  .trn_td(m2_trn_td),
  .trn_trem_n(m2_trn_trem_n),
  .trn_tsof_n(m2_trn_tsof_n),
  .trn_teof_n(m2_trn_teof_n),
  .trn_tsrc_rdy_n(m2_trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(m2_trn_tsrc_dsc_n),
  .trn_terrfwd_n(m2_trn_terrfwd_n),
  .trn_tstr_n(m2_trn_tstr_n),

  .trn_rd(trn_rd),
  .trn_rrem_n(trn_rrem_n),
  .trn_rsof_n(trn_rsof_n),
  .trn_reof_n(trn_reof_n),
  .trn_rsrc_rdy_n(trn_rsrc_rdy_n),
  .trn_rsrc_dsc_n(trn_rsrc_dsc_n),
  .trn_rerrfwd_n(trn_rerrfwd_n),
  .trn_rbar_hit_n(trn_rbar_hit_n),

  .cfg_bus_number(id[15:8]),
  .cfg_device_number(id[7:3]),
  .cfg_function_number(id[2:0])
);

// WR Engine
hm_wr wr (
  .sys_rst(sys_rst),
  .tx_start(wr_start),
  .tx_end(wr_end),
  .hm_addr(address[63:0]),
  .hm_data(data),
  .nosnoop(nosnoop),

  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),

  .trn_tbuf_av(m3_trn_tbuf_av),
  .trn_terr_drop_n(m3_trn_terr_drop_n),
  .trn_tdst_rdy_n(m3_trn_tdst_rdy_n),
  .trn_cyc_n(m3_trn_cyc_n),
  .trn_td(m3_trn_td),
  .trn_trem_n(m3_trn_trem_n),
  .trn_tsof_n(m3_trn_tsof_n),
  .trn_teof_n(m3_trn_teof_n),
  .trn_tsrc_rdy_n(m3_trn_tsrc_rdy_n),
  .trn_tsrc_dsc_n(m3_trn_tsrc_dsc_n),
  .trn_terrfwd_n(m3_trn_terrfwd_n),
  .trn_tstr_n(m3_trn_tstr_n),

  .cfg_bus_number(id[15:8]),
  .cfg_device_number(id[7:3]),
  .cfg_function_number(id[2:0]),

  .stat_trn_cpt_tx(),
  .stat_state(),
  .stat_trn_cpt_drop()
);

// TRN Conbus
hm_conbus5 conbus5(
  .trn_clk(trn_clk),
  .trn_rst(sys_rst | ~trn_reset_n),
	
	// Master 0 Interface
  .m0_trn_tbuf_av(m0_trn_tbuf_av),
  .m0_trn_terr_drop_n(m0_trn_terr_drop_n),
  .m0_trn_tdst_rdy_n(m0_trn_tdst_rdy_n),
  .m0_trn_cyc_n(m0_trn_cyc_n),
  .m0_trn_td(m0_trn_td),
  .m0_trn_trem_n(m0_trn_trem_n),
  .m0_trn_tsof_n(m0_trn_tsof_n),
  .m0_trn_teof_n(m0_trn_teof_n),
  .m0_trn_tsrc_rdy_n(m0_trn_tsrc_rdy_n),
  .m0_trn_tsrc_dsc_n(m0_trn_tsrc_dsc_n),
  .m0_trn_terrfwd_n(m0_trn_terrfwd_n),
  .m0_trn_tstr_n(m0_trn_tstr_n),
	
  // Master 1 Interface
  .m1_trn_tbuf_av(m1_trn_tbuf_av),
  .m1_trn_terr_drop_n(m1_trn_terr_drop_n),
  .m1_trn_tdst_rdy_n(m1_trn_tdst_rdy_n),
  .m1_trn_cyc_n(m1_trn_cyc_n),
  .m1_trn_td(m1_trn_td),
  .m1_trn_trem_n(m1_trn_trem_n),
  .m1_trn_tsof_n(m1_trn_tsof_n),
  .m1_trn_teof_n(m1_trn_teof_n),
  .m1_trn_tsrc_rdy_n(m1_trn_tsrc_rdy_n),
  .m1_trn_tsrc_dsc_n(m1_trn_tsrc_dsc_n),
  .m1_trn_terrfwd_n(m1_trn_terrfwd_n),
  .m1_trn_tstr_n(m1_trn_tstr_n),

  // Master 2 Interface
  .m2_trn_tbuf_av(m2_trn_tbuf_av),
  .m2_trn_terr_drop_n(m2_trn_terr_drop_n),
  .m2_trn_tdst_rdy_n(m2_trn_tdst_rdy_n),
  .m2_trn_cyc_n(m2_trn_cyc_n),
  .m2_trn_td(m2_trn_td),
  .m2_trn_trem_n(m2_trn_trem_n),
  .m2_trn_tsof_n(m2_trn_tsof_n),
  .m2_trn_teof_n(m2_trn_teof_n),
  .m2_trn_tsrc_rdy_n(m2_trn_tsrc_rdy_n),
  .m2_trn_tsrc_dsc_n(m2_trn_tsrc_dsc_n),
  .m2_trn_terrfwd_n(m2_trn_terrfwd_n),
  .m2_trn_tstr_n(m2_trn_tstr_n),
	
	// Master 3 Interface
  .m3_trn_tbuf_av(m3_trn_tbuf_av),
  .m3_trn_terr_drop_n(m3_trn_terr_drop_n),
  .m3_trn_tdst_rdy_n(m3_trn_tdst_rdy_n),
  .m3_trn_cyc_n(m3_trn_cyc_n),
  .m3_trn_td(m3_trn_td),
  .m3_trn_trem_n(m3_trn_trem_n),
  .m3_trn_tsof_n(m3_trn_tsof_n),
  .m3_trn_teof_n(m3_trn_teof_n),
  .m3_trn_tsrc_rdy_n(m3_trn_tsrc_rdy_n),
  .m3_trn_tsrc_dsc_n(m3_trn_tsrc_dsc_n),
  .m3_trn_terrfwd_n(m3_trn_terrfwd_n),
  .m3_trn_tstr_n(m3_trn_tstr_n),
	
	// Master 4 Interface
  .m4_trn_tbuf_av(),
  .m4_trn_terr_drop_n(),
  .m4_trn_tdst_rdy_n(),
  .m4_trn_cyc_n(1'b1),
  .m4_trn_td(64'bx),
  .m4_trn_trem_n(1'bx),
  .m4_trn_tsof_n(1'bx),
  .m4_trn_teof_n(1'bx),
  .m4_trn_tsrc_rdy_n(1'bx),
  .m4_trn_tsrc_dsc_n(1'bx),
  .m4_trn_terrfwd_n(1'bx),
  .m4_trn_tstr_n(1'bx),

  // Slave Interface
  .s_trn_tbuf_av(trn_tbuf_av),
  .s_trn_terr_drop_n(trn_terr_drop_n),
  .s_trn_tdst_rdy_n(trn_tdst_rdy_n),
  .s_trn_td(trn_td),
  .s_trn_trem_n(trn_trem_n),
  .s_trn_tsof_n(trn_tsof_n),
  .s_trn_teof_n(trn_teof_n),
  .s_trn_tsrc_rdy_n(trn_tsrc_rdy_n),
  .s_trn_tsrc_dsc_n(trn_tsrc_dsc_n),
  .s_trn_terrfwd_n(trn_terrfwd_n),
  .s_trn_tstr_n(trn_tstr_n)
);

// Sync

hm_sync sync (
  .sys_clk(sys_clk),
  .trn_clk(trn_clk),
  .trn__rx_timeout(trn__rx_timeout),
  .sys__rx_timeout(sys__rx_timeout),
  .trn__tx_timeout(trn__tx_timeout),
  .sys__tx_timeout(sys__tx_timeout),
  .trn__wr_timeout(trn__wr_timeout),
  .sys__wr_timeout(sys__wr_timeout),
  .trn__hm_end(trn__hm_end),
  .sys__hm_end(sys__hm_end),
  .trn__write_bar(trn__write_bar),
  .sys__write_bar(sys__write_bar),
  .trn__write_bar_number(trn__write_bar_number),
  .sys__write_bar_number(sys__write_bar_number),
  .trn__bar_bitmap(trn__bar_bitmap),
  .sys__bar_bitmap(sys__bar_bitmap),
  .trn__read_exp(trn__read_exp),
  .sys__read_exp(sys__read_exp),
  .trn__trn_lnk_up_n(trn__trn_lnk_up_n),
  .sys__trn_lnk_up_n(sys__trn_lnk_up_n),
  .trn__state_rx(trn__state_rx),
  .sys__state_rx(sys__state_rx),
  .trn__rx_tlp_dw(trn__rx_tlp_dw),
  .sys__rx_tlp_dw(sys__rx_tlp_dw),
  .trn__state_tx(trn__state_tx),
  .sys__state_tx(sys__state_tx),
  .trn__stat_trn_cpt_tx(trn__stat_trn_cpt_tx),
  .sys__stat_trn_cpt_rx(sys__stat_trn_cpt_rx),
  .trn__stat_trn_cpt_rx(trn__stat_trn_cpt_rx),
  .sys__stat_trn_cpt_tx(sys__stat_trn_cpt_tx),
  .trn__stat_trn_cpt_tx_drop(trn__stat_trn_cpt_tx_drop),
  .sys__stat_trn_cpt_tx_drop(sys__stat_trn_cpt_tx_drop),
  .trn__stat_trn_cpt_tx_start(trn__stat_trn_cpt_tx_start),
  .sys__stat_trn_cpt_tx_start(sys__stat_trn_cpt_tx_start),
  .trn__tx_error(trn__tx_error),
  .sys__tx_error(sys__tx_error),
  .trn__state(trn__state),
  .sys__state(sys__state),
  .sys__hm_start_read(sys__hm_start_read),
  .trn__hm_start_read(trn__hm_start_read)
);

// Memory HM read

assign read_m_web[0] = (read_mem_l_we == 1'b1) ? 4'b1111 : 4'b0000;
assign read_m_web[1] = (read_mem_h_we == 1'b1) ? 4'b1111 : 4'b0000;
assign read_m_addrb[0] = read_mem_l_addr;
assign read_m_addrb[1] = read_mem_h_addr;
assign read_m_addra[0] = wb_adr_i[11:3];
assign read_m_addra[1] = wb_adr_i[11:3];

assign hm_data [63:0] = {read_m_hm_dob[1][31:0], read_m_hm_dob[0][31:0]};

assign read_m_dia[0] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};
assign read_m_dia[1] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};

assign read_m_wea[0] = (wb_en & wb_we_i & ~wb_adr_i[2] & ~wb_adr_i[13] &
  ~wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;
assign read_m_wea[1] = (wb_en & wb_we_i & wb_adr_i[2] & ~wb_adr_i[13] &
  ~wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;

// Memory HM Expansion ROM

assign exp_m_addra[0] = wb_adr_i[11:3];
assign exp_m_addra[1] = wb_adr_i[11:3];

assign exp_m_dia[0] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};
assign exp_m_dia[1] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};

assign exp_m_wea[0] = (wb_en & wb_we_i & ~wb_adr_i[2] & ~wb_adr_i[13] &
  wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;
assign exp_m_wea[1] = (wb_en & wb_we_i & wb_adr_i[2] & ~wb_adr_i[13] &
  wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;

// Memory BAR

assign bar_m_addra[0] = wb_adr_i[11:3];
assign bar_m_addra[1] = wb_adr_i[11:3];

assign bar_m_dia[0] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};
assign bar_m_dia[1] = {
  wb_dat_i[7:0],
  wb_dat_i[15:8],
  wb_dat_i[23:16],
  wb_dat_i[31:24]
};

assign bar_m_wea[0] = (wb_en & wb_we_i & ~wb_adr_i[2] & wb_adr_i[13] &
  ~wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;
assign bar_m_wea[1] = (wb_en & wb_we_i & wb_adr_i[2] & wb_adr_i[13] &
  ~wb_adr_i[12]) ? wb_sel_i_le : 4'b0000;

// Memory HM read / Memory HM Expansion ROM / Memory BAR
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
	) read_ram (
		.DIA(read_m_dia[ram_index]),
		.DIPA(4'h0),
		.DOA(read_m_doa[ram_index]),
		.ADDRA({1'b0, read_m_addra[ram_index], 5'b0}),
		.WEA(read_m_wea[ram_index]),
		.ENA(1'b1),
		.CLKA(sys_clk),
		
		.DIB(read_m_dib[ram_index]),
		.DIPB(4'h0),
		.DOB(),
		.ADDRB({1'b0, read_m_addrb[ram_index][9:0], 5'b0}),
		.WEB(read_m_web[ram_index]),
		.ENB(1'b1),
		.CLKB(trn_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
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
	) read_ram_hm (
		.DIA(read_m_dia[ram_index]),
		.DIPA(4'h0),
		.DOA(),
		.ADDRA({1'b0, read_m_addra[ram_index], 5'b0}),
		.WEA(read_m_wea[ram_index]),
		.ENA(1'b1),
		.CLKA(sys_clk),
		
    // wire here hm_addr and data yolol <3
		.DIB(32'b0),
		.DIPB(4'h0),
		.DOB(read_m_hm_dob[ram_index]),
		.ADDRB({1'b0, hm_addr[11:3], 5'b0}),
		.WEB(4'b0),
		.ENB(1'b1),
		.CLKB(trn_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
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
	) exp_ram (
		.DIA(exp_m_dia[ram_index]),
		.DIPA(4'h0),
		.DOA(exp_m_doa[ram_index]),
		.ADDRA({1'b0, exp_m_addra[ram_index], 5'b0}),
		.WEA(exp_m_wea[ram_index]),
		.ENA(1'b1),
		.CLKA(sys_clk),
		
		.DIB(32'b0),
		.DIPB(4'h0),
		.DOB(exp_m_dob[ram_index]),
		.ADDRB({1'b0, exp_m_addrb[ram_index][9:0], 5'b0}),
		.WEB(4'h0),
		.ENB(1'b1),
		.CLKB(trn_clk),

		.REGCEA(1'b0),
		.REGCEB(1'b0),
		
		.SSRA(1'b0),
		.SSRB(1'b0)
	);
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
	) bar_ram (
		.DIA(bar_m_dia[ram_index]),
		.DIPA(4'h0),
		.DOA(bar_m_doa[ram_index]),
		.ADDRA({1'b0, bar_m_addra[ram_index], 5'b0}),
		.WEA(bar_m_wea[ram_index]),
		.ENA(1'b1),
		.CLKA(sys_clk),
		
		.DIB(bar_m_dib[ram_index]),
		.DIPB(4'h0),
		.DOB(bar_m_dob[ram_index]),
		.ADDRB({1'b0, bar_m_addrb[ram_index][9:0], 5'b0}),
		.WEB(bar_m_web[ram_index]),
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
  hm_memory_32 read_m (
		.DIA(read_m_dia[ram_index]),
		.DOA(read_m_doa[ram_index]),
		.ADDRA({1'b0, read_m_addra[ram_index], 5'b0}),
		.WEA(read_m_wea[ram_index]),
		.CLKA(sys_clk),
		
		.DIB(read_m_dib[ram_index]),
		.DOB(),
		.ADDRB({1'b0, read_m_addrb[ram_index][9:0], 5'b0}),
    .WEB(read_m_web[ram_index]),
		.CLKB(trn_clk)
  );
  hm_memory_32 read_m_hm (
		.DIA(read_m_dia[ram_index]),
		.DOA(),
		.ADDRA({1'b0, read_m_addra[ram_index], 5'b0}),
		.WEA(read_m_wea[ram_index]),
		.CLKA(sys_clk),
		
		.DIB(32'b0),
		.DOB(read_m_hm_dob[ram_index]),
		.ADDRB({1'b0, 10'b0, 5'b0}),
    .WEB(4'b0),
		.CLKB(trn_clk)
  );
  hm_memory_32 exp_m (
		.DIA(exp_m_dia[ram_index]),
		.DOA(exp_m_doa[ram_index]),
		.ADDRA({1'b0, exp_m_addra[ram_index], 5'b0}),
		.WEA(exp_m_wea[ram_index]),
		.CLKA(sys_clk),
		
		.DIB(32'b0),
		.DOB(exp_m_dob[ram_index]),
		.ADDRB({1'b0, exp_m_addrb[ram_index][9:0], 5'b0}),
    .WEB(4'h0),
		.CLKB(trn_clk)
  );
  hm_memory_32 bar_m (
		.DIA(bar_m_dia[ram_index]),
		.DOA(bar_m_doa[ram_index]),
		.ADDRA({1'b0, bar_m_addra[ram_index], 5'b0}),
		.WEA(bar_m_wea[ram_index]),
		.CLKA(sys_clk),
		
		.DIB(bar_m_dib[ram_index]),
		.DOB(bar_m_dob[ram_index]),
		.ADDRB({1'b0, bar_m_addrb[ram_index][9:0], 5'b0}),
    .WEB(bar_m_web[ram_index]),
		.CLKB(trn_clk)
  );
end
endgenerate
`endif//SIMULATION

always @(*) begin
  if (sys_rst == 1'b1) begin
	  wb_dat_o = 32'b0;
  end else begin
    if (~wb_adr_i[13] & ~wb_adr_i[12]) begin
      if (~wb_adr_i[2]) begin
        wb_dat_o = {
          read_m_doa[0][7:0],
          read_m_doa[0][15:8],
          read_m_doa[0][23:16],
          read_m_doa[0][31:24]
        };
      end else begin
        wb_dat_o = {
          read_m_doa[1][7:0],
          read_m_doa[1][15:8],
          read_m_doa[1][23:16],
          read_m_doa[1][31:24]
        };
      end
    end else if (~wb_adr_i[13] & wb_adr_i[12]) begin
      if (~wb_adr_i[2]) begin
        wb_dat_o = {
          exp_m_doa[0][7:0],
          exp_m_doa[0][15:8],
          exp_m_doa[0][23:16],
          exp_m_doa[0][31:24]
        };
      end else begin
        wb_dat_o = {
          exp_m_doa[1][7:0],
          exp_m_doa[1][15:8],
          exp_m_doa[1][23:16],
          exp_m_doa[1][31:24]
        };
      end
    end else begin
      if (~wb_adr_i[2]) begin
        wb_dat_o = {
          bar_m_doa[0][7:0],
          bar_m_doa[0][15:8],
          bar_m_doa[0][23:16],
          bar_m_doa[0][31:24]
        };
      end else begin
        wb_dat_o = {
          bar_m_doa[1][7:0],
          bar_m_doa[1][15:8],
          bar_m_doa[1][23:16],
          bar_m_doa[1][31:24]
        };
      end
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

endmodule
