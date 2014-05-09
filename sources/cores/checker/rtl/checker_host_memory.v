module mpu_host_memory (
  /**
   * When start is asserted en will be false until data is available
   */
  input [63:0] addr,
  input start,
  output [63:0] data,
  output en
);

// TODO

assign en = 1'b1;
assign data = 64'h7766554433221100;

endmodule
