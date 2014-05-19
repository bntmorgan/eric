`include "checker.vh"
`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs

// Ouputs
wire irq;

`include "sim_wb.v"
`include "sim_csr.v"
`include "sim.v"

`SIM_REPORT_CSR

/**
 * Tested components
 */
checker_top ck (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_we_i(wb_we_i),
  .wb_dat_o(wb_dat_o),
  .wb_ack_o(wb_ack_o),

  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .irq(irq)
);

always @(posedge irq) begin
  $display("-"); 
  $display("irq %d !!! Job is done", irq); 
end

/**
 * Simulation
 */
integer i;
initial
begin
  for (i = 0; i < 8; i = i + 1)
  begin
    $dumpvars(0,ck.mem.gen_ram[0].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[1].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[2].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[3].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[4].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[5].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[6].ram.mem[i]);
    $dumpvars(0,ck.mem.gen_ram[7].ram.mem[i]);
  end
  // CSR WRITE IRQ
  # 2 $display("---- CTRL = IRQ_EN");
  csrwrite(`CHECKER_CSR_CTRL, `CHECKER_CTRL_IRQ_EN);

  // CSR READ IRQ
  # 2 $display("---- read CTRL");
  csrread(`CHECKER_CSR_CTRL);

  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0x10");
  csrwrite(`CHECKER_CSR_ADDRESS_LOW, 32'h00000010);

  // CSR WRITE ADDRES LOW
  # 2 $display("---- read low");
  csrread(`CHECKER_CSR_ADDRESS_LOW);

  // Holds the cvalues
  # 10

  // CSR WRITE CTRL START
  # 2 $display("---- ctrl = dummymode + start");
  csrwrite(`CHECKER_CSR_CTRL, {28'h0, 1'b1, `CHECKER_MODE_DUMMY, 1'b1});

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csrread(`CHECKER_CSR_CTRL);

  // Holds the cvalues
  # 40

  // SYS RESET
  # 2 $display("---- rst");
  sys_rst = 1'b1;

  // END RESET
  # 2 $display("---- read low");
  sys_rst = 1'b0;

  // CSR WRITE IRQ
  # 2 $display("---- CTRL = IRQ_EN");
  csrwrite(`CHECKER_CSR_CTRL, `CHECKER_CTRL_IRQ_EN);

  // CSR READ IRQ
  # 2 $display("---- read CTRL");
  csrread(`CHECKER_CSR_CTRL);

  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0x10");
  csrwrite(`CHECKER_CSR_ADDRESS_LOW, 32'h00000010);

  // CSR WRITE ADDRES LOW
  # 2 $display("---- read low");
  csrread(`CHECKER_CSR_ADDRESS_LOW);

  // Holds the cvalues
  # 10

  // CSR WRITE CTRL START
  # 2 $display("---- ctrl = dummymode + start");
  csrwrite(`CHECKER_CSR_CTRL, {28'h0, 1'b1, `CHECKER_MODE_DUMMY, 1'b1});

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csrread(`CHECKER_CSR_CTRL);

  // Holds the cvalues
  # 40

  // Prepare the mpu

  // Write the program
  wbwrite(32'h00000000, 32'he2097856);
  wbwrite(32'h00000004, 32'h3412e208);
  wbwrite(32'h00000008, 32'h21436587);
  wbwrite(32'h0000000c, 32'he2100100);
  wbwrite(32'h00000010, 32'h0000e211);
  wbwrite(32'h00000014, 32'h00000000);
  wbwrite(32'h00000018, 32'hd30810c3);
  wbwrite(32'h0000001c, 32'h08c30000);

  wbread(32'h00000000);
  wbread(32'h00000004);
  wbread(32'h00000008);
  wbread(32'h0000000c);

  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0x10");
  csrwrite(`CHECKER_CSR_ADDRESS_LOW, 32'h00001000);

  // CSR WRITE CTRL START
  # 2 $display("---- ctrl = signlemode + start");
  csrwrite(`CHECKER_CSR_CTRL, {28'h0, 1'b1, `CHECKER_MODE_SINGLE, 1'b1});

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csrread(`CHECKER_CSR_CTRL);

  // Holds the cvalues
  # 400

  // csrwrite(`CHECKER_CSR_STAT, {29'h0, 3'b111});

  // Holds the cvalues
  # 2 $display("---- ctrl = signlemode + start");
  csrwrite(`CHECKER_CSR_CTRL, {28'h0, 1'b1, `CHECKER_MODE_SINGLE, 1'b1});

  # 400

  # 4 $finish;
end

endmodule
