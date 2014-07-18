module main();

`include "sim.v"

// Inputs
reg tx_start;
reg trn_tdst_rdy_n;
reg [63:0] hm_addr;
wire trn_clk = sys_clk;

// output
wire tx_end;
wire [63:0] trn_td;
wire trn_tsof_n;
wire trn_trem_n;
wire trn_teof_n;
wire trn_tsrc_rdy_n;

initial begin
  tx_start <= 1'b0;
  trn_tdst_rdy_n <= 1'b1;
  hm_addr <= 64'h0000000000000000;
end

/**
 * Tested component
 */
hm_tx tx (
  .tx_start(tx_start),
  .tx_end(tx_end),
  .hm_addr(hm_addr),
  .trn_clk(trn_clk),
  .trn_td(trn_td),
  .trn_tsof_n(trn_tsof_n),
  .trn_trem_n(trn_trem_n),
  .trn_teof_n(trn_teof_n),
  .trn_tsrc_rdy_n(trn_tsrc_rdy_n),
  .trn_tdst_rdy_n(trn_tdst_rdy_n)
);

task tx_memory_read;
input [63:0] addr;
begin
  hm_addr <= addr;
  // User app starts the transfert
  tx_start <= 1'b1;
  trn_tdst_rdy_n <= 1'b1;
  waitclock();
  tx_start <= 1'b0;
  waitnclock(9);
  // Emulate trn inrface is ready
  trn_tdst_rdy_n <= 1'b0;
  waitnclock(8);
end
endtask


initial begin
  waitnclock(10);
  // Memory read request <= 4gb
  tx_memory_read(64'h0000000000001000);

  // Memory read request > 4gb
  tx_memory_read(64'h1000000000000000);

  $display("caca");

  // Waiting for end
  waitnclock(40);
  $finish();
end

endmodule
