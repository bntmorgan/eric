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

  // Selectors
  // If 8 bit size can be bit 0 to 7 of the 64 bit qword
  input [2:0] s0,
  input [2:0] s1,
  input [2:0] s2,

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
 * Selector processing
 */

// Compute the size of the fields in bit
wire [5:0] bsize = ((1 << size) << 3);

// Right shifts function of the size a the sel
// rsX = (sel * 8) * bsize
wire [5:0] rs0 = (s0 * bsize); 
wire [5:0] rs1 = (s1 * bsize); 
wire [5:0] rs2 = (s2 * bsize); 

// Compute a mask for the high bits
wire [63:0] hm = ~(64'hffffffffffffffff << bsize);

// We do the right shift so every b, w, dw and qw are in the LSBs don't forget
// to mask the high bits
wire [63:0] _o0 = (o0 >> rs0) & hm;
wire [63:0] _o1 = (o1 >> rs1) & hm;
wire [63:0] _o2 = (o2 >> rs2) & hm;

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
