`include "hm.vh"

/**
 * This is a test core
 */

module hm_mr (
  input sys_rst,

  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,

  // Trn transmit interface
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

  // Trn receive interface
  input [63:0] trn_rd,
  input trn_rrem_n,
  input trn_rsof_n,
  input trn_reof_n,
  input trn_rsrc_rdy_n,
  output reg trn_rdst_rdy_n,
  input trn_rsrc_dsc_n,
  input trn_rerrfwd_n,
  output trn_rnp_ok_n,
  input [6:0] trn_rbar_hit_n,

  // Cfg interface
  input [7:0] cfg_bus_number,
  input [4:0] cfg_device_number,
  input [2:0] cfg_function_number,

  output reg [15:0] stat_trn_cpt_tx
);

/**
 * Core input tie-offs
 */
assign trn_tstr_n = 1'b0;
assign trn_terrfwd_n = 1'b1;
assign trn_tcfg_gnt_n = 1'b0;
assign trn_tsrc_dsc_n = 1'b1;

reg [1:0] state;

wire [63:0] completion [1:0];

wire is_memory_read_request = trn_rd[63:56] == {3'b0, 5'b00000};
wire [15:0] pci_c_id = {cfg_bus_number, cfg_device_number, cfg_function_number};
reg [15:0] pci_r_id;
reg [29:0] req_addr;
reg [3:0] ldw;
reg [3:0] fdw;
reg [9:0] length;
reg [7:0] tag; 
reg [2:0] tc;
reg td;
reg ep;
reg [1:0] attr;

assign completion[0][63:0] = {
  {1'b0},
  {7'b10_01010}, // Mem read completion
  {1'b0},
  tc, // tc
  {4'b0},
  td, // td
  ep, // ep
  attr, // attr
  {2'b0},
  {10'b00_0000_0001}, // length nb DW
  pci_c_id, // our pci id
  {3'b0}, // completion status ok
  {1'b0}, // BCM
  byte_count // n bytes
};

assign completion[1][63:0] = {
  pci_r_id, // pci requester id
  tag, // No tag
  1'b0, // Reserved
  lower_addr, // LSBs of the requested address
  32'hcacacaca // data sent
};

reg [1:0] dw_sent;

// wire [2:0] nb_ldw = ldw[0] + ldw[1] + ldw[2] + ldw[3];
// wire [2:0] nb_fdw = fdw[0] + fdw[1] + fdw[2] + fdw[3];
// 
// wire [11:0] bytes = (((length - 2 >= length) ? 0 : length - 2) << 2) + nb_ldw
//   + nb_fdw;

// wire [11:0] byte_count = 
//   (fdw == 4'b1xx1) ? 12'h004 :
//   (fdw == 4'b01x1) ? 12'h003 :
//   (fdw == 4'b1x10) ? 12'h003 :
//   (fdw == 4'b0011) ? 12'h002 :
//   (fdw == 4'b0110) ? 12'h002 :
//   (fdw == 4'b1100) ? 12'h002 :
//   (fdw == 4'b0001) ? 12'h001 :
//   (fdw == 4'b0010) ? 12'h001 :
//   (fdw == 4'b0100) ? 12'h001 :
//   (fdw == 4'b1000) ? 12'h001 :
//                      12'h001 ; // (fdw == 4'b0000) ?
// wire [06:0] lower_addr =
//   (fdw == 4'b0000) ? {req_addr[6:2], 2'b00} :
//   (fdw == 4'bxxx1) ? {req_addr[6:2], 2'b00} :
//   (fdw == 4'bxx10) ? {req_addr[6:2], 2'b01} :
//   (fdw == 4'bx100) ? {req_addr[6:2], 2'b10} :
//                      {req_addr[6:2], 2'b11} ; // (req_addr == 4'b1000) ? 
// 

reg [06:0] lower_addr;
reg [11:0] byte_count; 

/*
* Calculate byte count based on byte enable
*/
always @(fdw) begin
  casex (fdw[3:0])
    4'b1xx1 : byte_count = 12'h004;
    4'b01x1 : byte_count = 12'h003;
    4'b1x10 : byte_count = 12'h003;
    4'b0011 : byte_count = 12'h002;
    4'b0110 : byte_count = 12'h002;
    4'b1100 : byte_count = 12'h002;
    4'b0001 : byte_count = 12'h001;
    4'b0010 : byte_count = 12'h001;
    4'b0100 : byte_count = 12'h001;
    4'b1000 : byte_count = 12'h001;
    4'b0000 : byte_count = 12'h001;
  endcase
end

/*
* Calculate lower address based on  byte enable
*/
always @(fdw or req_addr) begin
  casex (fdw[3:0])
    4'b0000 : lower_addr = {req_addr[6:2], 2'b00};
    4'bxxx1 : lower_addr = {req_addr[6:2], 2'b00};
    4'bxx10 : lower_addr = {req_addr[6:2], 2'b01};
    4'bx100 : lower_addr = {req_addr[6:2], 2'b10};
    4'b1000 : lower_addr = {req_addr[6:2], 2'b11};
  endcase
end

task init;
begin
  state <= `HM_MR_STATE_IDLE;
  pci_r_id <= 0;
  dw_sent <= 0;
  trn_rdst_rdy_n <= 1'b0;
  trn_td <= 64'b0;
  trn_tsof_n <= 1'b1;
  trn_trem_n <= 1'b1;
  trn_teof_n <= 1'b1;
  trn_tsrc_rdy_n <= 1'b1;
  stat_trn_cpt_tx <= 16'b0;
  req_addr <= 0;
  ldw <= 0;
  fdw <= 0;
  length <= 0;
  tag <= 0;
  tc <= 0;
  td <= 0;
  ep <= 0;
  attr <= 0;
