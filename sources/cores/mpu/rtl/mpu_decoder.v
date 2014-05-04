`include "mpu.vh"

module mpu_decoder (
  // Instruction to decode
  input [47:0] i,

  /**
   * Instruction decoding
   */

  // Size of the instruction in bytes
  output [15:0] isize,

  // Decoding error
  output error,

  /**
   * operators configuration
   */
  output [1:0] op_size,
  output [3:0] op_op,
  output [63:0] op_o0,
  output [63:0] op_o1,
  output [63:0] op_o2,
  output [63:0] op_o3,
  output [2:0] op_s0,
  output [2:0] op_s1,
  output [2:0] op_s2,
  output [2:0] op_s3,
  output [4:0] op_idx0,
  output [4:0] op_idx1,
  output [4:0] op_idx2,
  output [4:0] op_idx3,

  /**
   * Data registers access
   *
   * The low part of the idx in the instruction is used to select the b w dw (or
   * qw) in the qw
   */
  input [63:0] r_data0,
  input [63:0] r_data1,
  input [63:0] r_data2,
  input [63:0] r_data3
);

wire [1:0] opsize;
wire [1:0] sop;
wire [7:0] reg0;
wire [7:0] reg1;
wire [7:0] reg2;
wire [7:0] reg3;
wire error_isize;
wire [15:0] jaddr;
wire [3:0] op;
wire [31:0] _imm;
wire [63:0] imm;


/**
 * Errors handling
 */
assign error = error_isize;

/**
 * Instruction decoding
 */

// The high part of the instruction opcode byte is the opcode : 0xb0000xxxx to
// 0xb1111xxxx : the lower values are choosen according to the alu op code. The
// high value are non arithmetic stuff like jumps or data register loading
assign op[3:0] = i[7:4];

// The sub operation code : 0xbxxxx00xx to 0xbxxxx11xx
assign sop[1:0] = i[3:2];

// Size of operands : instruction opcode is 0bxxxxxx00 to 0bxxxxxx11 meaning
// 1 byte to 8 bytes operand size
assign opsize[1:0] = i[1:0];

/**
 * Instruction set
 */

// mask[01] idx & jne
// 0x1_00xx reg_val reg_m0 reg_m1 reg_@

// val & m == val & m & jne
// 0x2_00xx reg_val0 reg_val1 reg_m reg_@

// val0 < val1 & jnlt
// 0x3_00xx reg_val0 reg_val1 reg_@

// int reg
// 0xc_00xx reg

// mload reg_dest reg_addr
// 0xd_0011 reg

// load reg imm{8,16,32}
// 0xe_00xx reg imm

// jmp addr16
// 0xf_xxxx reg_@

/**
 * Merge the operators
 */
assign op_o0 = r_data0;
assign op_o1 =
  (op == `MPU_OP_LOAD) ? imm :
  r_data1;
assign op_o2 = r_data2;
assign op_o3 = r_data3;

// Register decoding
assign reg0 = i[15: 8];
assign reg1 = i[23:16];
assign reg2 = i[31:24];
assign reg3 = i[39:32];

// Instruction size decoding (in bytes)
assign isize[15:0] =
  (op == `MPU_OP_MASK) ? 16'h0005 :
  (op == `MPU_OP_CMP) ? 16'h0005 :
  (op == `MPU_OP_LT) ? 16'h0004 :
  (op == `MPU_OP_ADD) ? 16'h0004 :
  (op == `MPU_OP_INT) ? 16'h0002 :
  (op == `MPU_OP_MLOAD && opsize == 2'b11) ? 16'h0003 :
  (op == `MPU_OP_LOAD && opsize == 2'b00) ? 16'h0003 :
  (op == `MPU_OP_LOAD && opsize == 2'b01) ? 16'h0004 :
  (op == `MPU_OP_LOAD && opsize == 2'b10) ? 16'h0006 :
  (op == `MPU_OP_JMP) ? 16'h0002 :
  // else
  16'h0000;

assign error_isize = (isize == 16'h0000) ? 1'b1 : 1'b0;

/**
 * Data register acces
 */
assign op_idx0 = reg0[7:3];
assign op_idx1 = reg1[7:3];
assign op_idx2 = reg2[7:3];
assign op_idx3 = reg3[7:3];

/**
 * Alu configuration
 */

// Operation
assign op_op = op;

// Size
assign op_size = opsize;

/**
 * Operators and Selectors processing
 */

// Selectors
assign op_s0 = reg0[2:0];
assign op_s1 = 
  (op == `MPU_OP_LOAD) ? 3'b000 : // The immediate value is always in the LSBs
  reg1[2:0];
assign op_s2 = reg2[2:0];
assign op_s3 = reg3[2:0];

// Immediate value
assign imm = {32'b0, i[47:16]};

endmodule
