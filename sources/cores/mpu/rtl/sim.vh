/**
 * Clocks
 */
`define SIM_SYS_CLK \
  always #1 sys_clk = !sys_clk; \
  initial begin \
    sys_clk = 1'b0; \
    sys_rst = 1'b0; \
  end \
  always @(posedge sys_clk) \
  begin \
    $display("-- %02d", $time); \
    $display("-"); \
  end

/**
 * CSR report
 */
`define SIM_REPORT_CSR \
  always @(posedge sys_clk) \
  begin \
    $display("csr_a 0x%x", csr_a); \
    $display("csr_we %b", csr_we); \
    $display("csr_di 0x%x", csr_di); \
    $display("csr_do 0x%x", csr_do); \
  end \
  initial begin \
    $display("CSR init"); \
    csr_di = 32'b0; \
    sys_rst = 1'b0; \
    csr_we = 1'b0; \
    csr_a = 14'b0; \
  end
