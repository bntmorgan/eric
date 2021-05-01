`ifndef __MPU_VH__
`define __MPU_VH__

/**
 * 30.000% Makina Process Unit
 */
`define MPU_OP_MASK      4'h1
`define MPU_OP_CMP       4'h2
`define MPU_OP_LT        4'h3
`define MPU_OP_ADD       4'h4
`define MPU_OP_HAMM      4'h5
`define MPU_OP_INT       4'hc
`define MPU_OP_MLOAD     4'hd
`define MPU_OP_LOAD      4'he
`define MPU_OP_JMP       4'hf

/**
 * MPU ctlif states
 */
`define MPU_STATE_IDLE    3'h0
`define MPU_STATE_RESET   3'h1
`define MPU_STATE_RUN     3'h2
`define MPU_STATE_WAIT    3'h3

`define MPU_CSR_CTRL              10'h000
`define MPU_CSR_STAT              10'h001
`define MPU_CSR_USER_DATA_LOW     10'h002
`define MPU_CSR_USER_DATA_HIGH    10'h003

`endif
