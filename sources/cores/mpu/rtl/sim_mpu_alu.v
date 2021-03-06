`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg [1:0] size;
reg [3:0] op;
reg [63:0] o0;
reg [63:0] o1;
reg [63:0] o2;
reg [2:0] s0;
reg [2:0] s1;
reg [2:0] s2;
reg [2:0] sres;

// Outputs
wire [63:0] res;
wire [7:0] flags;

/**
 * Tested components
 */
mpu_alu alu (
  .size(size),
  .op(op),
  .o0(o0),
  .o1(o1),
  .o2(o2),
  .s0(s0),
  .s1(s1),
  .s2(s2),
  .sres(sres),
  .res(res),
  .flags(flags)
);

initial begin
  size <= 2'b0;
  op <= 4'b0;
  o0 <= 64'b0;
  o1 <= 64'b0;
  o2 <= 64'b0;
  s0 <= 3'b0;
  s1 <= 3'b0;
  s2 <= 3'b0;
  sres <= 3'b1;
end

always @(*) begin
  $display("-");
  $display("op %x", op);
  $display("size %x", size);
  $display("o0  %x", o0);
  $display("o1  %x", o1);
  $display("o2  %x", o2);
  $display("res %x", res);
  $display("flags %x", flags);
end

/**
 * Simulation
 */
initial begin
  `SIM_DUMPFILE

  # 2 $display("--- 8-bit");
  # 2 $display("--- mask[01] a (ok)");
  op <= 8'h1;
  o0[07:00] <= 8'b01010101;
  o1[15:08] <= 8'b10101010;
  o2[23:16] <= 8'b01010101;
  s0 <= 3'b000;
  s1 <= 3'b001;
  s2 <= 3'b010;
  sres <= 3'b011;

  # 2 $display("--- mask[01] a (bad m1)");
  s0 <= 3'b000;
  s1 <= 3'b000;
  s2 <= 3'b000;
  sres <= 3'b000;
  op <= 8'h1;
  o0[7:0] <= 8'b01010101;
  o1[7:0] <= 8'b10101010;
  o2[7:0] <= 8'b00010101;

  # 2 $display("--- mask[01] a (bad m0)");
  op <= 8'h1;
  o0[7:0] <= 8'b01010101;
  o1[7:0] <= 8'b00101010;
  o2[7:0] <= 8'b01010101;

  # 2 $display("--- cmp a b m0 = 1 (ok)");
  op <= 8'h2;
  o0[7:0] <= 8'b01010101;
  o1[7:0] <= 8'b01010101;
  o2[7:0] <= 8'b11111111;

  # 2 $display("--- cmp a b m0 = 1 (ko)");
  op <= 8'h2;
  o0[7:0] <= 8'b01010101;
  o1[7:0] <= 8'b01010100;
  o2[7:0] <= 8'b11111111;

  # 2 $display("--- cmp a b m0 = 1 (ok)");
  op <= 8'h2;
  o0[7:0] <= 8'b01010101;
  o1[7:0] <= 8'b01010100;
  o2[7:0] <= 8'b11111110;

  # 2 $display("--- a < b (ok)");
  op <= 8'h3;
  o0[7:0] <=  8'b01010100;
  o1[7:0] <=  8'b01010101;

  # 2 $display("--- a < b (ko)");
  op <= 8'h3;
  o0[7:0] <=  8'b01010101;
  o1[7:0] <=  8'b01010101;

  # 2 $finish;
end

endmodule
