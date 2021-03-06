reg sys_clk;
reg sys_rst;

always #1 sys_clk = !sys_clk;

initial begin
  sys_clk = 1'b0;
  sys_rst = 1'b0;
end

always @(posedge sys_clk)
begin
  $display("-- %02d", $time);
  $display("-");
end

/* Wishbone Helpers */
task waitclock;
begin
	@(posedge sys_clk);
	#1;
end
endtask

task waitnclock;
input [15:0] n;
integer i;
begin
	for(i=0;i<n;i=i+1)
		waitclock;
	end
endtask

initial begin
  $dumpfile(`__DUMP_FILE__);
  $dumpvars(0,main);
end
