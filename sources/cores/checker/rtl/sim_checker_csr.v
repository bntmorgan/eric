`include "checker.vh"
`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;

reg [13:0] csr_a;
reg csr_we;
reg [31:0] csr_di;

// Ouputs
wire [31:0] csr_do;
wire irq;

`SIM_SYS_CLK

`SIM_REPORT_CSR

/**
 * Tested components
 */
checker_top ck(
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

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
initial
begin
  // CSR WRITE IRQ
  # 2 $display("---- CTRL = IRQ_EN");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b1;
  csr_di = `CHECKER_CTRL_IRQ_EN;

  // CSR READ IRQ
  # 2 $display("---- read CTRL");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 0;
  csr_di = 1'b0;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0x10");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b1;
  csr_di = 32'h00000010;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- read low");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b0;
  csr_di = 32'h0;

  // Holds the cvalues
  # 10

  // CSR WRITE CTRL START
  # 2 $display("---- ctrl = dummymode + start");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b1;
  csr_di = {28'h0, 1'b1, `CHECKER_MODE_DUMMY, 1'b1};

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b0;
  csr_di = 32'b0;

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
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b1;
  csr_di = `CHECKER_CTRL_IRQ_EN;

  // CSR READ IRQ
  # 2 $display("---- read CTRL");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 0;
  csr_di = 1'b0;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0x10");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b1;
  csr_di = 32'h00000010;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- read low");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b0;
  csr_di = 32'h0;

  // Holds the cvalues
  # 10

  // CSR WRITE CTRL START
  # 2 $display("---- ctrl = dummymode + start");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b1;
  csr_di = {28'h0, 1'b1, `CHECKER_MODE_DUMMY, 1'b1};

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b0;
  csr_di = 32'b0;

  // Holds the cvalues
  # 40


  # 4 $finish;
end

endmodule
