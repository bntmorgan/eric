`timescale 1ns/100ps

module main #(
	parameter adr_width = 28
) ();

// Ip core parameters
localparam DQ_WIDTH = 64;
localparam ADDR_WIDTH = 27;
localparam ECC_TEST = "OFF";
localparam DATA_WIDTH = 64;
localparam PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;


`include "sim.v"
`include "sim_fml.v"
`include "sim_ddr3.v"

/**
 * Tested component
 */
fml_ddr3_ctlif #(
  .adr_width(adr_width)
) ddr3 (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .ui_clk(ui_clk),
  .ui_rst(ui_rst),

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
  .app_addr(app_addr),
  .app_cmd(app_cmd),
  .app_en(app_en),
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
