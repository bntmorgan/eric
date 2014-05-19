module checker_host_memory (
  /**
   * When start is asserted en will be false until data is available
   */
  input sys_clk,
  input sys_rst,
  input en,

  input hm_start,
  output reg hm_end,
  output [63:0] hm_data,
  input [63:0] hm_page_addr,
  input [11:0] hm_page_offset,
  output reg hm_timeout
);

reg [4:0] cpt;
reg state;

assign hm_data = 64'h1234567887654321;

task init;
begin
  cpt <= 4'b0;
  state <= 1'b0;
  hm_end <= 1'b0;
  hm_timeout <= 1'b0;
end
endtask

initial begin
  init();
end

always @(posedge sys_clk) begin
  if (sys_rst) begin
    init();
  end else if (en == 1'b1) begin 
    if (state == 1'b0) begin
      hm_end <= 1'b0;
      hm_timeout <= 1'b0;
      if (hm_start == 1'b1) begin
        state <= 1'b1;
        cpt <= 4'b0;
      end
    end else begin
      cpt <= cpt + 1'b1;
      if (cpt == 4'b1000) begin
        state <= 1'b0;
        // hm_end <= 1'b1;
        hm_timeout <= 1'b1;
      end
    end
  end
end

endmodule
