`include "hm.vh"

/**
 * Receive response to a 3 or 4 dw Memory Read request with hm_addr address
 */

module hm_rx (
  input sys_rst,

  input rx_start,
  output reg rx_end,

  output reg [9:0] mem_l_addr,
  output reg [31:0] mem_l_data,
  output reg mem_l_we,

  output reg [9:0] mem_h_addr,
  output reg [31:0] mem_h_data,
  output reg mem_h_we,

  // Trn receive interface
  input trn_clk,
  input trn_reset_n,
  input trn_lnk_up_n,
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

  // User statistics counters ans status
  output reg [15:0] stat_trn_cpt_rx,
  output [1:0] stat_state,

  output reg timeout
);

/**
 * Core input tie-offs
 */
assign trn_rnp_ok_n = 1'b0;

reg [1:0] state;
reg [9:0] offset_l;
reg [9:0] offset_h;
reg rx_started;
reg rx_ended;
reg rx_ended_b;
// reg [31:0] timeout_cpt;
reg [15:0] timeout_cpt;
reg [11:0] byte_count; 
reg [9:0] length; 
reg [9:0] tlp_dw;

wire [1:0] fmt = trn_rd[62:61];
wire [4:0] type = trn_rd[60:56];
wire [31:0] dw_l = trn_rd[31:0];
wire [31:0] dw_h = trn_rd[63:32];

wire is_memory_completion = (fmt == 2'b10) && (type == 5'b01010);

assign stat_state = state;

task write_mem_l;
  input [32:0] data;
begin
  mem_l_data <= data;
  mem_l_addr <= offset_l;
  mem_l_we <= 1'b1;
  offset_l <= offset_l + 1'b1;
end
endtask

task write_mem_h;
  input [32:0] data;
begin
  mem_h_data <= data;
  mem_h_addr <= offset_h;
  mem_h_we <= 1'b1;
  offset_h <= offset_h + 1'b1;
end
endtask

task no_write_mem_l;
begin
  mem_l_we <= 1'b0;
end
endtask

task no_write_mem_h;
begin
  mem_h_we <= 1'b0;
end
endtask

task init_a;
begin
  trn_rdst_rdy_n <= 1'b0; // !!!! We are everytime ready, ignoring requests !!!!
  mem_l_addr <= 10'b0;
  mem_l_data <= 32'b0;
  mem_l_we <= 1'b0;
  mem_h_addr <= 10'b0;
  mem_h_data <= 32'b0;
  mem_h_we <= 1'b0;
  offset_l <= 10'b0;
  offset_h <= 10'b0;
  state <= 2'b00;
  stat_trn_cpt_rx <= 16'h0000;
  // timeout_cpt <= 32'h00000000;
  timeout_cpt <= 16'h0000;
  rx_ended <= 1'b0;
  timeout <= 1'b0;
  byte_count <= 12'b0;
  length <= 10'b0;
  tlp_dw <= 10'b0;
end
endtask

task init_b;
begin
  rx_end <= 1'b0;
  rx_started <= 1'b0;
  rx_ended_b <= 1'b0;
end
endtask


initial begin
  init_a();
  init_b();
end

// Bufferise the end, even if memory read is completed before the start
always @(posedge trn_clk) begin
  if (sys_rst == 1'b1 || trn_reset_n == 1'b0) begin
    init_b();
  end else begin
    rx_end <= 1'b0;
    if (rx_start == 1'b1) begin
      rx_started <= 1'b1;
    end 
    if (rx_ended == 1'b1) begin
      rx_ended_b <= 1'b1;
    end 
    if (rx_started == 1'b1 && rx_ended_b == 1'b1) begin
      rx_end <= 1'b1;
      rx_started <= 1'b0;
      rx_ended_b <= 1'b0;
    end else if (timeout == 1'b1) begin
      rx_started <= 1'b0;
      rx_ended_b <= 1'b0;
    end
  end
end

// dw_l & dw_h are reversed because of the xilinx v6 trn interface endianess
always @(posedge trn_clk) begin
  if (sys_rst == 1'b1 || trn_reset_n == 1'b0) begin
    init_a();
  end else begin
    if (state == `HM_RX_STATE_IDLE) begin
      rx_ended <= 1'b0;
      no_write_mem_l();
      no_write_mem_h();
      // Memory read completion -> RECV
      // XXX test
      // if (0) begin
      if (trn_rsrc_rdy_n == 1'b0 && trn_rsof_n == 1'b0 && is_memory_completion
         == 1'b1) begin
        state <= `HM_RX_STATE_RECV;
        // Contains the remaining bytes included the curent completion one
        byte_count <= trn_rd[11:0];
        length <= trn_rd[41:32];
        tlp_dw <= 10'b0;
      // Other request or completion -> IGN
      end else if (trn_rsrc_rdy_n == 1'b0 && trn_rsof_n == 1'b0) begin
        state <= `HM_RX_STATE_IGN;
        // XXX TODO DEBUG
        // write_mem_l(dw_h);
        // write_mem_h(dw_l);
      end
    end else if (state == `HM_RX_STATE_IGN) begin
      // XXX TODO DEBUG
      // write_mem_l(dw_h);
      // write_mem_h(dw_l);
      if (trn_rsrc_rdy_n == 1'b0 && trn_reof_n == 1'b0) begin
        // We wait again a memory read completion
        state <= `HM_RX_STATE_IDLE;
        stat_trn_cpt_rx <= stat_trn_cpt_rx + 1'b1;
      end
    end else if (state == `HM_RX_STATE_RECV) begin
      // Memory read completion is finished !!
      if (trn_rsrc_rdy_n == 1'b0 && trn_reof_n == 1'b0) begin
        state <= `HM_RX_STATE_IDLE;
        if (byte_count == length << 2) begin
          rx_ended <= 1'b1;
        end
        stat_trn_cpt_rx <= stat_trn_cpt_rx + 1'b1;
        if (offset_l ~^ offset_h) begin // a + b mod 2 == 0 ?
          if (!trn_rrem_n) begin
            write_mem_l(dw_l);
          end else begin
            no_write_mem_l();
          end
          write_mem_h(dw_h);
        end else begin
          write_mem_l(dw_h);
          if (!trn_rrem_n) begin
            write_mem_h(dw_l);
          end else begin
            no_write_mem_h();
          end
        end
      end else if (trn_rsrc_rdy_n == 1'b0) begin
        // First memory write
        if (tlp_dw == 10'b0) begin
          tlp_dw <= tlp_dw + 1'b1;
          if (offset_l ~^ offset_h) begin // a + b mod 2 == 0 ?
            write_mem_l(dw_l);
            no_write_mem_h();
          end else begin
            write_mem_h(dw_l);
            no_write_mem_l();
          end
        // Other memry writes
        end else begin
          tlp_dw <= tlp_dw + 2'b10;
          if (offset_l ~^ offset_h) begin // a + b mod 2 == 0 ?
            write_mem_l(dw_l);
            write_mem_h(dw_h);
          end else begin
            write_mem_l(dw_h);
            write_mem_h(dw_l);
          end
        end
      // No memory write
      end else begin
        no_write_mem_l();
        no_write_mem_h();
      end
    end else begin
      // Error
      state <= `HM_RX_STATE_IDLE;
    end
    // Timeout
    if (rx_started == 1'b1) begin
      timeout_cpt <= timeout_cpt + 1'b1;
      // if (timeout_cpt == 16'h000f) begin
      // if (timeout_cpt == 32'hffffffff) begin
      if (timeout_cpt == 16'hffff) begin
      // if (timeout_cpt == 16'hffff) begin
        state <= `HM_TX_STATE_IDLE;
        timeout <= 1'b1;
        timeout_cpt <= 16'h0000;
        // timeout_cpt <= 32'h00000000;
      end else begin
        timeout <= 1'b0;
      end
    end else begin
      timeout <= 1'b0;
      timeout_cpt <= 16'h0000;
      // timeout_cpt <= 32'h00000000;
    end
  end
end

endmodule