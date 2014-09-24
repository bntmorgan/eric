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
reg hm_start;
reg event_end;
reg event_error;
reg event_tx_timeout;
reg event_rx_timeout;
reg [63:0] address;

// IRQs
reg irq_en;
// assign irq = 0;
assign irq = (event_end & irq_en) | (event_tx_timeout & irq_en) |
  (event_rx_timeout & irq_en);

wire wb_en = wb_cyc_i & wb_stb_i;

// Trn

reg [1:0] state;
reg tx_start;
reg rx_start;
reg hm_end;
reg [15:0] timeout_cpt;

wire tx_end;
wire rx_memory_read;

task init_csr;
begin
  hm_start <= 1'b0;
  event_end <= 1'b0;
  event_rx_timeout <= 1'b0;
  event_tx_timeout <= 1'b0;
  event_end <= 1'b0;
  csr_do <= 32'd0; 
  irq_en <= 1'b0;
  address <= 64'b0;
end
endtask

// Memory

wire [9:0] mem_l_addr;
wire [9:0] mem_h_addr;
wire mem_l_we;
wire mem_h_we;
wire [31:0] m_doa [1:0];
wire [9:0] m_addra [1:0];
wire [31:0] m_dib [1:0];
wire [9:0] m_addrb [1:0];
wire [3:0] m_web [1:0];
assign m_web[0] = (mem_l_we == 1'b1) ? 4'b1111 : 4'b0000;
assign m_web[1] = (mem_h_we == 1'b1) ? 4'b1111 : 4'b0000;
assign m_addrb[0] = mem_l_addr;
assign m_addrb[1] = mem_h_addr;
assign hm_data [63:0] = {m_doa[1][31:0], m_doa[0][31:0]};

// Synced wires

wire [31:0] trn__stat_trn_cpt_tx;
wire [31:0] sys__stat_trn_cpt_tx;
wire [31:0] trn__stat_trn_cpt_rx;
wire [31:0] sys__stat_trn_cpt_rx;
wire [1:0] trn__state_rx; 
wire [1:0] sys__state_rx; 
wire [1:0] trn__state_tx; 
wire [1:0] sys__state_tx; 
wire [31:0] trn__stat_trn_cpt_drop;
wire [31:0] sys__stat_trn_cpt_drop;
wire trn__hm_end = hm_end;
wire sys__hm_end;
reg tx_timeout;
wire trn__tx_timeout = tx_timeout;
wire sys__tx_timeout;
reg rx_timeout;
wire trn__rx_timeout = rx_timeout;
wire sys__rx_timeout;
wire trn__trn_lnk_up_n = trn_lnk_up_n;
wire sys__trn_lnk_up_n;
wire [1:0] trn__state = state;
wire [1:0] sys__state;

task init_trn;
begin
  state <= `HM_STATE_IDLE;
  tx_start <= 1'b0;
  rx_start <= 1'b0;
  hm_end <= 1'b0;
  timeout_cpt <= 16'b0;
  rx_timeout <= 1'b0;
  tx_timeout <= 1'b0;
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
    hm_start <= 1'b0;
		if (csr_selected) begin
			case (csr_a[9:0])
        `HM_CSR_STAT: csr_do <= {29'b0, event_rx_timeout, event_tx_timeout,
          event_end};
        `HM_CSR_CTRL: csr_do <= {29'b0, hm_start, irq_en};
        `HM_CSR_ADDRESS_LOW: csr_do <= address[31:0];
        `HM_CSR_ADDRESS_HIGH: csr_do <= address[63:32];
        `HM_CSR_CPT_RX: csr_do <= sys__stat_trn_cpt_rx;
        `HM_CSR_CPT_TX: csr_do <= sys__stat_trn_cpt_tx;
        `HM_CSR_STATE_RX: csr_do <= sys__state_rx;
        `HM_CSR_STATE_TX: csr_do <= sys__state_tx;
        `HM_CSR_STATE: csr_do <= sys__state;
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
            end
          end
          `HM_CSR_CTRL: begin
            if (state == `HM_STATE_IDLE) begin
              irq_en <= csr_di[0];
            end
            // We can only write stop when one mpu is launched
            hm_start <= csr_di[1];
          end
          `HM_CSR_ADDRESS_LOW: address[31:0] <= csr_di;
          `HM_CSR_ADDRESS_HIGH: address[61:32] <= csr_di;
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
  end
end

// TRN state machine
always @(posedge trn_clk) begin
  if (sys_rst | ~trn_reset_n) begin
    init_trn();
  end else begin
    tx_start <= 1'b0;
    hm_end <= 1'b0;
    rx_timeout <= 1'b0;
    tx_timeout <= 1'b0;
    if (state == `HM_STATE_IDLE) begin
      if (hm_start == 1'b1) begin
        state <= `HM_STATE_SEND;
        tx_start <= 1'b1;
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
    end else begin
      init_trn();
    end
    // Timeout
    if (state == `HM_STATE_IDLE) begin
      timeout_cpt <= 16'h0000;
    end else begin
      timeout_cpt <= timeout_cpt + 1'b1;
      if (timeout_cpt == 16'hffff) begin
        state <= `HM_STATE_IDLE;
        if (state == `HM_STATE_SEND) begin
          tx_timeout <= 1'b1;
        end
        if (state == `HM_STATE_RECV) begin
          rx_timeout <= 1'b1;
        end
        timeout_cpt <= 16'h0000;
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

// Rx Engine

hm_rx rx (
  .sys_rst(sys_rst),
  .rx_memory_read(rx_memory_read),
  .mem_l_addr(mem_l_addr),
  .mem_l_data(m_dib[0]),
  .mem_l_we(mem_l_we),
  .mem_h_addr(mem_h_addr),
  .mem_h_data(m_dib[1]),
  .mem_h_we(mem_h_we),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),
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
  .stat_state(trn__state_rx)
);

// Tx Engine
hm_tx tx (
  .sys_rst(sys_rst),
  .tx_start(tx_start),
  .tx_end(tx_end),
  .hm_addr({address[63:12],12'b0}),
  .trn_clk(trn_clk),
  .trn_reset_n(trn_reset_n),
  .trn_lnk_up_n(trn_lnk_up_n),
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
  .stat_state(trn__state_tx),
  .stat_trn_cpt_drop(trn__stat_trn_cpt_drop)
);

// Memory

assign m_addra[0] = (wb_en == 1'b1) ? wb_adr_i[11:3] : hm_addr[11:3];
assign m_addra[1] = (wb_en == 1'b1) ? wb_adr_i[11:3] : hm_addr[11:3];

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
        m_doa[0][7:0],
        m_doa[0][15:8],
        m_doa[0][23:16],
        m_doa[0][31:24]
      };
    end else begin
      wb_dat_o = {
        m_doa[1][7:0],
        m_doa[1][15:8],
        m_doa[1][23:16],
        m_doa[1][31:24]
      };
    end
  end
end

// Sync

hm_sync sync (
  .sys_clk(sys_clk),
  .trn_clk(trn_clk),
  .trn__rx_timeout(trn__rx_timeout),
  .sys__rx_timeout(sys__rx_timeout),
  .trn__tx_timeout(trn__tx_timeout),
  .sys__tx_timeout(sys__tx_timeout),
  .trn__hm_end(trn__hm_end),
  .sys__hm_end(sys__hm_end),
  .trn__trn_lnk_up_n(trn__trn_lnk_up_n),
  .sys__trn_lnk_up_n(sys__trn_lnk_up_n),
  .trn__state_rx(trn__state_rx),
  .sys__state_rx (sys__state_rx ),
  .trn__state_tx(trn__state_tx),
  .sys__state_tx(sys__state_tx),
  .trn__stat_trn_cpt_tx(trn__stat_trn_cpt_tx),
  .sys__stat_trn_cpt_rx(sys__stat_trn_cpt_rx),
  .trn__stat_trn_cpt_rx(trn__stat_trn_cpt_rx),
  .sys__stat_trn_cpt_tx(sys__stat_trn_cpt_tx),
  .trn__stat_trn_cpt_drop(trn__stat_trn_cpt_drop),
  .sys__stat_trn_cpt_drop(sys__stat_trn_cpt_drop),
  .trn__state(trn__state),
  .sys__state(sys__state)
);

endmodule
