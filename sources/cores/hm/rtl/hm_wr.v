`include "hm.vh"

/**
 * Transmits a Memory Write 32 to the specified address
 * XXX only writes under 4GB
 */

module hm_wr (
  input sys_rst,

  input tx_start,
  output reg tx_end,

  input [63:0] hm_addr,
  input [31:0] hm_data,
  input nosnoop,

  // Trn transmit interface
  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,
  output reg trn_cyc_n,
  output reg [63:0] trn_td,
  output reg trn_tsof_n,
  output reg trn_trem_n,
  output reg trn_teof_n,
  output reg trn_tsrc_rdy_n,
  input trn_tdst_rdy_n,
  input [5:0] trn_tbuf_av,
  input trn_terr_drop_n,
  output trn_tsrc_dsc_n,
  output trn_terrfwd_n,
  output trn_tstr_n,

  // User statistics counters ans status
  output reg [31:0] stat_trn_cpt_tx,
  output reg [31:0] stat_trn_cpt_drop,
  output [1:0] stat_state,

  // Requester ID sharing
  input [7:0] cfg_bus_number,
  input [4:0] cfg_device_number,
  input [2:0] cfg_function_number,

  output reg timeout
);

wire [15:0] req_id = {cfg_bus_number, cfg_device_number, cfg_function_number};

/**
 * Core input tie-offs
 */
assign trn_tstr_n = 1'b0;
assign trn_terrfwd_n = 1'b1;
assign trn_tsrc_dsc_n = 1'b1;
assign stat_state = state;

reg state;
reg [2:0] cpt;
reg [63:0] data [2:0];
reg [31:0] timeout_cpt;
reg [2:0] dw_to_send;

task init;
begin
  state <= `HM_TX_STATE_IDLE;
  tx_end <= 1'b0;
  cpt <= 3'b0;
  trn_cyc_n <= 1'b1;
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
    3'b011, // fmt[2:0] = 3'b001 : 4DW header no data
    5'b00000, // type[4:0] = 5'b00000 : Memory write request

    8'b0, // Unspecified : TC0

    2'b0, // Unspecified : reserved
    1'b0,
    1'b0, // Attribute : No nosnoop !!
    2'b0, // AT, Address type : 2'b0 Default Untranslated
    10'b000001, // 32 dw requested XXX Max Payload Size for our root complex
    16'h0000, // Requester ID
    8'h00, // Tag
    4'h0, // Last BE : XXX Only one DW
    4'hf // 1st BE : XXX Only one DW
  };
  data[1] <= 64'b0;
  data[2] <= 64'b0;
  stat_trn_cpt_tx <= 32'b0;
  stat_trn_cpt_drop <= 32'b0;
  timeout_cpt <= 32'h00000000;
  timeout <= 1'b0;
  dw_to_send <= 3'b0;
end
endtask

initial begin
  init();
end

wire is_lower_4_gb = (hm_addr[63:0] & 64'hffffffff00000000) == 64'b0;

always @(posedge trn_clk) begin
  if (sys_rst == 1'b1 || trn_reset_n == 1'b0 || trn_lnk_up_n == 1'b1) begin
    init();
  end else begin
    if (trn_terr_drop_n == 1'b0) begin
      stat_trn_cpt_drop <= stat_trn_cpt_drop + 1'b1;
    end
    if (state == `HM_TX_STATE_IDLE) begin
      timeout <= 1'b0;
      tx_end <= 1'b0;
      timeout_cpt <= 32'h00000000;
      if (tx_start) begin
        state <= `HM_TX_STATE_SEND;
        trn_cyc_n <= 1'b0;
        // Set the requester id
        data[0][31:16] <= req_id;
        data[0][44] <= nosnoop;
        if (is_lower_4_gb) begin
          data[1][31:0] <= hm_data[31:0];
          data[1][63:32] <= {hm_addr[31:2], 2'b0};
          data[0][61] <= 1'b0; // fmt[0] = 1'b0 : 3DW header no data
          dw_to_send <= 3'h4;
        end else begin
          data[2][63:32] <= hm_data[31:0];
          data[1][63:0] <= {hm_addr[63:2], 2'b0};
          // XXX YOLOL
          // data[1][63:0] <= {64'h40b157010};
          data[0][61] <= 1'b1; // fmt[0] = 1'b1 : 4DW header no data
          dw_to_send <= 3'h5;
        end
      end
    end else begin
      if (cpt >= dw_to_send) begin
        state <= `HM_TX_STATE_IDLE;
        tx_end <= 1'b1;
        cpt <= 2'b0;
        dw_to_send <= 3'b0;
        trn_cyc_n <= 1'b1;
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
          if (cpt >= dw_to_send - 2) begin
            trn_teof_n <= 1'b0;
            if (is_lower_4_gb) begin
              trn_trem_n <= 1'b0;
            end else begin
              trn_trem_n <= 1'b1;
            end
          end
          // set the data
          trn_td <= data[cpt >> 1];
          cpt <= cpt + 3'b10;
        end else begin
          timeout_cpt <= timeout_cpt + 1'b1;
          if (timeout_cpt == 32'h08000000) begin
            state <= `HM_TX_STATE_IDLE;
            timeout <= 1'b1;
          end
        end
      end
    end
  end
end

endmodule
