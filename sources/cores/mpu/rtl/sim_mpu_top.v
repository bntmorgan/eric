`timescale 1ns/10ps

module main();

`include "sim.v"
`include "sim_csr.v"
`include "sim_wb.v"
`include "sim_memory.v"

/**
 * Top module signals
 */

// Inputs
wire [63:0] hm_data;

// Outputs
wire [63:0] hm_addr;
wire irq;

/**
 * Tested components
 */
mpu_top mpu (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .hm_data(hm_data),
  .hm_addr(hm_addr),
  .wb_adr_i(wb_adr_i),
  .wb_dat_o(wb_dat_o),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_ack_o(wb_ack_o),
  .wb_we_i(wb_we_i),
  .irq(irq)
);

assign hm_data = 64'h1234567812345678;

/**
 * Dumpfile configuration
 */
integer idx;
initial begin
  // Dump registers
  for (idx = 0; idx < 32; idx = idx + 1)
    $dumpvars(0,mpu.mpu.registers.regs[idx]);
end

/**
 * Simulation
 */

initial begin
  waitclock;

  // Prepare the mpu
  mpumeminit;

  wbread(32'h00000000);

  waitnclock(10);

  // Activate IRQs and read it
  csrwrite(`MPU_CSR_CTRL, 32'b1); 
  csrread(14'h0); 

  // Run MPU
  csrwrite(`MPU_CSR_CTRL, 32'b11);

  while (1) begin
    @(posedge irq) waitnclock(2);
    // Read end event
    csrread(`MPU_CSR_STAT);
    if (csr_do[0] || csr_do[1]) begin // We stop on error or end
      waitnclock(40);
      $finish;
    end
    // Commit event
    csrwrite(`MPU_CSR_STAT, 32'hffffffff);
  end
end

/**
 * Simulation
 */
integer i;
initial
begin
  for (i = 0; i < 8; i = i + 1)
  begin
    $dumpvars(0,mpu.mem.gen_ram[0].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[1].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[2].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[3].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[4].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[5].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[6].ram.mem[i]);
    $dumpvars(0,mpu.mem.gen_ram[7].ram.mem[i]);
  end
end

endmodule
