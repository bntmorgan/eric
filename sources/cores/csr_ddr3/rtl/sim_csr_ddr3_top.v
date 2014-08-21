module main #(
  parameter DQ_WIDTH = 64,
  parameter ROW_WIDTH = 14,
  parameter BANK_WIDTH = 3,
  parameter CS_WIDTH = 1,
  parameter nCS_PER_RANK = 1,
  parameter CKE_WIDTH = 1,
  parameter CK_WIDTH = 1,
  parameter DM_WIDTH = 8,
  parameter DQS_WIDTH = 8,
  parameter ECC_TEST = "OFF",
  parameter DATA_WIDTH = 64,
  parameter ADDR_WIDTH = 28
) ();

`include "sim.v"
`include "sim_csr.v"

csr_ddr3_top #(
  .DQ_WIDTH(DQ_WIDTH),
  .ROW_WIDTH(ROW_WIDTH),
  .BANK_WIDTH(BANK_WIDTH),
  .CS_WIDTH(CS_WIDTH),
  .nCS_PER_RANK(nCS_PER_RANK),
  .CKE_WIDTH(CKE_WIDTH),
  .CK_WIDTH(CK_WIDTH),
  .DM_WIDTH(DM_WIDTH),
  .DQS_WIDTH(DQS_WIDTH),
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(ADDR_WIDTH)
) ddr3 (
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),

  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do)
);

integer i, idx;
initial begin
  // Dump registers
  for (idx = 0; idx < 8; idx = idx + 1) begin
    $dumpvars(0,ddr3.ctlif.read_buf[idx]);
    $dumpvars(0,ddr3.ctlif.write_buf[idx]);
  end
  
  waitnclock(10);

  // Write Address
  csrwrite(14'h002, 32'h00001000);
  waitnclock(10);

  // Read address
  csrread(14'h002);
  waitnclock(10);

  // Start read
  csrwrite(14'h000, 32'h00000002);
  waitnclock(10);

  // Read events
  csrread(14'h001);
  waitnclock(10);

  // Remove events
  csrwrite(14'h001, 32'h00000003);
  waitnclock(10);

  // Write W0-7
  csrwrite(14'h003, 32'hcacacaca);
  csrwrite(14'h004, 32'hcacacaca);
  csrwrite(14'h005, 32'hcacacaca);
  csrwrite(14'h006, 32'hcacacaca);
  csrwrite(14'h007, 32'hcacacaca);
  csrwrite(14'h008, 32'hcacacaca);
  csrwrite(14'h009, 32'hcacacaca);
  csrwrite(14'h00a, 32'hcacacaca);
  waitnclock(10);

  // Start write
  csrwrite(14'h000, 32'h00000001);
  waitnclock(60);

  $finish();
end

endmodule
