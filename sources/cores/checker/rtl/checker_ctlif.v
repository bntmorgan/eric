`include "checker.vh"

module checker_ctlif #(
	parameter csr_addr = 4'h0
) (
  // System
	input sys_clk,
	input sys_rst,

  // CSR
	input [13:0] csr_a,
	input csr_we,
	input [31:0] csr_di,
	output reg [31:0] csr_do,

  /**
   * When cstart is asserted, all theese values are fixed until cend or cstop
   * are asserted
   */
  // Mode : Selects the component running the check
  output reg [1:0] cmode,
  // Start : starts the checker module or CSR stop it
  output reg cstart,
  // Address of the page
  output reg [63:0] caddr,
  // End : end from the checker mode
  input cend,
  // Ctrl : Gets the status of the checker module running
  input [7:0] cctrl,

  // IRQ
  output irq
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

/* Internal Registers */
// Events
reg event_done;
reg event_error;
// IRQs
reg irq_en;

/** 
 * Internal state 
 * 0 : Idle
 * 1 : Checker running 
 */
reg state;

/**
 * Mode 
 *
 * The mode selects a checker component which can do on of the following :
 * 
 * CHECKER_MODE_SINGLE Apply the automata on one page
 * CHECKER_MODE_AUTO   Apply the automata on entire memory
 * CHECKER_MODE_READ   Read a quad word
 * CHECKER_MODE_DUMMY  Immediately notifies that it's done
 */

/* IRQ Control */
assign irq = (event_done & irq_en) | (event_error & irq_en);

`define RESET_CTLIF begin \
  csr_do <= 32'd0; \
  caddr <= 64'b0; \
  event_done <= 1'b0; \
  event_error <= 1'b0; \
  irq_en <= 1'b0; \
  cmode[1:0] <= `CHECKER_MODE_SINGLE; \
  cstart <= 1'b0; \
  state <= `CHECKER_STATE_IDLE; \
end

initial begin 
  `RESET_CTLIF
end

reg [31:0] test;

/**
 * CSR logic
 *
 * CSR registers can't be modified in the CHECKER_STATE_RUNNING state except for
 * cstart which can be if the user needs to stop the automata
 */
always @(posedge sys_clk) begin
	if (sys_rst) begin
    `RESET_CTLIF
	end else begin
		csr_do <= 32'd0;
    // XXX TO TEST
    if (cend) begin
      cstart <= 1'b0;
      event_done <= 1'b1;
    end
    if (cstart)
      state <= `CHECKER_STATE_RUNNING;
    else 
      state <= `CHECKER_STATE_IDLE;
    // XXX END TO TEST
		if (csr_selected) begin
			case (csr_a[2:0])
				`CHECKER_CSR_ADDRESS_LOW: csr_do <= caddr[31:0];
				`CHECKER_CSR_ADDRESS_HIGH: csr_do <= caddr[63:32];
        `CHECKER_CSR_STAT: csr_do <= {30'b0, event_error, event_done};
        `CHECKER_CSR_CTRL: csr_do <= {27'b0, cstart, cmode[1], cmode[0],
          irq_en};
			endcase
			if (csr_we) begin
				case (csr_a[2:0])
          `CHECKER_CSR_ADDRESS_LOW: begin
            if (state == `CHECKER_STATE_IDLE) begin
              caddr[31:0] <= csr_di;
            end
          end
          `CHECKER_CSR_ADDRESS_HIGH: begin
            if (state == `CHECKER_STATE_IDLE) begin
              caddr[63:32] <= csr_di;
            end
          end
          `CHECKER_CSR_STAT: begin 
            if (state == `CHECKER_STATE_IDLE) begin
              /* write one to clear */
              if(csr_di[0])
                event_done <= 1'b0;
              if(csr_di[1])
                event_error <= 1'b0;
            end
          end
          `CHECKER_CSR_CTRL: begin
            if (state == `CHECKER_STATE_IDLE) begin
              irq_en <= csr_di[0];
              cmode[1:0] <= csr_di[2:1];
            end
            // We can only write stop when one checker is lanched
            cstart <= csr_di[3];
          end
        endcase
      end
    end
  end
end

endmodule
