reg ui_clk;
reg ui_clk_sync_rst;

always #1 ui_clk = !ui_clk;

initial begin
  ui_clk = 1'b0;
  ui_clk_sync_rst = 1'b0;
end

/* Wishbone Helpers */
task waitddrclock;
begin
	@(posedge ui_clk);
	#2;
end
endtask

task waitnddrclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitddrclock;
	end
endtask
