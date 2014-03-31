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
  input [63:0] o0,
  input [63:0] o1,
  input [63:0] o2,

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
 * Mask processing
 */

// Compute the size of the fields in bit
wire [5:0] bsize = ((1 << size) << 3);

// Compute a mask for the high bits
wire [63:0] hm = ~(64'hffffffffffffffff << bsize);

/**
 * mask[01] a ?
 * Checks the 0 allowed and 1 allowed masks on operand a
 * false if it ok
 * 
 * m0 : 1 if 0 is allowed : for alu development convenience we compute not(m0)
 * m1 : 1 if 1 is allowed
 *
 * x m0  (not (x) and m1)   x m1 (x and not(m1))
 * 0 0   0                  0 0  0  
 * 0 1   1                  0 1  0
 * 1 0   0                  1 0  1
 * 1 1   0                  1 1  0
 */

assign op_mask = ((~(o0) & (~(o1) & hm)) | (o0 & ~o2)) == 64'b0;

/** 
 * a & not(m0) == b & not(m0)
 * 
 * Checks the equality of chosen bit between in operand a and b
 * m0 has asserts all the bits to check
 */
assign op_cmp = (o0 & o2) == (o1 & o2);

assign op_lt =  o0 < o1;

endmodule