end
endtask

initial begin
  init();
end

always @(posedge trn_clk) begin
  if (sys_rst || trn_lnk_up_n) begin
    init();
  end else begin
    if (state == `HM_MR_STATE_IDLE) begin
      // Memory read bar hit !
      if (!trn_rsrc_rdy_n && is_memory_read_request && !trn_rsof_n &&
          trn_rbar_hit_n != 7'b1111111) begin
        state <= `HM_MR_STATE_READ_ADDRESS;
        pci_r_id <= trn_rd[31:16];
        fdw <= trn_rd[3:0];
        ldw <= trn_rd[7:4];
        length <= trn_rd[41:32];
        tag <= trn_rd[15:08];
        tc <= trn_rd[54:52];  
        td <= trn_rd[47];
        ep <= trn_rd[46]; 
        attr <= trn_rd[45:44];
      end
    end else if (state == `HM_MR_STATE_READ_ADDRESS) begin
      if (!trn_rsrc_rdy_n && !trn_reof_n) begin
        req_addr <= {trn_rd[63:34], 2'b00};
        state <= `HM_MR_STATE_SEND;
        trn_rdst_rdy_n <= 1'b1; // Stop reading
      end
    end else if (state == `HM_MR_STATE_SEND) begin
      // End of transmission go to idle
      if (dw_sent == 2'b10) begin
        state <= `HM_MR_STATE_IDLE;
        dw_sent <= 2'b0;
        trn_teof_n <= 1'b1;
        trn_tsrc_rdy_n <= 1'b1; // Stop sending
        trn_rdst_rdy_n <= 1'b0; // Reading again
        trn_trem_n <= 1'b1;
        stat_trn_cpt_tx <= stat_trn_cpt_tx + 1'b1;
      end else begin
        if (!trn_tdst_rdy_n) begin
          // First quad word
          if (dw_sent == 2'b00) begin
            trn_tsrc_rdy_n <= 1'b0; // Sending
            trn_td <= completion[0];
            trn_tsof_n <= 1'b0;
            dw_sent <= 2'b01;
          // Second quad word
          end else if (dw_sent == 2'b01) begin
            trn_tsrc_rdy_n <= 1'b0; // Sending
            trn_td <= completion[1];
            trn_tsof_n <= 1'b1;
            trn_teof_n <= 1'b0;
            dw_sent <= 2'b10;
            trn_trem_n <= 1'b0;
          end
        end
      end
    end else begin
      init();
    end
  end
end

endmodule
