module mpu_int (
  /**
   * When irq is one en will be false until irq is commited by the main proco
   */
  input irq,
  input [63:0] data,
  output en
);

// TODO

assign en = 1'b1;

endmodule
