module mpu_int (
  // System
  input sys_clk,
  input sys_rst,
  /**
   * When irq is one en will be false until irq is commited by the main proco
   */
  input irq,
  input [63:0] data,
  output en
);

// TODO
reg state;
reg [1:0] cpt;

initial begin 
  state = 1'b1;
  cpt = 2'b0;
end

assign en = state;

always @(posedge sys_clk) begin
  if (sys_rst) begin
    state <= 1'b1;
    cpt <= 0'b0;
  end else begin
    if (state == 1'b1) begin
      if (irq == 1'b1) begin
        state <= 1'b0;
        cpt <= 0'b0;
      end
    end else begin
      if (cpt == 2'b11) begin
        state <= 1'b1;
      end
      cpt <= cpt + 1'b1;
    end
  end
end

endmodule
