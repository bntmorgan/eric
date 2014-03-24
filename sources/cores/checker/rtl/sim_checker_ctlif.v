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

reg cend;
reg [7:0] cctrl;


// Ouputs
wire [31:0] csr_do;
wire irq;

wire [1:0] cmode;
wire cstart;
wire [63:0] caddr;

`SIM_SYS_CLK

`SIM_REPORT_CSR

/**
 * Tested components
 */
checker_ctlif ctlif(
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

  .csr_a(csr_a),
  .csr_we(csr_we),
  .csr_di(csr_di),
  .csr_do(csr_do),
  .irq(irq),

  .cmode(cmode),
  .cstart(cstart),
  .caddr(caddr),
  .cend(cend),
  .cctrl(cctrl)
);

always @(*)
begin
  $display("-");
  $display("cmode %d", cmode);
  $display("cstart %b", cstart);
  $display("caddr 0x%x", caddr);
  $display("cend 0x%x", cend);
  $display("cctrl 0x%x", cctrl);
end

always @(*)
begin
  $display("-");
  $display("irq %d", irq);
end

initial begin
  cend <= 1'b0;
  cctrl <= 8'b0;
end

/**
 * Simulation
 */
initial
begin
  // CSR WRITE ADDRES LOW
  # 2 $display("---- low = 0xaaaaaaaa");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b1;
  csr_di = 32'haaaaaaaa;

  // CSR READ ADDRES LOW
  # 2 $display("---- read low");
  csr_a = `CHECKER_CSR_ADDRESS_LOW; 
  csr_we = 1'b0;
  csr_di = 32'h0;

  // CSR WRITE ADDRES HIGH
  # 2 $display("---- high = 0xbbbbbbbb");
  csr_a = `CHECKER_CSR_ADDRESS_HIGH; 
  csr_we = 1'b1;
  csr_di = 32'hbbbbbbbb;

  // CSR READ ADDRES HIGH
  # 2 $display("---- read high");
  csr_a = `CHECKER_CSR_ADDRESS_HIGH; 
  csr_we = 1'b0;
  csr_di = 32'h0;

  /* CHECKER CYCLE START END */

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
  # 10 

  // CHECKER END
  $display("---- Checker end");
  cend = 1'b1;
  # 2
  cend = 1'b0;

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

  // Hold the values
  # 10

  // USER END
  # 2 $display("---- ctrl = dummymode + ~start");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b1;
  csr_di = {28'h0, 1'b0, `CHECKER_MODE_DUMMY, 1'b1};

  // Hold the values
  # 10

  // CSR READ CTRL
  # 2 $display("---- read ctrl");
  csr_a = `CHECKER_CSR_CTRL; 
  csr_we = 1'b0;
  csr_di = 32'b0;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- rst");
  sys_rst = 1'b1;

  // CSR WRITE ADDRES LOW
  # 2 $display("---- read low");
  sys_rst = 1'b0;

  # 4 $finish;
end

endmodule
