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

  // Operands
  input [2:0] s0,
  input [2:0] s1,
  input [2:0] s2,
  input [2:0] sres,

  // Results
  // We use 64 bit res but only the lsb will be used (booleans)
  output [63:0] res,
  output [7:0] flags
);

wire op_mask;
wire op_cmp;
wire op_lt;
wire [5:0] rs0;
wire [5:0] rs1;
wire [5:0] rs2;
wire [5:0] lsres;
wire [5:0] bsize;
wire [63:0] hm;
wire [63:0] _o0;
wire [63:0] _o1;
wire [63:0] _o2;

// Compute the size of the fields in bit
assign bsize[5:0] = ((1 << size) << 3);

// Right shifts function of the size a the sel
// rsX = sel * bsize
assign rs0[5:0] = (s0 * bsize); 
assign rs1[5:0] = (s1 * bsize); 
assign rs2[5:0] = (s2 * bsize); 
assign lsres[5:0] = (sres * bsize); 

// Compute a mask for the high bits
assign hm[63:0] = ~(64'hffffffffffffffff << bsize);

// We do the right shift so every b, w, dw and qw are in the LSBs don't forget
// to mask the high bits
assign _o0[63:0] = (o0 >> rs0) & hm;
assign _o1[63:0] = (o1 >> rs1) & hm;
assign _o2[63:0] = (o2 >> rs2) & hm;

assign flags = 8'b0;

assign res = 
  (op == 8'h1) ? op_mask << lsres :
  (op == 8'h2) ? op_cmp << lsres :
  (op == 8'h3) ? op_lt << lsres :
  64'b0;

/**
 * Mask processing
 */

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

assign op_mask = ((~(_o0) & (~(_o1) & hm)) | (_o0 & ~_o2)) == 64'b0;

/** 
 * a & not(m0) == b & not(m0)
 * 
 * Checks the equality of chosen bit between in operand a and b
 * m0 has asserts all the bits to check
 */
assign op_cmp = (_o0 & _o2) == (_o1 & _o2);

assign op_lt =  _o0 < _o1;

endmodule
