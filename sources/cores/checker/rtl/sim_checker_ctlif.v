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

reg mode_end;
reg [63:0] mode_data;
reg mode_irq;
reg mode_error;


// Ouputs
wire [31:0] csr_do;
wire irq;
wire mode_ack;

wire [1:0] mode_mode;
wire mode_start;
wire [63:0] mode_addr;

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

  .mode_mode(mode_mode),
  .mode_start(mode_start),
  .mode_addr(mode_addr),
  .mode_end(mode_end),
  .mode_data(mode_data),
  .mode_irq(mode_irq),
  .mode_ack(mode_ack),
  .mode_error(mode_error)
);

always @(*)
begin
  $display("-");
  $display("mode_mode %d", mode_mode);
  $display("mode_start %b", mode_start);
  $display("mode_addr 0x%x", mode_addr);
  $display("mode_end 0x%x", mode_end);
  $display("mode_data 0x%x", mode_data);
  $display("mode_irq 0x%x", mode_irq);
end

always @(*)
begin
  $display("-");
  $display("irq %d", irq);
end

initial begin
  mode_end <= 1'b0;
  mode_data <= 64'b0;
  mode_irq <= 1'b0;
  mode_error <= 1'b0;
end

/**
 * Simulation
 */
initial
begin
  `SIM_DUMPFILE

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
  mode_end = 1'b1;
  # 2
  mode_end = 1'b0;

  // Holds the cvalues
  # 10

  // CSR WRITE event_end
  # 2 $display("---- ctrl = dummymode + start");
  csr_a = `CHECKER_CSR_STAT; 
  csr_we = 1'b1;
  csr_di = `CHECKER_STAT_EVENT_END;
  # 2
  csr_we = 1'b0;

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
