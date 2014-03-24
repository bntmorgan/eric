`include "checker.vh"
`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;

reg [1:0] cmode;
reg cstart;
reg [63:0] caddr;

// Ouputs
wire cend;
wire [7:0] cctrl;

`SIM_SYS_CLK

/**
 * Tested components
 */
checker_dummy dummy (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),

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
  $display("cstart %d", cstart);
  $display("caddr 0x%x", caddr);
  $display("cend %d", cend);
  $display("cctrl 0x%x", cctrl);
end

initial begin
  cmode <= 2'b00;
  cstart <= 1'b0;
  caddr <= 64'h0000000000000010;
  $display("--- caddr <= 0x10");
end

/**
 * Simulation
 */
initial
begin

  // START
  # 2 $display("--- cstart = 1");
  cstart <= 1'b1;

  # 40

  // START
  # 2 $display("--- cstart = 1");
  cstart <= 1'b1;

  # 40 $finish;
end

always @(posedge cend) cstart <= 1'b0; 

endmodule
