module mpu_decoder (
  // Instruction to decode
  input [47:0] i,

  /**
   * Instruction decoding
   */

  // Size of the instruction in bits
  output [15:0] isize,

  // Operation
  output [3:0] op,

  // Address to jump
  output [15:0] jaddr,

  // Immediate value
  output [31:0] imm,

  // Decoding error
  output err,

  /**
   * Alu configuration
   */

  output [1:0] alu_size,
  output [3:0] alu_op,
  output [63:0] alu_o0,
  output [63:0] alu_o1,
  output [63:0] alu_o2,
  output [2:0] alu_s0,
  output [2:0] alu_s1,
  output [2:0] alu_s2,

  /**
   * Data registers access
   *
   * The low part of the idx in the instruction is used to select the b w dw (or
   * qw) in the qw
   */
  output [4:0] r_idx0,
  output [4:0] r_idx1,
  output [4:0] r_idx2,
  input [63:0] r_data0,
  input [63:0] r_data1,
  input [63:0] r_data2
);

wire [1:0] opsize;
wire [1:0] sop;
wire [7:0] reg0;
wire [7:0] reg1;
wire [7:0] reg2;
wire err_isize;

/**
 * Errors handling
 */
assign err = err_isize;

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
// 0x1_00xx reg_val reg_m0 reg_m1 @no

// val & m == val & m & jne
// 0x2_00xx reg_val0 reg_val1 reg_m @no

// val0 < val1 & jnlt
// 0x3_00xx reg_val0 reg_val1 @no

// mload reg
// 0xd_0011 reg

// load reg imm{8,16,32}
// 0xe_00xx reg imm

// jmp addr16
// 0xf_xxxx @

// Immediate value
assign imm = i[47:16];

assign jaddr =
  (op == 4'h1 || op == 4'h2) ? i[47:32] :
  (op == 4'h3              ) ? i[39:24] :
  (op == 4'hf              ) ? i[23: 8] :
  16'h0000;

// Register decoding
assign reg0 = i[15: 8];
assign reg1 = i[23:16];
assign reg2 = i[31:24];

// Instruction size decoding (in bytes)
assign isize[15:0] =
  // 1
  (op == 4'h1) ? 16'h0006 :
  // 2
  (op == 4'h2) ? 16'h0006 :
  // 3
  (op == 4'h3) ? 16'h0005 :
  // d
  (op == 4'hd && opsize == 2'b11) ? 16'h0002 :
  // e
  (op == 4'he && opsize == 2'b00) ? 16'h0003 :
  (op == 4'he && opsize == 2'b01) ? 16'h0004 :
  (op == 4'he && opsize == 2'b10) ? 16'h0006 :
  // f
  (op == 4'hf) ? 16'h0003 :
  // else
  16'h0000;

assign err_isize = (isize == 16'h0000) ? 1'b1 : 1'b0;

/**
 * Alu configuration
 */

// Operation
assign alu_op = op;

// Size
assign alu_size = opsize;

// Operators
assign alu_o0 = r_data0;
assign alu_o1 = r_data1;
assign alu_o2 = r_data2;

// Selectors
assign alu_s0 = reg0[2:0];
assign alu_s1 = reg1[2:0];
assign alu_s2 = reg2[2:0];

/**
 * Data register acces
 */
assign r_idx0 = reg0[7:3];
assign r_idx1 = reg1[7:3];
assign r_idx2 = reg2[7:3];

endmodule
