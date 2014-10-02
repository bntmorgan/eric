`include "hm.vh"

/**
 * This is a test core
 */

module hm_bar (
  input sys_rst,

  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,

  output reg [9:0] mem_l_addr,
  output [3:0] mem_l_we,
  input [31:0] mem_l_data_i,
  output [31:0] mem_l_data_o,

  output reg [9:0] mem_h_addr,
  output [3:0] mem_h_we,
  input [31:0] mem_h_data_i,
  output [31:0] mem_h_data_o,

  // Trn transmit interface
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

  // Trn receive interface
  input [63:0] trn_rd,
  input trn_rrem_n,
  input trn_rsof_n,
  input trn_reof_n,
  input trn_rsrc_rdy_n,
  input trn_rsrc_dsc_n,
  input trn_rerrfwd_n,
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
assign trn_tsrc_dsc_n = 1'b1;

reg [2:0] state;

reg start_dw;

wire [63:0] completion [2:0];

wire is_memory_read_request = trn_rd[63:56] == {3'b000, 5'b00000};
wire is_memory_write_request = trn_rd[63:56] == {3'b010, 5'b00000};
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

reg [06:0] lower_addr;
// reg [11:0] byte_count; 

reg [10:0] qw_cpt;
reg [10:0] dw_cpt;

wire [31:0] mem_l_data_i_be = {
  mem_l_data_i[7:0],
  mem_l_data_i[15:8],
  mem_l_data_i[23:16],
  mem_l_data_i[31:24]
};

wire [31:0] mem_h_data_i_be = {
  mem_h_data_i[7:0],
  mem_h_data_i[15:8],
  mem_h_data_i[23:16],
  mem_h_data_i[31:24]
};

wire [31:0] dw_l_o = (~start_dw) ? mem_l_data_i_be : mem_h_data_i_be;
wire [31:0] dw_h_o = (~start_dw) ? mem_h_data_i_be : mem_l_data_i_be;

assign mem_l_data_o = (~start_dw) ? mem_l_data_o_r : mem_h_data_o_r;
assign mem_h_data_o = (~start_dw) ? mem_h_data_o_r : mem_l_data_o_r;

assign mem_l_we = (~start_dw) ? mem_l_we_r : mem_h_we_r;
assign mem_h_we = (~start_dw) ? mem_h_we_r : mem_l_we_r;

reg [31:0] mem_l_data_o_r;
reg [31:0] mem_h_data_o_r;
reg [3:0] mem_l_we_r;
reg [3:0] mem_h_we_r;
wire [31:0] dw_l_i = trn_rd[31:0];
wire [31:0] dw_h_i = trn_rd[63:32];
wire [31:0] dw_l_i_le = {
  dw_l_i[7:0],
  dw_l_i[15:8],
  dw_l_i[23:16],
  dw_l_i[31:24]
};
wire [31:0] dw_h_i_le = {
  dw_h_i[7:0],
  dw_h_i[15:8],
  dw_h_i[23:16],
  dw_h_i[31:24]
};
wire [3:0] fdw_le = fdw;// {fdw[0], fdw[1], fdw[2], fdw[3]};
wire [3:0] ldw_le = ldw;// {ldw[0], ldw[1], ldw[2], ldw[3]};

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
  byte_count[11:0] // n bytes
};

assign completion[1][63:0] = {
  pci_r_id, // pci requester id
  tag, // No tag
  1'b0, // Reserved
  lower_addr, // LSBs of the requested address
  dw_l_o // data sent
};

assign completion[2][63:0] = {
  dw_h_o, // data sent
  dw_l_o // data sent
};

wire [2:0] nb_ldw = 
    (real_length == 11'h001)    ? 12'h000 :
    (ldw[3] & ldw[0])           ? 12'h004 :
    (~ldw[3] & ldw[2] & ldw[0]) ? 12'h004 :
    (ldw[3] & ldw[1] & ~ldw[0]) ? 12'h004 :
    (ldw == 4'b0011)            ? 12'h002 :
    (ldw == 4'b0110)            ? 12'h002 :
    (ldw == 4'b1100)            ? 12'h002 :
    (ldw == 4'b0001)            ? 12'h001 :
    (ldw == 4'b0010)            ? 12'h001 :
    (ldw == 4'b0100)            ? 12'h001 :
    (ldw == 4'b1000)            ? 12'h001 :
                                  12'h001 ;

wire [2:0] nb_fdw = 
    (fdw[3] & fdw[0])           ? 12'h004 :
    (~fdw[3] & fdw[2] & fdw[0]) ? 12'h004 :
    (fdw[3] & fdw[1] & ~fdw[0]) ? 12'h004 :
    (fdw == 4'b0011)            ? 12'h002 :
    (fdw == 4'b0110)            ? 12'h002 :
    (fdw == 4'b1100)            ? 12'h002 :
    (fdw == 4'b0001)            ? 12'h001 :
    (fdw == 4'b0010)            ? 12'h001 :
    (fdw == 4'b0100)            ? 12'h001 :
    (fdw == 4'b1000)            ? 12'h001 :
                                  12'h001 ;
  
wire [10:0] real_length = (length == 0) ? 11'h400 : length;

wire [12:0] byte_count = (((real_length - 2 >= real_length) ? 0 : real_length
  - 2) << 2) + nb_ldw + nb_fdw;

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
  dw_cpt <= 0;
  qw_cpt <= 0;
  trn_cyc_n <= 1'b1;
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
  start_dw <= 0;
end
endtask

task read_init_l;
  input [9:0] offset;
begin
  mem_l_addr <= offset;
  mem_l_we_r <= 4'b0;
  mem_l_data_o_r <= 32'b0;
end
endtask

task read_init_h;
  input [9:0] offset;
begin
  mem_h_addr <= offset;
  mem_h_we_r <= 4'b0;
  mem_h_data_o_r <= 32'b0;
end
endtask

task read_mem_l;
begin
  mem_l_addr <= mem_l_addr + 1'b1;
end
endtask

task read_mem_h;
begin
  mem_h_addr <= mem_h_addr + 1'b1;
end
endtask

task write_init_l;
  input [9:0] offset;
  input [31:0] data;
  input [3:0] sel;
begin
  mem_l_addr <= offset;
  mem_l_we_r <= sel;
  mem_l_data_o_r <= data;
end
endtask

task write_init_h;
  input [9:0] offset;
  input [31:0] data;
  input [3:0] sel;
begin
  mem_h_addr <= offset;
  mem_h_we_r <= sel;
  mem_h_data_o_r <= data;
end
endtask

task write_mem_l;
  input [31:0] data;
  input [3:0] sel;
begin
  mem_l_data_o_r <= data;
  mem_l_addr <= mem_l_addr + 1'b1;
  mem_l_we_r <= sel;
end
endtask

task write_mem_h;
  input [31:0] data;
  input [3:0] sel;
begin
  mem_h_data_o_r <= data;
  mem_h_addr <= mem_h_addr + 1'b1;
  mem_h_we_r <= sel;
end
endtask

task write_mem_l_no;
begin
  mem_l_we_r <= 4'b0;
  mem_l_data_o_r <= 32'b0;
end
endtask

task write_mem_h_no;
begin
  mem_h_we_r <= 4'b0;
  mem_h_data_o_r <= 32'b0;
end
endtask

initial begin
  init();
  read_init_l(10'b0);
  read_init_h(10'b0);
  write_init_l(10'b0, 32'b0, 4'b0);
  write_init_h(10'b0, 32'b0, 4'b0);
end

always @(posedge trn_clk) begin
  if (sys_rst || trn_lnk_up_n) begin
    init();
  end else begin
    // By default we do not write any dw
    write_mem_l_no;
    write_mem_h_no;
    if (state == `HM_MR_STATE_IDLE) begin
      // Memory read bar hit !
      if (~trn_rsrc_rdy_n & is_memory_read_request & ~trn_rsof_n
        & (~trn_rbar_hit_n[5] | ~trn_rbar_hit_n[4] | ~trn_rbar_hit_n[3]
        | ~trn_rbar_hit_n[2] | ~trn_rbar_hit_n[1] | ~trn_rbar_hit_n[0])) begin
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
      // Memory write bar hit !
      if (~trn_rsrc_rdy_n & is_memory_write_request & ~trn_rsof_n
        & (~trn_rbar_hit_n[5] | ~trn_rbar_hit_n[4] | ~trn_rbar_hit_n[3]
        | ~trn_rbar_hit_n[2] | ~trn_rbar_hit_n[1] | ~trn_rbar_hit_n[0])) begin
        state <= `HM_MR_STATE_WRITE_ADDRESS;
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
      if (~trn_rsrc_rdy_n & ~trn_reof_n) begin
        req_addr <= {trn_rd[63:34], 2'b00};
        state <= `HM_MR_STATE_SEND;
        start_dw <= trn_rd[34];
        trn_cyc_n <= 1'b0;
        read_init_l(trn_rd[43:35]);
        if (~trn_rd[34]) begin
          read_init_h(trn_rd[43:35] - 1);
        end else begin
          read_init_h(trn_rd[43:35]);
        end
      end
    end else if (state == `HM_MR_STATE_SEND) begin
      // End of transmission go to idle
      if (dw_cpt >= real_length) begin
        state <= `HM_MR_STATE_IDLE;
        qw_cpt <= 11'b0;
        dw_cpt <= 11'b0;
        trn_cyc_n <= 1'b1;
        trn_teof_n <= 1'b1;
        trn_tsrc_rdy_n <= 1'b1; // Stop sending
        trn_trem_n <= 1'b1;
        stat_trn_cpt_tx <= stat_trn_cpt_tx + 1'b1;
        trn_td <= 64'b0;
      end else begin
        if (~trn_tdst_rdy_n) begin
          read_mem_l;
          read_mem_h;
          // First quad word
          if (qw_cpt == 2'b00) begin
            trn_tsrc_rdy_n <= 1'b0; // Sending
            trn_td <= completion[0];
            trn_tsof_n <= 1'b0;
            qw_cpt <= qw_cpt + 2'b01;
          // Second quad word
          end else if (qw_cpt == 2'b01) begin
            trn_tsrc_rdy_n <= 1'b0; // Sending
            trn_td <= completion[1];
            trn_tsof_n <= 1'b1;
            qw_cpt <= qw_cpt + 2'b01;
            dw_cpt <= dw_cpt + 2'b01;
          end else begin
            trn_td <= completion[2];
            qw_cpt <= qw_cpt + 2'b01;
            dw_cpt <= dw_cpt + 2'b10;
          end
          if ((qw_cpt > 11'h001 && dw_cpt >= real_length - 2) || (qw_cpt ==
              11'h001 && dw_cpt >= real_length - 1)) begin
            trn_teof_n <= 1'b0;
            if (qw_cpt == 2'b01) begin
              trn_trem_n <= 1'b0;
            end else begin
              if (real_length % 2 == 0) begin
                trn_trem_n <= 1'b1;
              end else begin
                trn_trem_n <= 1'b0;
              end
            end
          end
        end
      end
    end else if (state == `HM_MR_STATE_WRITE_ADDRESS) begin
      if (~trn_rsrc_rdy_n & ~trn_reof_n) begin
        req_addr <= {trn_rd[63:34], 2'b00};
        start_dw <= trn_rd[34];
        write_init_l(trn_rd[43:35], dw_l_i_le, fdw_le);
        if (~trn_rd[34]) begin
          write_init_h(trn_rd[43:35] - 1, 32'b0, 4'b0);
        end else begin
          write_init_h(trn_rd[43:35], 32'b0, 4'b0);
        end
        if (~trn_reof_n) begin
          state <= `HM_MR_STATE_IDLE;
        end else begin
          state <= `HM_MR_STATE_RECV;
        end
      end
    end else if (state == `HM_MR_STATE_RECV) begin
      if (~trn_rsrc_rdy_n) begin
        // End of reception go to idle
        if (~trn_reof_n) begin
          state <= `HM_MR_STATE_IDLE;
          if (~trn_rrem_n) begin
            write_mem_h(dw_h_i_le, 4'b1111);
            write_mem_l(dw_l_i_le, ldw_le);
          end else begin
            write_mem_h(dw_h_i_le, ldw_le);
          end
        // Any case
        end else begin
          write_mem_l(dw_l_i_le, 4'b1111);
          write_mem_h(dw_h_i_le, 4'b1111);
        end
      end
    end else begin
      init();
    end
  end
end

endmodule
