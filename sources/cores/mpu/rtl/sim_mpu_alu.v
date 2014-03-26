module main();

/**
 * Top module signals
 */

// Inputs
reg [1:0] size;
reg [3:0] op;
reg [63:0] a;
reg [63:0] b;
reg [63:0] m0;
reg [63:0] m1;

// Outputs
wire [63:0] res;
wire [7:0] flags;

/**
 * Tested components
 */
mpu_alu alu (
  .size(size),
  .op(op),
  .a(a),
  .b(b),
  .m0(m0),
  .m1(m1),

  .res(res),
  .flags(flags)
);

initial begin
  size <= 2'b0;
  op <= 4'b0;
  a <= 64'b0;
  b <= 64'b0;
  m0 <= 64'b0;
  m1 <= 64'b0;
end

always @(*)
begin
  $display("-");
  $display("size %x", size);
  $display("op %x", op);
  $display("a %x", a);
  $display("b %x", b);
  $display("m0 %x", m0);
  $display("m1 %x", m1);
  $display("res %x", res);
  $display("flags %x", flags);
end

/**
 * Simulation
 */
initial
begin

  # 2 $display("--- 8-bit");
  # 2 $display("--- mask[01] a (ok)");
  op <= 8'h1;
  a[7:0] <=  8'b01010101;
  m0[7:0] <= 8'b10101010;
  m1[7:0] <= 8'b01010101;

  # 2 $display("--- mask[01] a (bad m1)");
  op <= 8'h1;
  a[7:0] <=  8'b01010101;
  m0[7:0] <= 8'b10101010;
  m1[7:0] <= 8'b00010101;

  # 2 $display("--- mask[01] a (bad m0)");
  op <= 8'h1;
  a[7:0] <=  8'b01010101;
  m0[7:0] <= 8'b00101010;
  m1[7:0] <= 8'b01010101;

  # 2 $display("--- cmp a b m0 = 1 (ok)");
  op <= 8'h2;
  a[7:0] <=  8'b01010101;
  b[7:0] <=  8'b01010101;
  m0[7:0] <= 8'b11111111;

  # 2 $display("--- cmp a b m0 = 1 (ko)");
  op <= 8'h2;
  a[7:0] <=  8'b01010101;
  b[7:0] <=  8'b01010100;
  m0[7:0] <= 8'b11111111;

  # 2 $display("--- cmp a b m0 = 1 (ok)");
  op <= 8'h2;
  a[7:0] <=  8'b01010101;
  b[7:0] <=  8'b01010100;
  m0[7:0] <= 8'b11111110;

  # 2 $display("--- a < b (ok)");
  op <= 8'h3;
  a[7:0] <=  8'b01010100;
  b[7:0] <=  8'b01010101;

  # 2 $display("--- a < b (ko)");
  op <= 8'h3;
  a[7:0] <=  8'b01010101;
  b[7:0] <=  8'b01010101;

  # 2 $finish;
end

endmodule
