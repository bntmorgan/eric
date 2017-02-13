`include "hm.vh"

/**
 * Receive response to a 3 or 4 dw Memory Read request with hm_addr address
 */

module hm_rx (
  input sys_rst,

  output reg rx_memory_read,

  output reg [9:0] mem_l_addr,
  output reg [31:0] mem_l_data_o,
  output reg mem_l_we,

  output reg [9:0] mem_h_addr,
  output reg [31:0] mem_h_data_o,
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
  input trn_rsrc_dsc_n,
  input trn_rerrfwd_n,
  input [6:0] trn_rbar_hit_n,

  // Debug signals
  input sys_dgb_mode,

  // User statistics counters ans status
  output reg [31:0] tlp_dw_g,
  output reg [31:0] stat_trn_cpt_rx,
  output [2:0] stat_state
);

/**
 * Core input tie-offs
 */

reg [2:0] state;
reg [9:0] offset_l;
reg [9:0] offset_h;
reg [11:0] byte_count;
reg [9:0] length;
reg [9:0] tlp_dw;

wire [1:0] fmt = trn_rd[62:61];
wire [4:0] type = trn_rd[60:56];
wire [31:0] dw_l = trn_rd[31:0];
wire [31:0] dw_h = trn_rd[63:32];

wire is_memory_completion = (fmt == 2'b10) && (type == 5'b01010);

assign stat_state = state;

task write_init_l;
begin
  mem_l_addr <= 10'b0;
  mem_l_data_o <= 32'b0;
  mem_l_we <= 1'b0;
  offset_l <= 10'b0;
end
endtask

task write_init_h;
begin
  mem_h_addr <= 10'b0;
  mem_h_data_o <= 32'b0;
  mem_h_we <= 1'b0;
  offset_h <= 10'b0;
end
endtask

task write_mem_l;
  input [31:0] data;
begin
  mem_l_data_o <= {
    data[7:0],
    data[15:8],
    data[23:16],
    data[31:24]
  };
  mem_l_addr <= offset_l;
  mem_l_we <= 1'b1;
  offset_l <= offset_l + 1'b1;
end
endtask

task write_mem_h;
  input [31:0] data;
begin
  mem_h_data_o <= {
    data[7:0],
    data[15:8],
    data[23:16],
    data[31:24]
  };
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

task init;
begin
  state <= `HM_RX_STATE_IDLE;
  byte_count <= 12'b0;
  length <= 10'b0;
  tlp_dw <= 10'b0;
  rx_memory_read <= 1'b0;
  write_init_l;
  write_init_h;
  tlp_dw_g <= 32'b0;
  stat_trn_cpt_rx <= 32'b0;
end
endtask

initial begin
  init();
end

// dw_l & dw_h are reversed because of the xilinx v6 trn interface endianess
always @(posedge trn_clk) begin
  if (sys_rst == 1'b1 || trn_reset_n == 1'b0) begin
    init();
  end else if (state == `HM_RX_STATE_RESET) begin
    state <= `HM_RX_STATE_IDLE;
    byte_count <= 12'b0;
    length <= 10'b0;
    tlp_dw <= 10'b0;
    rx_memory_read <= 1'b0;
    write_init_l;
    write_init_h;
  end else begin
    rx_memory_read <= 1'b0;
    if (state == `HM_RX_STATE_IDLE) begin
      no_write_mem_l();
      no_write_mem_h();
      if (sys_dgb_mode == 1'b1 && trn_rsrc_rdy_n == 1'b0 &&
          trn_rsof_n == 1'b0) begin // Debug mode !
        state <= `HM_RX_STATE_DBG;
        write_mem_l(dw_h);
        write_mem_h(dw_l);
      end else if (trn_rsrc_rdy_n == 1'b0 && trn_rsof_n == 1'b0 &&
          is_memory_completion == 1'b1) begin // Memory read completion -> RECV
        state <= `HM_RX_STATE_RECV;
        // Contains the remaining bytes included the curent completion one
        byte_count <= trn_rd[11:0];
        length <= trn_rd[41:32];
        tlp_dw <= 10'b0;
      // Other request or completion -> IGN
      end else if (trn_rsrc_rdy_n == 1'b0 && trn_rsof_n == 1'b0) begin
        state <= `HM_RX_STATE_IGN;
      end
    end else if (state == `HM_RX_STATE_DBG) begin
      // TLP is finished !!
      if (trn_rsrc_rdy_n == 1'b0 && trn_reof_n == 1'b0) begin
        state <= `HM_RX_STATE_IDLE;
        stat_trn_cpt_rx <= stat_trn_cpt_rx + 1'b1;
        write_mem_l(dw_h);
        write_mem_h(dw_l);
      end else if (trn_rsrc_rdy_n == 1'b0) begin
        write_mem_l(dw_h);
        write_mem_h(dw_l);
      // No memory write
      end else begin
        no_write_mem_l();
        no_write_mem_h();
      end
    end else if (state == `HM_RX_STATE_IGN) begin
      if (trn_rsrc_rdy_n == 1'b0 && trn_reof_n == 1'b0) begin
        // We wait again a memory read completion
        state <= `HM_RX_STATE_IDLE;
      end
    end else if (state == `HM_RX_STATE_RECV) begin
      // Memory read completion is finished !!
      if (trn_rsrc_rdy_n == 1'b0 && trn_reof_n == 1'b0) begin
        state <= `HM_RX_STATE_IDLE;
        // Is it the last memory completion TLP ?
        if (byte_count == length << 2) begin
          rx_memory_read <= 1'b1;
          write_init_l;
          write_init_h;
          state <= `HM_RX_STATE_RESET;
        end
        stat_trn_cpt_rx <= stat_trn_cpt_rx + 1'b1;
        if (offset_l ~^ offset_h) begin // a + b mod 2 == 0 ?
          if (!trn_rrem_n) begin
            write_mem_l(dw_l);
            tlp_dw_g <= tlp_dw_g + 2'b10;
          end else begin
            no_write_mem_l();
            tlp_dw_g <= tlp_dw_g + 1'b1;
          end
          write_mem_h(dw_h);
        end else begin
          write_mem_l(dw_h);
          if (!trn_rrem_n) begin
            write_mem_h(dw_l);
            tlp_dw_g <= tlp_dw_g + 2'b10;
          end else begin
            no_write_mem_h();
            tlp_dw_g <= tlp_dw_g + 1'b1;
          end
        end
      end else if (trn_rsrc_rdy_n == 1'b0) begin
        // First memory write
        if (tlp_dw == 10'b0) begin
          tlp_dw <= tlp_dw + 1'b1;
          tlp_dw_g <= tlp_dw_g + 1'b1;
          if (offset_l ~^ offset_h) begin // a + b mod 2 == 0 ?
            write_mem_l(dw_l);
            no_write_mem_h();
          end else begin
            write_mem_h(dw_l);
            no_write_mem_l();
          end
        // Other memry writes
        end else begin
          tlp_dw_g <= tlp_dw_g + 2'b10;
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
  end
end

endmodule
