`ifndef __CHECKER_VH__
`define __CHECKER_VH__

// Checker ctlif states
`define CHECKER_STATE_IDLE    2'b00
`define CHECKER_STATE_RUN     2'b01
`define CHECKER_STATE_WAIT    2'b10
`define CHECKER_STATE_ACK     2'b11

// Dummy Checker states
`define CHECKER_DUMMY_STATE_IDLE    1'b0
`define CHECKER_DUMMY_STATE_RUN     1'b1

// Single Checker states
`define CHECKER_SINGLE_STATE_IDLE    2'b00
`define CHECKER_SINGLE_STATE_RUN     2'b01
`define CHECKER_SINGLE_STATE_WAIT    2'b10
`define CHECKER_SINGLE_STATE_RESET   2'b11

// Modes
`define CHECKER_MODE_SINGLE 2'b00
`define CHECKER_MODE_AUTO   2'b01
`define CHECKER_MODE_READ   2'b10
`define CHECKER_MODE_DUMMY  2'b11

// CSR Register
`define CHECKER_CSR_ADDRESS_LOW       3'b000
`define CHECKER_CSR_ADDRESS_HIGH      3'b001
`define CHECKER_CSR_CTRL              3'b010
`define CHECKER_CSR_STAT              3'b011

// Register Status
`define CHECKER_STAT_EVENT_END        32'h00000001
`define CHECKER_STAT_EVENT_ERROR      32'h00000002
`define CHECKER_STAT_EVENT_USER_IRQ   32'h00000003

// Register Ctrl
`define CHECKER_CTRL_IRQ_EN           32'h00000001
`define CHECKER_CTRL_MODE_DFA_SINGLE  (`CHECKER_MODE_SINGLE << 32'd1)
`define CHECKER_CTRL_MODE_DFA_AUTO    (`CHECKER_MODE_AUTO << 32'd1)
`define CHECKER_CTRL_MODE_READ        (`CHECKER_MODE_READ << 32'd1)
`define CHECKER_CTRL_MODE_DUMMY       (`CHECKER_MODE_DUMMY << 32'd1)
`define CHECKER_CTRL_START            32'h00000008

`endif
