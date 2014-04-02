`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;
reg [4:0] r_idx0;
reg [4:0] r_idx1;
reg [4:0] r_idx2;
reg [4:0] r_idx3;
reg [4:0] w_idx;
reg [63:0] w_data;
reg [1:0] w_size;
reg [2:0] w_sel;
reg [2:0] w_r_sel;
reg we;

wire [63:0] r_data0;
wire [63:0] r_data1;
wire [63:0] r_data2;
wire [63:0] r_data3;

`SIM_SYS_CLK

/**
 * Tested components
 */
mpu_registers regs (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .r_idx0(r_idx0),
  .r_idx1(r_idx1),
  .r_idx2(r_idx2),
  .r_idx3(r_idx3),
  .r_data0(r_data0),
  .r_data1(r_data1),
  .r_data2(r_data2),
  .r_data3(r_data3),
  .w_idx(w_idx),
  .w_data(w_data),
  .w_sel(w_sel),
  .w_r_sel(w_r_sel),
  .w_size(w_size),
  .we(we)
);

always @(*)
begin
  $display("-");
  $display("r_idx0 %x", r_idx0);
  $display("r_idx1 %x", r_idx1);
  $display("r_idx2 %x", r_idx2);
  $display("r_idx2 %x", r_idx3);
  $display("r_data0 %x", r_data0);
  $display("r_data1 %x", r_data1);
  $display("r_data2 %x", r_data2);
  $display("r_data3 %x", r_data3);
  $display("we %x", we);
  $display("w_data %x", w_data);
  $display("w_idx %x", w_idx);
  $display("w_sel %x", w_sel);
  $display("w_r_sel %x", w_r_sel);
end

initial begin
  r_idx0 <= 5'b00000;
  r_idx1 <= 5'b00001;
  r_idx2 <= 5'b00010;
  r_idx3 <= 5'b00011;
  w_idx <= 5'b0;
  w_data <= 64'b0;
  we = 1'b0;
  w_size = 2'b00;
  w_sel = 3'b000;
  w_r_sel = 3'b000;
end

/**
 * Simulation
 */
initial
begin

  # 8 $display("--- r0 <- 0xaaaaaaaaaaaaaaaa");
  we = 1'b1;
  w_data = 64'haaaaaaaaaaaaaaaa;
  w_idx = 5'b0;
  w_sel = 3'b0;
  w_r_sel = 3'b0;

  # 8 $display("--- r0 <- 0xaaaaaaaaaaaaaaaa");
  we = 1'b1;
  w_data = 64'haaaaaaaaaaaaaaaa;
  w_idx = 5'b0;
  w_sel = 3'b110;
  w_r_sel = 3'b110;

  # 8 $display("--- r1 <- 0xaaaaaaaaaaaaaaaa");
  we = 1'b1;
  w_data = 64'hbbbbbbbbbbbbbbbb;
  w_idx = 5'b1;
  w_sel = 3'b010;
  w_r_sel = 3'b010;
  w_size = 2'b01;

  # 8 $finish;
end

endmodule
