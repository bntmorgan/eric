`define HM_CSR_CTRL           10'h000
`define HM_CSR_STAT           10'h001
`define HM_CSR_ADDRESS_LOW    10'h002
`define HM_CSR_ADDRESS_HIGH   10'h003
`define HM_CSR_CPT_RX         10'h004
`define HM_CSR_CPT_TX         10'h005
`define HM_CSR_STATE_RX       10'h006
`define HM_CSR_STATE_TX       10'h007
`define HM_CSR_STATE          10'h008

`define HM_TX_STATE_IDLE 1'b0
`define HM_TX_STATE_SEND 1'b1

`define HM_RX_STATE_IDLE  2'b00
`define HM_RX_STATE_RESET 2'b01
`define HM_RX_STATE_IGN   2'b10
`define HM_RX_STATE_RECV  2'b11

`define HM_STATE_IDLE 2'b00
`define HM_STATE_READ_PAGE 2'b01
`define HM_STATE_READ_RAMB 2'b10
`define HM_STATE_READ_RAMB_END 2'b11
`define HM_STATE_SEND 2'b01
`define HM_STATE_RECV 2'b10

`define HM_MR_STATE_IDLE 2'b00
`define HM_MR_STATE_READ_ADDRESS 2'b01
`define HM_MR_STATE_SEND 2'b10

`define HM_TX_DW_TO_SEND 2'b10
