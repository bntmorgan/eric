module mpu_top (
  // System
  input sys_clk,
  input sys_rst,

  // Instruction bus, synchronous memory for instructions
  output [15:0] iaddr,
  input /* width !!! */ idata,
  
  // Data bus Memory to check, clock might be async so we acknoledge the data
  // receive
  output [63:0] daddr,
  input [63:0] ddata,
  input dack
);

endmodule
