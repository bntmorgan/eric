reg ddr_clk;
reg ddr_rst;

always #1 ddr_clk = !ddr_clk;

initial begin
  ddr_clk = 1'b0;
  ddr_rst = 1'b0;
end

/* Wishbone Helpers */
task waitddrclock;
begin
	@(posedge ddr_clk);
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
