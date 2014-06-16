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
`include "sim_memory.v"
`include "sim.v"

/**
 * Tested components
 */
checker_memory m (
  .sys_clk(sys_clk),
  .mpu_clk(sys_clk),
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

task mpuread;
input [15:0] i;
begin
 mpu_addr = i;
 waitclock;
end
endtask

task mpumemread;
integer i;
begin
  for (i = 0; i < 256; i = i + 1) begin
    $display("reading m[0x%x]", i);
    mpuread(i);
  end
end
endtask

/**
 * Simulation
 */
integer i;
initial
begin
  `SIM_DUMPFILE
  for (i = 0; i < 8; i = i + 1)
  begin
    $dumpvars(0,m.gen_ram[0].ram.mem[i]);
    $dumpvars(0,m.gen_ram[1].ram.mem[i]);
    $dumpvars(0,m.gen_ram[2].ram.mem[i]);
    $dumpvars(0,m.gen_ram[3].ram.mem[i]);
    $dumpvars(0,m.gen_ram[4].ram.mem[i]);
    $dumpvars(0,m.gen_ram[5].ram.mem[i]);
    $dumpvars(0,m.gen_ram[6].ram.mem[i]);
    $dumpvars(0,m.gen_ram[7].ram.mem[i]);
  end
  $dumpvars(0,m.gen_ram[0].ram);
  $dumpvars(0,m.gen_ram[1].ram);
  $dumpvars(0,m.gen_ram[2].ram);
  $dumpvars(0,m.gen_ram[3].ram);
  $dumpvars(0,m.gen_ram[4].ram);
  $dumpvars(0,m.gen_ram[5].ram);
  $dumpvars(0,m.gen_ram[6].ram);
  $dumpvars(0,m.gen_ram[7].ram);

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

  // Test lecture / ecriture
  mpumeminittest;
	
	wb_adr_i = 32'd0;
	wb_dat_i = 32'd0;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;

  mpumemread;

  $finish;
end

endmodule
