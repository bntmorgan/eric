`include "hm.vh"

/**
 * Transmits a 3 or 4 dw Memory Read request with hm_addr address
 */

module hm_tx (
  input sys_rst,

  input tx_start,
  output reg tx_end,

  input [63:0] hm_addr,

  // Trn transmit interface
  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,
  output reg [63:0] trn_td,
  output reg trn_tsof_n,
  output reg trn_trem_n,
  output reg trn_teof_n,
  output reg trn_tsrc_rdy_n,
  input trn_tdst_rdy_n,
  input [5:0] trn_tbuf_av,
  input trn_tcfg_req_n,
  input trn_terr_drop_n,
  output trn_tsrc_dsc_n,
  output trn_terrfwd_n,
  output trn_tcfg_gnt_n,
  output trn_tstr_n,

  // User statistics counters ans status
  output reg [15:0] stat_trn_cpt_tx,
  output reg [7:0] stat_trn_cpt_drop,
  output [1:0] stat_state,

  output reg timeout
);

/**
 * Core input tie-offs
 */
assign trn_tstr_n = 1'b0;
assign trn_terrfwd_n = 1'b1;
assign trn_tcfg_gnt_n = 1'b0;
assign trn_tsrc_dsc_n = 1'b1;
assign stat_state = state;

reg state;
reg [1:0] cpt;
reg [63:0] data [1:0];

// reg [31:0] timeout_cpt;
reg [15:0] timeout_cpt;

assign stat_state = state;

task init;
begin
  state <= `HM_TX_STATE_IDLE;
  tx_end <= 1'b0;
  cpt <= 2'b0;
  trn_td <= 64'b0;
  trn_tsof_n <= 1'b1;
  trn_trem_n <= 1'b1;
  trn_teof_n <= 1'b1;
  trn_tsrc_rdy_n <= 1'b1;
  /**
   * TLP header
   *
   * 3DW
   * 00 00 00 10 XX 00 38 FF  00 00 00 00
   *
   * 4DW
   * 20 00 00 10 XX 00 38 FF  00 00 00 00
   */
  data[0] <= {
    3'b001, // fmt[2:0] = 3'b001 : 4DW header no data
    5'b00000, // type[4:0] = 5'b00000 : Memory read request

    8'b0, // Unspecified

    4'b0, // Unspecified
    2'b0, // AT, Address type : 2'b0 Default Untranslated
    // 10'b100000000, // 256 dw requested
    10'b000000000, // 1024 dw requested
    16'h1800, // Requester ID
    // 16'h0400, // Requester ID
    8'h38, // Tag
    4'hf, // Last BE : TODO > 1 DW
    4'hf // 1st BE : TODO > 1 DW
  };
  data[1] <= 64'b0;
  stat_trn_cpt_tx <= 16'h0000;
  stat_trn_cpt_drop <= 8'b0;
  // timeout_cpt <= 32'h00000000;
  timeout_cpt <= 16'h0000;
  timeout <= 1'b0;
end
endtask

initial begin
  init();
end

wire is_lower_4_gb = (hm_addr[63:0] & 64'hffffffff00000000) == 64'b0;

always @(posedge trn_clk) begin
  if (sys_rst == 1'b1 || trn_reset_n == 1'b0) begin
    init();
  end else begin
    if (trn_terr_drop_n == 1'b0) begin
      stat_trn_cpt_drop <= stat_trn_cpt_drop + 1'b1;
    end
    if (state == `HM_TX_STATE_IDLE) begin 
      timeout <= 1'b0;
      tx_end <= 1'b0;
      // timeout_cpt <= 32'h00000000;
      timeout_cpt <= 16'h0000;
      if (tx_start) begin
        state <= `HM_TX_STATE_SEND;
        if (is_lower_4_gb) begin
          data[1][63:32] <= hm_addr[31:0];
          data[0][63:61] <= 3'b000; // fmt[2:0] = 3'b000 : 3DW header no data
        end else begin
          data[1][63:0] <= hm_addr[63:0];
          data[0][63:61] <= 3'b001; // fmt[2:0] = 3'b001 : 4DW header no data
        end
      end
    end else begin
      if (cpt == `HM_TX_DW_TO_SEND) begin
        state <= `HM_TX_STATE_IDLE;
        tx_end <= 1'b1;
        cpt <= 2'b0;
        trn_tsrc_rdy_n <= 1'b1;
        trn_teof_n <= 1'b1;
        trn_trem_n <= 1'b1;
        trn_td <= 64'b0;
        stat_trn_cpt_tx <= stat_trn_cpt_tx + 1'b1;
      end else begin 
        trn_tsrc_rdy_n <= 1'b0;
        if (trn_tdst_rdy_n == 1'b0) begin 
          // Start of frame
          if (cpt == 2'b0) begin
            trn_tsof_n <= 1'b0;
          end else begin
            trn_tsof_n <= 1'b1;
          end
          // End of frame
          if (cpt == `HM_TX_DW_TO_SEND - 1) begin
            trn_teof_n <= 1'b0;
            if (is_lower_4_gb) begin
              trn_trem_n <= 1'b1;
            end else begin
              trn_trem_n <= 1'b0;
            end
          end
          // set the data
          trn_td <= data[cpt];
          cpt <= cpt + 1'b1;
        end else begin
          timeout_cpt <= timeout_cpt + 1'b1;
          // if (timeout_cpt == 16'h000f) begin
          if (timeout_cpt == 16'hffff) begin
          // if (timeout_cpt == 32'hffffffff) begin
            state <= `HM_TX_STATE_IDLE;
            timeout <= 1'b1;
          end
        end
      end
    end
  end
end

endmodule
