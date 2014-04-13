`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;
reg [15:0] mpu_addr;
reg [31:0] wb_adr_i;
reg [31:0] wb_dat_i;
reg [3:0] wb_sel_i;
reg wb_stb_i;
reg wb_cyc_i;
reg wb_we_i;
reg [2:0] wb_cti_i;

// Outputs
wire [47:0] mpu_do;
wire [31:0] wb_dat_o;
wire wb_ack_o;

`SIM_SYS_CLK

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
  $display("wb_adr_i %x", wb_adr_i);
  $display("wb_dat_i %x", wb_dat_i);
  $display("wb_sel_i %x", wb_sel_i);
  $display("wb_stb_i %x", wb_stb_i);
  $display("wb_cyc_i %x", wb_cyc_i);
  $display("wb_we_i %x", wb_we_i);
  $display("wb_dat_o %x", wb_dat_o);
  $display("wb_ack_o %x", wb_ack_o);
end

initial begin
  mpu_addr <= 16'b0;
  wb_adr_i <= 32'b0;
  wb_dat_i <= 32'b0;
  wb_sel_i <= 4'b0;
  wb_stb_i <= 1'b0;
  wb_cyc_i <= 1'b0;
  wb_we_i <= 1'b0;
end

/* Wishbone Helpers */
task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task waitnclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitclock;
	end
endtask

task wbwrite;
input [31:0] address;
input [31:0] data;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_dat_i = data;
	wb_sel_i = 4'hf;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b1;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	waitclock;
	$display("WB Write: %x=%x acked in %d clocks", address, data, i);
	wb_adr_i = 32'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

task wbread;
input [31:0] address;
integer i;
begin
	wb_adr_i = address;
	wb_cti_i = 3'b000;
	wb_cyc_i = 1'b1;
	wb_stb_i = 1'b1;
	wb_we_i = 1'b0;
	i = 0;
	while(~wb_ack_o) begin
		i = i+1;
		waitclock;
	end
	$display("WB Read : %x=%x acked in %d clocks", address, wb_dat_o, i);
	waitclock;
	wb_adr_i = 32'hx;
	wb_cyc_i = 1'b0;
	wb_stb_i = 1'b0;
	wb_we_i = 1'b0;
end
endtask

/**
 * Simulation
 */
initial
begin
  `SIM_DUMPFILE
  # 4
	// Writing to RX0 memory
	wbwrite(32'h00000000, 32'h01020304);
	wbwrite(32'h00000004, 32'h05060708);
  # 4 $finish;
end

endmodule
