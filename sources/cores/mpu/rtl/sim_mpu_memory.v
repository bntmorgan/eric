`include "sim.vh"

module main();

/**
 * Top module signals
 */

// Inputs
reg sys_clk;
reg sys_rst;
reg [15:0] r_addr;
reg we;
reg [15:0] w_addr;
reg [32:0] w_data;

// Outputs
wire [47:0] r_data;

`SIM_SYS_CLK

/**
 * Tested components
 */
mpu_memory mem (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .r_addr(r_addr),
  .we(we),
  .w_addr(w_addr),
  .w_data(w_data),
  .r_data(r_data)
);

initial begin
  r_addr = 16'b0;
  we = 1'b0;
  w_addr = 16'b0;
  w_data = 32'b0;
end

always @(*) begin
  $display("-");
  $display("r_addr %x", r_addr);
  $display("r_data %x", r_data);
  $display("we %x", we);
  $display("w_addr %x", w_addr);
  $display("w_data %x", w_data);
end

/**
 * Simulation
 */
initial begin
  # 8 $finish();
end

endmodule
