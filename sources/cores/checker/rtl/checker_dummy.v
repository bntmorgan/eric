`include "checker.vh"

module checker_dummy #(
  parameter mode = 2'b0
) (
  // System
	input sys_clk,
	input sys_rst,

  // Mode and control
  input [1:0] mode_mode,
  input mode_start,
  input [63:0] mode_addr,
  output reg mode_end,
  output reg [63:0] mode_data,
  output reg mode_irq,
  input mode_ack,
  output reg mode_error
);

/* Internal Registers */
reg [63:0] counter;

`define RESET_DUMMY begin \
  mode_end <= 1'b0; \
  mode_data <= 64'b0; \
  mode_irq <= 1'b0; \
  mode_error <= 1'b0; \
  counter <= 64'b0; \
  state <= `CHECKER_DUMMY_STATE_IDLE; \
end

wire mode_selected = mode_mode == mode;
wire mode_started = mode_selected & mode_start;

reg [1:0] state;

initial begin 
  `RESET_DUMMY
end

always @(posedge sys_clk) begin
	if (sys_rst) begin
    `RESET_DUMMY
	end else begin
    if (state == `CHECKER_DUMMY_STATE_RUN) begin
      if (mode_started) begin
        counter <= counter + 1'b1;
        mode_data[7:0] <= counter[7:0];
        if (counter >= mode_addr) begin
          mode_end <= 1'b1;
          state <= `CHECKER_DUMMY_STATE_IDLE;
        end else if (counter[27:0] == 28'hfffffff) begin
          state <= `CHECKER_DUMMY_STATE_WAIT;
          mode_irq <= 1'b1;
        end
      end else begin 
        state <= `CHECKER_DUMMY_STATE_IDLE;
      end
    end else if (state == `CHECKER_DUMMY_STATE_WAIT) begin
      if (mode_ack) begin
        mode_irq <= 1'b0;
        counter <= counter + 1'b1;
        state <= `CHECKER_DUMMY_STATE_RUN;
      end
    // CHECKER_DUMMY_STATE_IDLE
    end else begin
      if (mode_started) begin
        `RESET_DUMMY
        state <= `CHECKER_DUMMY_STATE_RUN;
      end
    end
  end
end

endmodule
