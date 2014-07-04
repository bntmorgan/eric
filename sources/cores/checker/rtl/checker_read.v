`include "checker.vh"

module checker_read #(
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

  // HM control
  output reg hm_start,
  output reg hm_rst,
  input hm_end,
  input hm_timeout,
  input hm_error
);

reg [1:0] state;

task init;
begin
  state <= `CHECKER_READ_STATE_IDLE;
  hm_start <= 1'b0;    
  hm_rst <= 1'b0;
  mode_error <= 1'b0;
  mode_end <= 1'b0;
  mode_data <= 1'b0;
  mode_irq <= 1'b0;
end
endtask

wire mode_selected = mode_mode == mode;
wire mode_started = mode_selected & mode_start;

initial begin
  init();
end

always @(posedge sys_clk) begin
  if (sys_rst == 1'b1) begin
    init();
  end else begin
    if (state == `CHECKER_READ_STATE_IDLE) begin
      mode_end <= 1'b0;
      mode_error <= 1'b0;
      if (mode_started == 1'b1 && mode_end == 1'b0 && mode_error == 1'b0) begin
        state <= `CHECKER_READ_STATE_RESET;
        hm_rst <= 1'b1;
      end
    end else if (state == `CHECKER_READ_STATE_RESET) begin
      hm_start <= 1'b1; 
      hm_rst <= 1'b0;
      state <= `CHECKER_READ_STATE_RUN;
    end else begin
      // CHECKER_READ_STATE_RUN
      hm_start <= 1'b0; 
      if (hm_end | hm_error | hm_timeout | ~mode_started == 1'b1) begin
      state <= `CHECKER_READ_STATE_IDLE;
        if (hm_end == 1'b1) begin
          mode_end <= 1'b1;
        end else if (hm_timeout | hm_error == 1'b1 ) begin
          mode_error <= 1'b1;
        end
      end
    end
  end
end

endmodule
