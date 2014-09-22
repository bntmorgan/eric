`include "mpu.vh"

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
  input [63:0] o3,

  // Operands
  input [2:0] s0,
  input [2:0] s1,
  input [2:0] s2,
  input [2:0] s3,
  input [2:0] sres,

  // Results
  // We use 64 bit res but only the lsb will be used (booleans)
  output [63:0] res,
  output [7:0] flags
);

wire op_mask;
wire op_cmp;
wire op_lt;
wire [63:0] op_add;
wire [63:0] x;
wire [63:0] op_hamm;
wire [5:0] rs0;
wire [5:0] rs1;
wire [5:0] rs2;
wire [5:0] rs3;
wire [5:0] lsres;
wire [5:0] bsize;
wire [63:0] hm;
wire [63:0] _o0;
wire [63:0] _o1;
wire [63:0] _o2;
wire [63:0] _o3;

// Compute the size of the fields in bit
assign bsize[5:0] = ((1 << size) << 3);

// Right shifts function of the size a the sel
// rsX = sel * bsize
assign rs0[5:0] = (s0 * bsize); 
assign rs1[5:0] = (s1 * bsize); 
assign rs2[5:0] = (s2 * bsize); 
assign rs3[5:0] = (s3 * bsize); 
assign lsres[5:0] = (sres * bsize); 

// Compute a mask for the high bits
assign hm[63:0] = ~(64'hffffffffffffffff << bsize);

// We do the right shift so every b, w, dw and qw are in the LSBs don't forget
// to mask the high bits
assign _o0[63:0] = (o0 >> rs0) & hm;
assign _o1[63:0] = (o1 >> rs1) & hm;
assign _o2[63:0] = (o2 >> rs2) & hm;
assign _o3[63:0] = (o3 >> rs3) & hm;

assign flags = 8'b0;

assign res = 
  (op == `MPU_OP_MASK) ? op_mask << lsres :
  (op == `MPU_OP_CMP) ? op_cmp << lsres :
  (op == `MPU_OP_LT) ? op_lt << lsres :
  (op == `MPU_OP_ADD) ? op_add << lsres :
  (op == `MPU_OP_HAMM) ? op_hamm << lsres :
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

assign op_add = _o1 + _o2;

assign x = (_o1 & _o3) ^ (_o2 & _o3);

assign op_hamm = x[00]
  + x[01] + x[02] + x[03] + x[04] + x[05] + x[06] + x[07] + x[08] + x[09]
  + x[10] + x[11] + x[12] + x[13] + x[14] + x[15] + x[16] + x[17] + x[18]
  + x[19] + x[20] + x[21] + x[22] + x[23] + x[24] + x[25] + x[26] + x[27]
  + x[28] + x[29] + x[30] + x[31] + x[32] + x[33] + x[34] + x[35] + x[36]
  + x[37] + x[38] + x[39] + x[40] + x[41] + x[42] + x[43] + x[44] + x[45]
  + x[46] + x[47] + x[48] + x[49] + x[50] + x[51] + x[52] + x[53] + x[54]
  + x[55] + x[56] + x[57] + x[58] + x[59] + x[60] + x[61] + x[62] + x[63] ;

endmodule
