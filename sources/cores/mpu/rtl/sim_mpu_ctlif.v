`timescale 1ns/10ps
`include "mpu.vh"

module main ();

`include "sim.v"
`include "sim_csr.v"
`include "sim_mpu.v"

// Inputs

// Outputs
wire irq;

/**
 * Tested component
 */
mpu_ctlif ctlif (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .mpu_clk(mpu_clk),
  .mpu_en(mpu_en),
  .mpu_rst(mpu_rst),
  .user_irq(user_irq),
  .user_data(user_data),
  .error(error),
  .irq(irq)
);

initial begin
  waitnclock(10);

  // Activate IRQs and read it
  csrwrite(`MPU_CSR_CTRL, 32'b1); 
  csrread(14'h0); 

  // Run MPU
  csrwrite(`MPU_CSR_CTRL, 32'b11);

  // Error accurs
  error <= 1'b1;
  waitnclock(10);
  error <= 1'b0;

  // Commit event
  csrwrite(`MPU_CSR_STAT, 32'hffffffff);

  // Run MPU
  csrwrite(`MPU_CSR_CTRL, 32'b11);

  // User irq
  waitnclock(10);
  user_irq <= 1'b1;
  user_data <= {64{1'b1}};
  waitnclock(10);
  user_irq <= 1'b0;
  user_data <= {64{1'b0}};

  // Commit event
  csrwrite(`MPU_CSR_STAT, 32'hffffffff);

  // User irq end
  waitnclock(10);
  user_irq <= 1'b1;
  user_data <= {64{1'b0}};
  waitnclock(10);
  user_irq <= 1'b0;
  user_data <= {64{1'b0}};

  // Commit event
  csrwrite(`MPU_CSR_STAT, 32'hffffffff);

  waitnclock(40);
  $finish;
end

endmodule
