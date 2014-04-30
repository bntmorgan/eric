module mpu_counter (
  // System
  input sys_clk,
  input sys_rst,

  /**
   * Counter
   * 
   * If load is asserted next rise load data as current value for ip else
   * If count is asserted next rise will be incremented by incr
   */
  input en,
  input [15:0] incr,
  input load,
  input [15:0] data,

  // Instruction pointer
  output reg [15:0] out
);

`define RESET_MPU_IP begin \
  out <= 16'b0; \
end

initial begin
  `RESET_MPU_IP
end
 
always @(posedge sys_clk) begin
  if (sys_rst) begin
    `RESET_MPU_IP
  end else begin
    if (en) begin
      if (load) begin
        out[15:0] <= data[15:0];
      end else begin
        out[15:0] <= out[15:0] + incr[15:0];
      end
    end
  end
end

endmodule
