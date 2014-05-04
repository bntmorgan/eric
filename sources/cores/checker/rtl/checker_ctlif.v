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
   * When mode_start is asserted, all theese values are fixed until mode_end or cstop
   * are asserted
   */
  // Mode : Selects the component running the check
  output reg [1:0] mode_mode,
  // Start : starts the checker module or CSR stop it
  output reg mode_start,
  // Address of the page
  output reg [63:0] mode_addr,
  // End : end from the checker mode
  input mode_end,
  // Ctrl : Gets the status of the checker module running
  input [63:0] mode_data,
  // Mode irq
  input mode_irq,
  // Mode irq ack
  output reg mode_ack,
  // Mode error
  input mode_error,

  // LM32 IRQ
  output irq
);

/* CSR interface */
wire csr_selected = csr_a[13:10] == csr_addr;

/* Internal Registers */
// Events
reg event_end;
reg event_error;
reg event_mode_irq;
// IRQs
reg irq_en;

/** 
 * Internal state 
 * 0 : Idle
 * 1 : Checker running 
 * 2 : Checker Wait
 * 3 : Checker irq ack
 */
reg [1:0] state;

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
assign irq = (event_end & irq_en) | (event_error & irq_en) | (event_mode_irq
  & irq_en);

`define RESET_CTLIF begin \
  csr_do <= 32'd0; \
  mode_addr <= 64'b0; \
  event_end <= 1'b0; \
  event_error <= 1'b0; \
  event_mode_irq <= 1'b0; \
  irq_en <= 1'b0; \
  mode_mode[1:0] <= `CHECKER_MODE_SINGLE; \
  mode_start <= 1'b0; \
  mode_ack <= 1'b0; \
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
 * mode_start which can be if the user needs to stop the automata
 */
always @(posedge sys_clk) begin
	if (sys_rst) begin
    `RESET_CTLIF
	end else begin
    // State machine 
    if (state == `CHECKER_STATE_IDLE) begin
      if (mode_start == 1'b1) begin // IDLE -> RUN
        state <= `CHECKER_STATE_RUN;
        mode_start <= 1'b1;
      end
    end else if (state == `CHECKER_STATE_RUN) begin
      if (mode_end == 1'b1) begin
        state <= `CHECKER_STATE_IDLE; // RUN -> IDLE
        mode_start <= 1'b0;
        mode_start <= 1'b0;
        event_end <= 1'b1;
      end else if (mode_error == 1'b1) begin
        state <= `CHECKER_STATE_IDLE; // RUN -> IDLE
        mode_start <= 1'b0;
        mode_start <= 1'b0;
        event_error <= 1'b1;
      end else if (mode_irq == 1'b1) begin
        state <= `CHECKER_STATE_WAIT; // RUN -> WAIT
        event_mode_irq <= 1'b1;
      end
    end else if (state == `CHECKER_STATE_WAIT) begin
      if (event_mode_irq == 1'b0) begin // WAIT -> RUN
        state <= `CHECKER_STATE_ACK;
        mode_ack <= 1'b1;
      end else if (mode_start == 1'b0) begin
        state <= `CHECKER_STATE_IDLE; // WAIT -> IDLE
        event_mode_irq <= 1'b0;
        mode_start <= 1'b0;
      end
    // Error no fourth state
    end else if (state == `CHECKER_STATE_ACK) begin
      state <= `CHECKER_STATE_RUN;
      mode_ack <= 1'b0;
    end
    // CSR 
		csr_do <= 32'd0;
		if (csr_selected) begin
			case (csr_a[2:0])
				`CHECKER_CSR_ADDRESS_LOW: csr_do <= mode_addr[31:0];
				`CHECKER_CSR_ADDRESS_HIGH: csr_do <= mode_addr[63:32];
        `CHECKER_CSR_STAT: csr_do <= {29'b0, event_mode_irq, event_error,
          event_end};
        `CHECKER_CSR_CTRL: csr_do <= {27'b0, mode_start, mode_mode[1],
          mode_mode[0], irq_en};
        `CHECKER_CSR_MODE_DATA_LOW: csr_do <= mode_data[31:0];
        `CHECKER_CSR_MODE_DATA_HIGH: csr_do <= mode_data[63:32];
			endcase
			if (csr_we) begin
				case (csr_a[2:0])
          `CHECKER_CSR_ADDRESS_LOW: begin
            if (state == `CHECKER_STATE_IDLE) begin
              mode_addr[31:0] <= csr_di;
            end
          end
          `CHECKER_CSR_ADDRESS_HIGH: begin
            if (state == `CHECKER_STATE_IDLE) begin
              mode_addr[63:32] <= csr_di;
            end
          end
          `CHECKER_CSR_STAT: begin 
            if (state == `CHECKER_STATE_IDLE || state == `CHECKER_STATE_WAIT)
            begin
              /* write one to clear */
              if(csr_di[0])
                event_end <= 1'b0;
              if(csr_di[1])
                event_error <= 1'b0;
              if(csr_di[2])
                event_mode_irq <= 1'b0;
            end
          end
          `CHECKER_CSR_CTRL: begin
            if (state == `CHECKER_STATE_IDLE) begin
              irq_en <= csr_di[0];
              mode_mode[1:0] <= csr_di[2:1];
            end
            // We can only write stop when one checker is lanched
            mode_start <= csr_di[3];
          end
        endcase
      end
    end
  end
end

endmodule
