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
  output ip_en,
  output [15:0] ip_incr,
  output ip_load,
  output [15:0] ip_data,

  /**
   * User interrupt
   */
  output user_irq,
  output [63:0] data
);



endmodule
