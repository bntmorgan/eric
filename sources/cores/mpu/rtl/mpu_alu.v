module mpu_alu (
  // Operation size
  input [1:0] size,

  // Operation code
  // 0 : none
  // 1 : mask[01] a 
  // 2 : a == b
  // 3 : a < b
  input [3:0] op,

  // Operands
  input [63:0] a,
  input [63:0] b,

  // Operand Mask 0 and 1
  input [63:0] m0,
  input [63:0] m1,

  // Results
  // We use 64 bit res but only the lsb will be used (booleans)
  output [63:0] res,
  output [7:0] flags
);

wire op_mask;
wire op_cmp;
wire op_lt;

assign flags = 8'b0;

assign res = 
  (op == 8'h1) ? {63'b0, op_mask} :
  (op == 8'h2) ? {63'b0, op_cmp} :
  (op == 8'h3) ? {63'b0, op_lt} :
  64'b0;

/**
 * mask[01] a ?
 * Checks the 0 allowed and 1 allowed masks on operand a
 * false if it ok
 * 
 * m0 : 1 if 0 is allowed
 * m1 : 1 if 1 is allowed
 *
 * x m0  (x nor m0)   x m1 (x and not(m1))
 * 0 0   1            0 0  0  
 * 0 1   0            0 1  0
 * 1 0   0            1 0  1
 * 1 1   0            1 1  0
 */
assign op_mask = 
  (size == 2'b00) ? (~(a[7:0] | m0[7:0]) | (a[7:0] & ~(m1[7:0]))) == 8'b0 :
  (size == 2'b01) ? (~(a[15:0] | m0[15:0]) | (a[15:0] & ~(m1[15:0]))) == 16'b0 :
  (size == 2'b10) ? (~(a[31:0] | m0[31:0]) | (a[31:0] & ~(m1[31:0]))) == 32'b0 :
  (size == 2'b11) ? (~(a[63:0] | m0[63:0]) | (a[63:0] & ~(m1[63:0]))) == 64'b0 :
  1'b0;

/** 
 * a & not(m0) == b & not(m0)
 * 
 * Checks the equality of chosen bit between in operand a and b
 * m0 has asserts all the bits to check
 */
assign op_cmp = 
  (size == 2'b00) ? (a[7:0] & m0[7:0]) == (b[7:0] & m0[7:0]) :
  (size == 2'b01) ? (a[15:0] & m0[15:0]) == (b[15:0] & m0[15:0]) :
  (size == 2'b10) ? (a[31:0] & m0[31:0]) == (b[31:0] & m0[31:0]) :
  (size == 2'b11) ? (a[63:0] & m0[63:0]) == (b[63:0] & m0[63:0]) :
  1'b0;

assign op_lt = 
  (size == 2'b00) ? a[7:0] < b[7:0] :
  (size == 2'b01) ? a[15:0] < b[15:0] :
  (size == 2'b10) ? a[31:0] < b[31:0] :
  (size == 2'b11) ? a[63:0] < b[63:0] :
  1'b0;

endmodule
