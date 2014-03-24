module checker_dummy #(
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
  output reg [7:0] cctrl
);

/* Internal Registers */
reg [63:0] counter;

`define RESET_DUMMY begin \
  cend <= 1'b0; \
  cctrl <= 8'b0; \
  counter <= 64'b0; \
  state <= `CHECKER_STATE_IDLE; \
end

wire mode_selected = cmode == mode;
wire mode_started = mode_selected & cstart;

reg [1:0] state;

initial begin 
  `RESET_DUMMY
end

always @(posedge sys_clk) begin
	if (sys_rst) begin
    `RESET_DUMMY
	end else begin
    if (state == `CHECKER_STATE_RUNNING) begin
      if (mode_started) begin
        counter <= counter + 1'b1;
        if (counter >= caddr) begin
          cend <= 1'b1;
          cctrl[7:0] <= counter[7:0];
          state <= `CHECKER_STATE_IDLE;
        end
      end else begin 
        state <= `CHECKER_STATE_IDLE;
      end
    // CHECKER_STATE_IDLE
    end else begin
      if (mode_started) begin
        `RESET_DUMMY
        state <= `CHECKER_STATE_RUNNING;
      end
    end
  end
end

endmodule
