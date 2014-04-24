`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg [15:0] mpu_addr;

// Outputs
wire [47:0] mpu_do;

`SIM_SYS_CLK

`include "sim_wb.v"

/**
 * Tested components
 */
checker_memory m (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .mpu_addr(mpu_addr),
  .mpu_do(mpu_do),
  .wb_adr_i(wb_adr_i),
  .wb_dat_i(wb_dat_i),
  .wb_sel_i(wb_sel_i),
  .wb_stb_i(wb_stb_i),
  .wb_cyc_i(wb_cyc_i),
  .wb_we_i(wb_we_i),
  .wb_dat_o(wb_dat_o),
  .wb_ack_o(wb_ack_o)
);

always @(*)
begin
  $display("-");
  $display("mpu_addr %x", mpu_addr);
  $display("mpu_do %x", mpu_do);
end

initial begin
  mpu_addr <= 16'b0;
end

/**
 * Simulation
 */
integer i;
initial
begin
  `SIM_DUMPFILE
  for (i = 0; i < 8; i = i + 1)
  begin
    $dumpvars(0,m.ram_dat_i[i]);
  end

	$display("Reset / Initialize our logic");
	sys_rst = 1'b1;
	
	wb_adr_i = 32'd0;
	wb_dat_i = 32'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;

	waitclock;
	
	sys_rst = 1'b0;
	
	waitnclock(10);

	// Writing to RX0 memory
	wbwrite(32'h00000000, 32'h01020304);
	wbwrite(32'h00000004, 32'h05060708);
  wbread(32'h00000000);
  wbread(32'h00000004);

	waitnclock(10);
  $finish;
end

endmodule
