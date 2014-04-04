module checker_single#(
  parameter mode = 2'b0
) (
  // System
	input sys_clk,
	input sys_rst,

  // Mode and control
  input [1:0] cmode,
  input cstart,
  input [63:0] caddr,
  output reg cend,
  output reg [7:0] cctrl,

  // MPU control
  output mpu_en
);

task init;
  begin
    cend <= 1'b0;
    cctrl <= 8'b0;
    state <= `CHECKER_STATE_IDLE;
  end
endtask

wire mode_selected = cmode == mode;
wire mode_started = mode_selected & cstart;

// TODO XXX just for debug, not enought
assign mpu_en = mode_started;

reg [1:0] state;

initial begin 
  init();
end

always @(posedge sys_clk) begin
	if (sys_rst) begin
    init();
	end else begin
    if (state == `CHECKER_STATE_RUNNING) begin
      state <= `CHECKER_STATE_IDLE;
    // CHECKER_STATE_IDLE
    end else begin
      if (mode_started) begin
        init();
        state <= `CHECKER_STATE_RUNNING;
      end
    end
  end
end

endmodule
