`include "checker.vh"

module checker_single #(
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
  output reg mode_error,

  // MPU control
  input mpu_error,
  input mpu_user_irq,
  input [63:0] mpu_user_data,
  output reg mpu_en,
  output reg mpu_rst
);

task init;
  begin
    mode_end <= 1'b0;
    mode_data <= 64'b0;
    mode_irq <= 1'b0;
    mode_error <= 1'b0;
    state <= `CHECKER_SINGLE_STATE_IDLE;
    mpu_en <= 1'b0;
    mpu_rst <= 1'b0;
  end
endtask

wire mode_selected = mode_mode == mode;

reg [1:0] state;

initial begin 
  init();
end

always @(posedge sys_clk) begin
	if (sys_rst) begin
    init();
	end else begin
    if (mode_selected) begin
      if (state == `CHECKER_SINGLE_STATE_IDLE) begin
        if (mode_start == 1'b1) begin // IDLE -> RESET
          state <= `CHECKER_SINGLE_STATE_RESET;
          mpu_rst <= 1'b1;
          mode_error <= 1'b0;
          mode_end <= 1'b0;
        end
      end else if (state == `CHECKER_SINGLE_STATE_RESET) begin
        state <= `CHECKER_SINGLE_STATE_RUN; // RESET -> RUN
        mpu_rst <= 1'b0;
        mpu_en <= 1'b1;
      end else if (state == `CHECKER_SINGLE_STATE_RUN) begin
        if (mode_start == 1'b0) begin // RUN -> IDE
          state <= `CHECKER_SINGLE_STATE_IDLE;
          mpu_en <= 1'b0;
        end else if (mpu_error == 1'b1) begin // RUN -> IDLE
          state <= `CHECKER_SINGLE_STATE_IDLE;
          mode_error <= 1'b1;
          mpu_en <= 1'b0;
        end else if (mpu_user_irq == 1'b1 && mpu_user_data == 64'b0) begin
          state <= `CHECKER_SINGLE_STATE_IDLE; // RUN -> IDLE : IRQ data 0 !
          mode_end <= 1'b1;
          mpu_en <= 1'b0;
        end else if (mpu_user_irq == 1'b1) begin // RUN -> WAIT
          state <= `CHECKER_SINGLE_STATE_WAIT;
          mode_data <= mpu_user_data;
          mode_irq <= 1'b1;
          mpu_en <= 1'b0;
        end
      end else if (state == `CHECKER_SINGLE_STATE_WAIT) begin
        // We send irq just one clock time
        if (mode_irq == 1'b1) begin
          mode_irq <= 1'b0;
        end
        if (mode_ack == 1'b1) begin // WAIT -> RUN
          state <= `CHECKER_SINGLE_STATE_RUN;
          mode_irq <= 1'b0;
          mode_data <= 64'b0;
          mpu_en <= 1'b1;
        end
      end
    end
  end
end

endmodule
