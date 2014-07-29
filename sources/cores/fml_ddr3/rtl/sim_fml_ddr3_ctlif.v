`timescale 1ns/100ps

module main #(
	parameter adr_width = 30
) ();

`include "sim.v"
`include "sim_fml.v"
`include "sim_ddr.v"

// Ip core parameters
localparam DQ_WIDTH = 64;
localparam ADDR_WIDTH = 27;
localparam ECC_TEST = "OFF";
localparam DATA_WIDTH = 64;
localparam PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;
localparam APP_DATA_WIDTH = PAYLOAD_WIDTH * 4;
localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

// Inputs
reg app_rdy;
reg [APP_DATA_WIDTH-1:0] app_rd_data;
reg app_rd_data_end;
reg app_rd_data_valid;
reg app_wdf_rdy;
reg phy_init_done;

// Outputs
wire [ADDR_WIDTH-1:0] app_addr;
wire [2:0] app_cmd;
wire app_en;
wire app_hi_pri;
wire app_sz;
wire [APP_DATA_WIDTH-1:0] app_wdf_data;
wire app_wdf_end;
wire [APP_MASK_WIDTH-1:0] app_wdf_mask;
wire app_wdf_wren;

// XXX test ties-off
initial begin
  app_rdy <= 1;
  app_rd_data <= {
    64'haaaaaaaaaaaaaaaa,
    64'hbbbbbbbbbbbbbbbb,
    64'hcccccccccccccccc,
    64'hdddddddddddddddd
  };
  app_rd_data_end <= 1;
  app_rd_data_valid <= 1;
  app_wdf_rdy <= 1;
  phy_init_done <= 1;
end


/**
 * Tested component
 */
fml_ddr3_ctlif ddr3 (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .ddr_clk(ddr_clk),
  .ddr_rst(ddr_rst),

  .fml_adr(fml_adr),
  .fml_stb(fml_stb),
  .fml_we(fml_we),
  .fml_ack(fml_ack),
  .fml_sel(fml_sel),
  .fml_di(fml_di),
  .fml_do(fml_do),

  .app_rdy(app_rdy),
  .app_rd_data(app_rd_data),
  .app_rd_data_end(app_rd_data_end),
  .app_rd_data_valid(app_rd_data_valid),
  .app_wdf_rdy(app_wdf_rdy),
  .phy_init_done(phy_init_done),
  .app_addr(app_addr),
  .app_cmd(app_cmd),
  .app_en(app_en),
  .app_hi_pri(app_hi_pri),
  .app_sz(app_sz),
  .app_wdf_data(app_wdf_data),
  .app_wdf_end(app_wdf_end),
  .app_wdf_mask(app_wdf_mask),
  .app_wdf_wren(app_wdf_wren)
);

/**
 * Dumpfile configuration
 */
integer idx;
initial begin
  // Dump registers
  for (idx = 0; idx < 4; idx = idx + 1) begin
    $dumpvars(0,ddr3.read_buf[idx]);
    $dumpvars(0,ddr3.write_buf[idx]);
  end
end

initial begin
  waitnclock(20);

  fml_single_read;

  waitnclock(20);

  fml_single_write;

  waitnclock(40);
  $finish();
end

endmodule
