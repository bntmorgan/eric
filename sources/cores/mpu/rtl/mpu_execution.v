`include "mpu.vh"

module mpu_execution (
  /**
   * Decoded instruction
   */

  // Size of the instruction in bytes
  input [15:0] isize,

  /**
   * Operators configuration
   */
  input [1:0] op_size,
  input [3:0] op_op,
  input [63:0] op_o0,
  input [63:0] op_o1,
  input [63:0] op_o2,
  input [63:0] op_o3,
  input [2:0] op_s0,
  input [2:0] op_s1,
  input [2:0] op_s2,
  input [2:0] op_s3,
  input [4:0] op_idx0,
  input [4:0] op_idx1,
  input [4:0] op_idx2,
  input [4:0] op_idx3,

  /**
   * Instruction pointer
   */
  output [15:0] ip_incr,
  output ip_load,
  output [15:0] ip_data,

  /**
   * User interrupt
   *
   * Asserting user_irq will disable ip en until cpu clears the irq
   */
  output user_irq,
  output [63:0] user_data,

  /**
   * Write register access
   */
  output [4:0] w_idx,
  output [63:0] w_data,
  output [2:0] w_sel,
  output [2:0] w_r_sel,
  output [1:0] w_size,
  output we,

  /**
   * Host memory read
   *
   * Asserting mem_start will request the memory quad word to the host and
   * disable ip until the response is received
   */
  output [63:0] hm_addr,
  output hm_start,
  input [63:0] hm_data
);

wire alu_false;
wire [2:0] op_sres;
wire [63:0] op_res;
wire [7:0] op_flags;

/**
 * Host memory read
 */
assign hm_addr = op_o1;
assign hm_start = (op_op == `MPU_OP_MLOAD) ? 1'b1 : 1'b0;

/**
 * User interrupt
 */
assign user_irq = (op_op == `MPU_OP_INT) ? 1'b1 : 1'b0;
assign user_data = op_o0;

/**
 * Write register access
 */
assign w_idx = op_idx0;
assign w_data = 
  (op_op == `MPU_OP_MLOAD) ? hm_data :
  (op_op == `MPU_OP_ADD) ? op_res :
  (op_op == `MPU_OP_HAMM) ? op_res :
  op_o1;
assign w_sel = 3'b000;
assign w_r_sel = op_s0;
assign w_size = op_size;
assign we = (op_op == `MPU_OP_HAMM || op_op == `MPU_OP_ADD || op_op ==
  `MPU_OP_LOAD || op_op == `MPU_OP_MLOAD) ? 1'b1 : 1'b0;

/**
 * ALU(minium)
 */
assign op_sres = 3'b000;

mpu_alu alu (
  .size(op_size),
  .op(op_op),
  .o0(op_o0),
  .o1(op_o1),
  .o2(op_o2),
  .o3(op_o3),
  .s0(op_s0),
  .s1(op_s1),
  .s2(op_s2),
  .s3(op_s3),
  .sres(op_sres),
  .res(op_res),
  .flags(op_flags)
);

/**
 * Jump and jump if false
 */
assign alu_false = ~(op_res[0]);

assign ip_data = 
  (op_op == `MPU_OP_MASK || op_op == `MPU_OP_CMP) ? op_o3[15:0] :
  (op_op == `MPU_OP_LT) ? op_o2[15:0] :
  (op_op == `MPU_OP_JMP) ? op_o0[15:0] :
  16'h0000;

assign ip_load = 
  (op_op == `MPU_OP_JMP || ((op_op == `MPU_OP_MASK || op_op == `MPU_OP_CMP ||
    op_op == `MPU_OP_LT) && (alu_false))) ? 1'b1 :
  1'b0;

/**
 * Ip incrementation
 */
assign ip_incr = isize;

endmodule
